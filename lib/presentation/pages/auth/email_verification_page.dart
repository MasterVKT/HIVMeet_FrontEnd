import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/routes.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/authentication_service.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds only a Firebase session until its email-verification claim is fresh.
/// It deliberately never displays the address or a token.
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage>
    with WidgetsBindingObserver {
  static const _resendDeadlineKey = 'email_verification_resend_deadline';
  static const _resendCooldown = Duration(seconds: 60);

  Timer? _ticker;
  DateTime? _resendDeadline;
  bool _isChecking = false;
  bool _isResending = false;
  String? _messageKey;

  AuthenticationService get _authService => getIt<AuthenticationService>();

  int get _secondsRemaining {
    final deadline = _resendDeadline;
    if (deadline == null) return 0;
    return deadline.difference(DateTime.now()).inSeconds.clamp(0, 9999);
  }

  String _tr(String key, {Map<String, dynamic>? params}) =>
      LocalizationService.translate(key, params: params);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreResendCooldown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkVerification(silent: true));
    }
  }

  Future<void> _restoreResendCooldown() async {
    final preferences = await SharedPreferences.getInstance();
    final timestamp = preferences.getInt(_resendDeadlineKey);
    if (!mounted || timestamp == null) return;
    final deadline = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (deadline.isAfter(DateTime.now())) {
      setState(() => _resendDeadline = deadline);
      _startTicker();
    } else {
      await preferences.remove(_resendDeadlineKey);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      if (_secondsRemaining == 0) {
        _ticker?.cancel();
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove(_resendDeadlineKey);
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _checkVerification({bool silent = false}) async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
      if (!silent) _messageKey = null;
    });
    final result = await _authService.completeEmailVerification();
    if (!mounted) return;
    if (result.success && result.user != null) {
      context.go(AppRoutes.discovery);
      return;
    }
    setState(() {
      _isChecking = false;
      if (!silent || result.errorCode != 'email_not_verified') {
        _messageKey = result.error ?? 'auth.email_verification.still_pending';
      }
    });
  }

  Future<void> _resend() async {
    if (_isResending || _secondsRemaining > 0) return;
    setState(() {
      _isResending = true;
      _messageKey = null;
    });
    final result = await _authService.resendEmailVerification(
      locale: LocalizationService.instance.currentLocale,
    );
    if (!mounted) return;
    if (result.verificationEmailSent == true) {
      final deadline = DateTime.now().add(_resendCooldown);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(
        _resendDeadlineKey,
        deadline.millisecondsSinceEpoch,
      );
      if (!mounted) return;
      setState(() {
        _resendDeadline = deadline;
        _messageKey = 'auth.email_verification.resend_sent';
        _isResending = false;
      });
      _startTicker();
      return;
    }
    setState(() {
      _isResending = false;
      _messageKey = 'auth.email_verification.resend_failed';
    });
  }

  Future<void> _useAnotherAccount() async {
    await _authService.signOut();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _secondsRemaining;
    final resendLabel = seconds > 0
        ? _tr('auth.email_verification.resend_wait',
            params: {'seconds': seconds})
        : _tr('auth.email_verification.resend');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 72,
                    color: AppColors.primaryPurple,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _tr('auth.email_verification.title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _tr('auth.email_verification.description'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (_messageKey != null) ...[
                    const SizedBox(height: 20),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _tr(_messageKey!),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.slate,
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  AppButton(
                    onPressed: _isChecking ? null : _checkVerification,
                    text: _tr('auth.email_verification.check'),
                    isLoading: _isChecking,
                    type: ButtonType.primary,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isResending || seconds > 0 ? null : _resend,
                    child: _isResending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(resendLabel),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _useAnotherAccount,
                    child: Text(_tr('auth.email_verification.another_account')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
