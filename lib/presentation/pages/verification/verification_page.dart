import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/kyc/kyc_capture_port.dart';
import 'package:hivmeet/core/kyc/kyc_screen_privacy.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/kyc.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/kyc/kyc_cubit.dart';
import 'package:hivmeet/presentation/blocs/kyc/kyc_state.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';

/// Presents only server-safe state. Local document bytes, names and paths are
/// never rendered, logged or persisted by this screen.
class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage>
    with WidgetsBindingObserver {
  final KycScreenPrivacy _screenPrivacy = KycScreenPrivacy();
  bool _consentAccepted = false;
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_screenPrivacy.setEnabled(true));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<KycCubit>().refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_screenPrivacy.setEnabled(false));
    unawaited(getIt<KycCubit>().clearSensitiveDrafts());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    switch (lifecycle) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (mounted) setState(() => _obscured = true);
        // Launching the system picker or UCrop also pauses this Flutter
        // activity.  While the capture Future is pending, clearing the draft
        // deletes the destination allocated for the crop and drops the KYC
        // session before the native activity can return its result.
        //
        // The page remains obscured and protected by FLAG_SECURE.  Drafts are
        // still purged for every ordinary background transition and on page
        // disposal or logout.
        if (getIt<KycCubit>().state.stage != KycUiStage.capturing) {
          unawaited(getIt<KycCubit>().clearSensitiveDrafts());
        }
        break;
      case AppLifecycleState.resumed:
        if (mounted) setState(() => _obscured = false);
        getIt<KycCubit>().refresh();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<KycCubit>(),
      child: BlocConsumer<KycCubit, KycState>(
        listenWhen: (previous, current) =>
            previous.errorCode != current.errorCode &&
            current.errorCode != null,
        listener: (context, state) => HIVToast.showError(
          context: context,
          message: _errorText(state.errorCode!),
        ),
        builder: (context, state) {
          if (_obscured) return const Scaffold(backgroundColor: Colors.black);
          return Scaffold(
            backgroundColor: AppColors.primaryWhite,
            appBar: AppBar(
              title: Text(_tr('kyc.title')),
              backgroundColor: AppColors.primaryWhite,
              actions: [
                IconButton(
                  tooltip: _tr('kyc.refresh'),
                  onPressed: state.isBusy
                      ? null
                      : () => context.read<KycCubit>().refresh(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _PrivacyNotice(),
                  const SizedBox(height: 16),
                  _StatusCard(snapshot: state.snapshot),
                  const SizedBox(height: 20),
                  if (state.stage == KycUiStage.loading &&
                      state.session == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _body(context, state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, KycState state) {
    if (state.snapshot.hasActiveAccess) {
      return _TerminalPanel(
        icon: Icons.verified_user,
        color: AppColors.success,
        title: _tr('kyc.verified_title'),
        message: _tr('kyc.verified_message'),
      );
    }
    if (state.snapshot.status == KycStatus.pendingReview ||
        state.stage == KycUiStage.submitted) {
      return _TerminalPanel(
        icon: Icons.hourglass_top,
        color: AppColors.info,
        title: _tr('kyc.pending_title'),
        message: _tr('kyc.pending_message'),
      );
    }

    final isRestart = state.snapshot.status == KycStatus.rejected ||
        state.snapshot.status == KycStatus.expired;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isRestart) ...[
          Text(
            state.snapshot.status == KycStatus.rejected
                ? _rejectionText(state.snapshot.rejectionReasonCode)
                : _tr('kyc.expired_message'),
          ),
          const SizedBox(height: 12),
        ],
        if (state.session == null)
          _StartPanel(
            consentAccepted: _consentAccepted,
            onChanged: (value) => setState(() => _consentAccepted = value),
            onStart: state.isBusy
                ? null
                : () => context.read<KycCubit>().start(
                      consentAccepted: _consentAccepted,
                    ),
          )
        else
          _DocumentsPanel(state: state),
      ],
    );
  }

  String _errorText(String code) {
    switch (code) {
      case 'consent_required':
      case 'documents_required':
      case 'challenge_expired':
      case 'camera_permission_denied':
      case 'unsupported_format':
      case 'file_too_large':
      case 'image_quality_insufficient':
      case 'cropper_unavailable':
      case 'capture_failed':
      case 'kyc_required':
      case 'network':
      case 'intent_expired':
      case 'payload_too_large':
      case 'rate_limited':
      case 'invalid_response':
      case 'file_unavailable':
      case 'unsafe_upload_url':
      case 'upload_failed':
      case 'technical_rejected':
      case 'technical_processing_timeout':
        return _tr('kyc.error.$code');
      default:
        return _tr('kyc.error.unavailable');
    }
  }

  String _rejectionText(String? reason) {
    switch (reason) {
      case 'document_unreadable':
      case 'document_expired':
      case 'medical_document_too_old':
      case 'selfie_challenge_mismatch':
      case 'unsupported_document':
        return _tr('kyc.rejection.$reason');
      default:
        return _tr('kyc.rejected_message');
    }
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryPurple.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline, color: AppColors.primaryPurple),
            const SizedBox(width: 12),
            Expanded(child: Text(_tr('kyc.privacy_notice'))),
          ],
        ),
      );
}

class _StatusCard extends StatelessWidget {
  final KycSnapshot snapshot;
  const _StatusCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final status = snapshot.status;
    final (icon, color, label) = switch (status) {
      KycStatus.verified => (
          Icons.verified,
          AppColors.success,
          _tr('kyc.status.verified')
        ),
      KycStatus.pendingReview => (
          Icons.hourglass_top,
          AppColors.info,
          _tr('kyc.status.pending_review')
        ),
      KycStatus.rejected => (
          Icons.cancel_outlined,
          AppColors.error,
          _tr('kyc.status.rejected')
        ),
      KycStatus.expired => (
          Icons.schedule,
          AppColors.warning,
          _tr('kyc.status.expired')
        ),
      _ => (
          Icons.shield_outlined,
          AppColors.primaryPurple,
          _tr('kyc.status.incomplete')
        ),
    };
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(_tr('kyc.status.label')),
        subtitle: Text(label),
      ),
    );
  }
}

