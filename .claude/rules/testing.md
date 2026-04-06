# HIVMeet - Testing Strategy

**Purpose**: Guidelines for widget testing, integration testing, and test-driven development practices.

---

## Testing Pyramid

```
        E2E Tests (Few)
       /              \
    Integration Tests
   /                   \
  Widget Tests (Many)
```

**Philosophy**: Write many widget tests, some integration tests, few E2E tests.

---

## Widget Testing

### Setup

**Dependencies** (`pubspec.yaml`):
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
```

### Basic Widget Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hivmeet/presentation/widgets/custom_button.dart';

void main() {
  group('CustomButton Widget Tests', () {
    testWidgets('renders correctly with text', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Click Me'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      // Arrange
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Assert
      expect(pressed, true);
    });

    testWidgets('shows loading indicator when loading', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Submit',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });
  });
}
```

---

## BLoC Testing

### Using bloc_test Package

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:hivmeet/presentation/bloc/authentication/authentication_bloc.dart';
import 'package:hivmeet/domain/usecases/login_usecase.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  group('AuthenticationBloc Tests', () {
    late MockLoginUseCase mockLoginUseCase;

    setUp(() {
      mockLoginUseCase = MockLoginUseCase();
    });

    blocTest<AuthenticationBloc, AuthenticationState>(
      'emits [AuthenticationLoading, AuthenticationSuccess] when login succeeds',
      build: () {
        when(mockLoginUseCase(any)).thenAnswer(
          (_) async => Right(mockUser),
        );
        return AuthenticationBloc(loginUseCase: mockLoginUseCase);
      },
      act: (bloc) => bloc.add(
        LoginRequested(email: 'test@test.com', password: 'password123'),
      ),
      expect: () => [
        AuthenticationLoading(),
        AuthenticationSuccess(user: mockUser),
      ],
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'emits [AuthenticationLoading, AuthenticationFailure] when login fails',
      build: () {
        when(mockLoginUseCase(any)).thenAnswer(
          (_) async => Left(ServerFailure(message: 'Invalid credentials')),
        );
        return AuthenticationBloc(loginUseCase: mockLoginUseCase);
      },
      act: (bloc) => bloc.add(
        LoginRequested(email: 'test@test.com', password: 'wrong'),
      ),
      expect: () => [
        AuthenticationLoading(),
        AuthenticationFailure(message: 'Invalid credentials'),
      ],
    );
  });
}
```

---

## Integration Testing

### Testing User Flows

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hivmeet/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow Integration Test', () {
    testWidgets('user can login successfully', (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to login screen
      final loginButton = find.text('Se connecter');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Enter credentials
      final emailField = find.byKey(Key('email_field'));
      final passwordField = find.byKey(Key('password_field'));
      
      await tester.enterText(emailField, 'test@hivmeet.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Submit form
      final submitButton = find.text('Connexion');
      await tester.tap(submitButton);
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Verify navigation to home screen
      expect(find.text('Découverte'), findsOneWidget);
      expect(find.byKey(Key('discovery_screen')), findsOneWidget);
    });
  });
}
```

---

## Mocking HTTP Requests

### Using mockito

```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';

@GenerateMocks([Dio])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService Tests', () {
    late MockDio mockDio;
    late AuthService authService;

    setUp(() {
      mockDio = MockDio();
      authService = AuthService(mockDio);
    });

    test('login returns UserModel on success', () async {
      // Arrange
      final mockResponse = Response(
        data: {
          'user': {
            'id': '123',
            'email': 'test@test.com',
            'username': 'testuser',
          },
          'token': 'abc123',
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/auth/login'),
      );

      when(mockDio.post(
        '/api/v1/auth/login',
        data: anyNamed('data'),
      )).thenAnswer((_) async => mockResponse);

      // Act
      final result = await authService.login(
        email: 'test@test.com',
        password: 'password123',
      );

      // Assert
      expect(result, isA<UserModel>());
      expect(result.email, 'test@test.com');
      verify(mockDio.post('/api/v1/auth/login', data: anyNamed('data'))).called(1);
    });

    test('login throws ServerException on failure', () async {
      // Arrange
      when(mockDio.post(
        '/api/v1/auth/login',
        data: anyNamed('data'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        ),
      ));

      // Act & Assert
      expect(
        () => authService.login(email: 'test@test.com', password: 'wrong'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
```

