# HIVMeet - Architecture & Design Patterns

**Purpose**: Detailed guidance on Clean Architecture implementation, BLoC pattern, and structural conventions.

---

## Clean Architecture Layers

### 1. Presentation Layer (`lib/presentation/`)

**Responsibility**: UI components, user interaction, state management

**Components**:
- **Pages**: Full screens (e.g., `login_page.dart`, `discovery_page.dart`)
- **Widgets**: Reusable UI components (e.g., `profile_card.dart`, `custom_button.dart`)
- **BLoC/Cubit**: State management classes

**Rules**:
- ✅ Pages only handle UI rendering and user events
- ✅ NO business logic in widgets
- ✅ Call UseCases through BLoC/Cubit
- ✅ Observe state changes reactively

**Example**:
```dart
class DiscoveryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      builder: (context, state) {
        if (state is DiscoveryLoading) {
          return LoadingIndicator();
        } else if (state is DiscoveryLoaded) {
          return ProfileCardStack(profiles: state.profiles);
        } else if (state is DiscoveryError) {
          return ErrorWidget(message: state.message);
        }
        return Container();
      },
    );
  }
}
```

---

### 2. Application Layer (BLoC/Cubit)

**Responsibility**: State management, orchestrate UseCases, handle UI events

**Pattern**: BLoC (Business Logic Component) using `flutter_bloc` package

**Structure**:
```
lib/presentation/bloc/
├── authentication/
│   ├── authentication_bloc.dart
│   ├── authentication_event.dart
│   └── authentication_state.dart
├── discovery/
│   ├── discovery_bloc.dart
│   ├── discovery_event.dart
│   └── discovery_state.dart
└── profile/
    ├── profile_cubit.dart
    └── profile_state.dart
```

**Rules**:
- ✅ One BLoC per feature/screen
- ✅ Use Cubit for simple state (no events needed)
- ✅ Use BLoC for complex flows (multiple events)
- ✅ Always emit new state instances (immutability)
- ✅ Handle errors gracefully with error states

**Example**:
```dart
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final GetDiscoveryProfilesUseCase getProfiles;
  final LikeProfileUseCase likeProfile;

  DiscoveryBloc({
    required this.getProfiles,
    required this.likeProfile,
  }) : super(DiscoveryInitial()) {
    on<LoadDiscoveryProfiles>(_onLoadProfiles);
    on<LikeProfile>(_onLikeProfile);
  }

  Future<void> _onLoadProfiles(
    LoadDiscoveryProfiles event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(DiscoveryLoading());
    
    final result = await getProfiles(NoParams());
    
    result.fold(
      (failure) => emit(DiscoveryError(message: failure.message)),
      (profiles) => emit(DiscoveryLoaded(profiles: profiles)),
    );
  }
}
```

---

### 3. Domain Layer (`lib/domain/`)

**Responsibility**: Business logic, entities, repository interfaces

**Components**:
- **Entities**: Pure business objects (no JSON, no framework dependencies)
- **Repository Interfaces**: Abstract contracts for data access
- **UseCases**: Single-responsibility business operations

**Structure**:
```
lib/domain/
├── entities/
│   ├── user.dart
│   ├── profile.dart
│   └── match.dart
├── repositories/
│   ├── auth_repository.dart
│   ├── profile_repository.dart
│   └── matching_repository.dart
└── usecases/
    ├── get_discovery_profiles.dart
    ├── like_profile.dart
    └── send_message.dart
```

**Entity Example**:
```dart
class User {
  final String id;
  final String email;
  final String username;
  final DateTime birthdate;
  final Gender gender;
  final bool isPremium;

  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.birthdate,
    required this.gender,
    required this.isPremium,
  });
}
```

**UseCase Example**:
```dart
class GetDiscoveryProfilesUseCase {
  final ProfileRepository repository;

  GetDiscoveryProfilesUseCase(this.repository);

  Future<Either<Failure, List<Profile>>> call(NoParams params) async {
    return await repository.getDiscoveryProfiles();
  }
}
```

---

### 4. Data Layer (`lib/data/`)

**Responsibility**: API calls, local storage, data transformations

**Components**:
- **Models**: DTOs with JSON serialization (extend entities)
- **Services**: API client implementations (Dio)
- **Repository Implementations**: Implement domain repository interfaces
- **Data Sources**: Remote (API) and Local (cache/database)