class _TerminalPanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  const _TerminalPanel({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 46, color: color),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _StartPanel extends StatelessWidget {
  final bool consentAccepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onStart;
  const _StartPanel({
    required this.consentAccepted,
    required this.onChanged,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_tr('kyc.start_title'),
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(_tr('kyc.start_message')),
          const SizedBox(height: 16),
          _Requirement(
              icon: Icons.badge_outlined,
              text: _tr('kyc.requirement.identity')),
          _Requirement(
              icon: Icons.description_outlined,
              text: _tr('kyc.requirement.medical')),
          _Requirement(
              icon: Icons.camera_front_outlined,
              text: _tr('kyc.requirement.selfie')),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: consentAccepted,
            onChanged:
                onStart == null ? null : (value) => onChanged(value ?? false),
            title: Text(_tr('kyc.consent')),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.shield_outlined),
            label: Text(_tr('kyc.start_action')),
          ),
        ],
      );
}

class _Requirement extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Requirement({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, color: AppColors.primaryPurple),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ]),
      );
}

class _DocumentsPanel extends StatelessWidget {
  final KycState state;
  const _DocumentsPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<KycCubit>();
    final session = state.session!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_tr('kyc.documents_title'),
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(_tr('kyc.documents_message')),
        if (state.stage == KycUiStage.analysing) ...[
          const SizedBox(height: 12),
          const _TechnicalAnalysisNotice(),
        ],
        const SizedBox(height: 16),
        _DocumentTile(
          type: KycDocumentType.identityDocument,
          state: state,
          onCapture: () =>
              _chooseSource(context, KycDocumentType.identityDocument),
          onRemove: () =>
              cubit.removeDocument(KycDocumentType.identityDocument),
        ),
        _DocumentTile(
          type: KycDocumentType.medicalDocument,
          state: state,
          onCapture: () =>
              _chooseSource(context, KycDocumentType.medicalDocument),
          onRemove: () => cubit.removeDocument(KycDocumentType.medicalDocument),
        ),
        const SizedBox(height: 8),
        _ChallengeCard(code: session.selfieChallengeCode),
        _DocumentTile(
          type: KycDocumentType.selfieWithCode,
          state: state,
          onCapture: () =>
              _chooseSource(context, KycDocumentType.selfieWithCode),
          onRemove: () => cubit.removeDocument(KycDocumentType.selfieWithCode),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: state.canSubmit ? cubit.submit : null,
          icon: state.stage == KycUiStage.uploading ||
                  state.stage == KycUiStage.analysing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: Text(switch (state.stage) {
            KycUiStage.uploading => _tr('kyc.submitting'),
            KycUiStage.analysing => _tr('kyc.analysing'),
            _ => _tr('kyc.submit'),
          }),
        ),
      ],
    );
  }

  Future<void> _chooseSource(BuildContext context, KycDocumentType type) async {
    final source = await showModalBottomSheet<KycCaptureSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(_tr('kyc.capture_camera')),
              onTap: () => Navigator.pop(sheetContext, KycCaptureSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(_tr('kyc.capture_file')),
              onTap: () => Navigator.pop(sheetContext, KycCaptureSource.files),
            ),
          ],
        ),
      ),
    );
    if (source != null && context.mounted) {
      context.read<KycCubit>().captureDocument(type: type, source: source);
    }
  }
}

class _ChallengeCard extends StatelessWidget {
  final String code;
  const _ChallengeCard({required this.code});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tr('kyc.challenge_title'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(_tr('kyc.challenge_message')),
            const SizedBox(height: 10),
            Text(code,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.darkPurple,
                      fontWeight: FontWeight.bold,
                    )),
          ],
        ),
      );
}

class _TechnicalAnalysisNotice extends StatelessWidget {
  const _TechnicalAnalysisNotice();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(_tr('kyc.analysing_message'))),
          ],
        ),
      );
}

class _DocumentTile extends StatelessWidget {
  final KycDocumentType type;
  final KycState state;
  final VoidCallback onCapture;
  final VoidCallback onRemove;
  const _DocumentTile({
    required this.type,
    required this.state,
    required this.onCapture,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final captured = state.documents.containsKey(type);
    final accepted = state.hasAcceptedDocument(type);
    final progress = state.uploadProgress[type];
    final title = switch (type) {
      KycDocumentType.identityDocument => _tr('kyc.document.identity'),
      KycDocumentType.medicalDocument => _tr('kyc.document.medical'),
      KycDocumentType.selfieWithCode => _tr('kyc.document.selfie'),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            Icon(
                captured || accepted
                    ? Icons.check_circle
                    : Icons.upload_file_outlined,
                color:
                    captured || accepted ? AppColors.success : AppColors.slate),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
            if (captured)
              IconButton(
                tooltip: _tr('kyc.remove_document'),
                onPressed: state.isBusy ? null : onRemove,
                icon: const Icon(Icons.delete_outline),
              )
            else if (!accepted)
              TextButton(
                onPressed: state.isBusy ? null : onCapture,
                child: Text(_tr('kyc.add_document')),
              ),
          ]),
          if (accepted)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_tr('kyc.document_accepted'),
                  style: Theme.of(context).textTheme.bodySmall),
            )
          else if (captured)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_tr('kyc.document_ready'),
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
          ],
        ]),
      ),
    );
  }
}

String _tr(String key) => LocalizationService.translate(key);