---

## Golden Tests (Visual Regression)

**Purpose**: Verify UI hasn't changed unexpectedly

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  group('ProfileCard Golden Tests', () {
    testGoldens('renders correctly', (WidgetTester tester) async {
      await loadAppFonts();

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
        ])
        ..addScenario(
          widget: ProfileCard(
            name: 'John Doe',
            age: 30,
            bio: 'Hello, I am John!',
          ),
          name: 'default',
        )
        ..addScenario(
          widget: ProfileCard(
            name: 'Jane Smith',
            age: 28,
            bio: 'Looking for meaningful connections.',
            isPremium: true,
          ),
          name: 'premium_badge',
        );

      await tester.pumpDeviceBuilder(builder);

      await screenMatchesGolden(tester, 'profile_card');
    });
  });
}
```

---

## Test Coverage

### Generate Coverage Report

```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html
```

### Target Coverage

- **Critical Code**: 100% (auth, payment, sensitive data)
- **Business Logic**: >90% (UseCases, BLoCs)
- **Data Layer**: >80% (Services, Repositories)
- **UI Components**: >70% (Widgets, Pages)
- **Overall Project**: >80%

---

## Test Organization

### Directory Structure

```
test/
├── unit/
│   ├── domain/
│   │   └── usecases/
│   │       ├── login_usecase_test.dart
│   │       └── register_usecase_test.dart
│   ├── data/
│   │   ├── models/
│   │   │   └── user_model_test.dart
│   │   └── repositories/
│   │       └── auth_repository_test.dart
│   └── presentation/
│       └── bloc/
│           └── authentication_bloc_test.dart
├── widget/
│   ├── custom_button_test.dart
│   ├── profile_card_test.dart
│   └── swipe_cards_test.dart
├── integration/
│   ├── login_flow_test.dart
│   ├── discovery_flow_test.dart
│   └── messaging_flow_test.dart
└── fixtures/
    ├── mock_user.json
    ├── mock_profiles.json
    └── mock_messages.json
```

---

## Testing Best Practices

1. ✅ **Follow AAA Pattern**: Arrange, Act, Assert
2. ✅ **One assertion per test** (prefer specific tests over generic ones)
3. ✅ **Use descriptive test names**: `should_return_user_when_login_succeeds`
4. ✅ **Mock external dependencies** (APIs, databases, storage)
5. ✅ **Test edge cases**: null values, empty lists, network errors
6. ✅ **Use fixtures** for consistent test data
7. ✅ **Keep tests fast** (unit tests < 100ms, widget tests < 500ms)
8. ✅ **Run tests before every commit**
9. ✅ **Maintain test code quality** (same standards as production code)
10. ✅ **Test accessibility**: screen readers, contrast, focus

---

## Continuous Integration

### GitHub Actions Workflow

```yaml
name: Flutter CI

on:
  push:
    branches: [ master, develop ]
  pull_request:
    branches: [ master, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run analyzer
        run: flutter analyze
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

---

## Test Data Fixtures

**Location**: `test/fixtures/`

**Example** (`mock_user.json`):
```json
{
  "id": "user_123",
  "email": "test@hivmeet.com",
  "username": "testuser",
  "birthdate": "1990-01-15",
  "gender": "male",
  "is_premium": false,
  "profile_completion": 85
}
```

**Usage**:
```dart
import 'dart:convert';
import 'dart:io';

String fixture(String name) {
  return File('test/fixtures/$name').readAsStringSync();
}

Map<String, dynamic> jsonFixture(String name) {
  return json.decode(fixture(name));
}

// In test
final userData = jsonFixture('mock_user.json');
final user = UserModel.fromJson(userData);
```

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

**Comprehensive testing ensures HIVMeet's reliability, especially for sensitive user data and privacy-critical features.**
