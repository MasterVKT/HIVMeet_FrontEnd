import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/domain/entities/user.dart' as domain;
import 'package:hivmeet/presentation/blocs/auth/auth_bloc_simple.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_event.dart';
import 'package:hivmeet/presentation/blocs/auth/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthenticationService extends Mock
    implements AuthenticationService {}

void main() {
  group('AuthBlocSimple email verification', () {
    late _MockAuthenticationService authenticationService;
    late AuthBlocSimple bloc;

    setUp(() {
      authenticationService = _MockAuthenticationService();
      when(() => authenticationService.status)
          .thenReturn(AuthenticationStatus.disconnected);
      when(() => authenticationService.statusStream)
          .thenAnswer((_) => const Stream<AuthenticationStatus>.empty());
      when(() => authenticationService.userStream)
          .thenAnswer((_) => const Stream<domain.User?>.empty());
      when(() => authenticationService.errorStream)
          .thenAnswer((_) => const Stream<String?>.empty());
      bloc = AuthBlocSimple(authenticationService);
    });

    tearDown(() => bloc.close());

    test('routes an unverified Firebase sign-in to the waiting state',
        () async {
      when(
        () => authenticationService.signInWithEmailAndPassword(
          email: 'member@example.test',
          password: 'StrongPassword123!',
        ),
      ).thenAnswer(
          (_) async => AuthenticationResult.emailVerificationPending());

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<EmailVerificationPending>(),
        ]),
      );

      bloc.add(const LoginRequested(
        email: 'member@example.test',
        password: 'StrongPassword123!',
      ));
      await expectation;
    });
  });
}