**Structure**:
```
lib/data/
├── models/
│   ├── user_model.dart
│   ├── profile_model.dart
│   └── match_model.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── profile_service.dart
├── repositories/
│   ├── auth_repository_impl.dart
│   └── profile_repository_impl.dart
└── datasources/
    ├── remote/
    │   └── profile_remote_datasource.dart
    └── local/
        └── profile_local_datasource.dart
```

**Model Example** (extends Entity):
```dart
class UserModel extends User {
  const UserModel({
    required String id,
    required String email,
    required String username,
    required DateTime birthdate,
    required Gender gender,
    required bool isPremium,
  }) : super(
    id: id,
    email: email,
    username: username,
    birthdate: birthdate,
    gender: gender,
    isPremium: isPremium,
  );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      birthdate: DateTime.parse(json['birthdate']),
      gender: Gender.values.byName(json['gender']),
      isPremium: json['is_premium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'birthdate': birthdate.toIso8601String(),
      'gender': gender.name,
      'is_premium': isPremium,
    };
  }
}
```

**Repository Implementation**:
```dart
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Profile>>> getDiscoveryProfiles() async {
    try {
      final profiles = await remoteDataSource.fetchDiscoveryProfiles();
      await localDataSource.cacheProfiles(profiles);
      return Right(profiles);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException {
      // Try loading from cache
      try {
        final cachedProfiles = await localDataSource.getCachedProfiles();
        return Right(cachedProfiles);
      } catch (e) {
        return Left(CacheFailure(message: 'No cached data available'));
      }
    }
  }
}
```

---

## Dependency Injection

**Pattern**: Service Locator using `get_it` package

**File**: `lib/core/injection/injection_container.dart`

**Setup**:
```dart
final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // External
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => FlutterSecureStorage());
  
  // Services
  sl.registerLazySingleton(() => ApiService(sl()));
  sl.registerLazySingleton(() => AuthService(sl(), sl()));
  
  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl())
  );
  
  // UseCases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  
  // BLoCs (registered as factories - new instance each time)
  sl.registerFactory(() => AuthenticationBloc(
    loginUseCase: sl(),
    registerUseCase: sl(),
  ));
}
```

**Usage in Widget**:
```dart
BlocProvider(
  create: (context) => sl<AuthenticationBloc>(),
  child: LoginPage(),
)
```

---

## Error Handling

**Pattern**: Either<Failure, Success> using `dartz` package

**Failure Hierarchy**:
```dart
abstract class Failure {
  final String message;
  const Failure({required this.message});
}

class ServerFailure extends Failure {
  const ServerFailure({required String message}) : super(message: message);
}

class NetworkFailure extends Failure {
  const NetworkFailure({required String message}) : super(message: message);
}

class CacheFailure extends Failure {
  const CacheFailure({required String message}) : super(message: message);
}

class ValidationFailure extends Failure {
  const ValidationFailure({required String message}) : super(message: message);
}
```

**Exception Hierarchy**:
```dart
class ServerException implements Exception {
  final String message;
  const ServerException({required this.message});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({required this.message});
}
```

---

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | `snake_case` | `user_profile_page.dart` |
| Classes | `PascalCase` | `UserProfilePage` |
| Variables | `camelCase` | `currentUser` |
| Functions | `camelCase` | `fetchUserProfile()` |
| Constants | `camelCase` | `maxBioLength` |
| Private | `_camelCase` | `_privateMethod()` |

---

## File Organization Rules

1. ✅ One class per file (except small related classes like events/states)
2. ✅ Group imports: Dart SDK → Flutter → External packages → Internal
3. ✅ Export barrel files for public APIs (`index.dart`)
4. ✅ Keep files under 300 lines (refactor if larger)
5. ✅ Use `part` directive sparingly (prefer composition)

---

## 🔧 Error Correction in Logs

**When errors are identified in logs (frontend or backend)**:

- ✅ **CORRECT ERRORS** in source code whenever possible
- ✅ **DO NOT ONLY** document or ignore minor errors
- ✅ **PRIORITIZE** fixes that have no impact on other features
- ✅ For critical or complex errors (requiring backend modification), create a markdown file `BACKEND_[TYPE]_[DESCRIPTION].md`

**Examples of errors to correct directly**:
- Dart compilation errors
- Type errors
- Empty URLs causing crashes
- Unhandled null values
- Incorrect UI states

**Examples requiring a markdown file**:
- Backend corrections required
- API modifications
- Database schema changes
- Complex performance issues

---

**This architecture ensures maintainability, testability, and scalability of HIVMeet frontend.**
