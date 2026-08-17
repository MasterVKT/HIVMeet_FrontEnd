import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_bloc.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_event.dart';
import 'package:hivmeet/presentation/blocs/profile/profile_state.dart';
import 'package:hivmeet/presentation/widgets/common/hiv_toast.dart';
import 'package:hivmeet/presentation/widgets/common/retry_panel.dart';
import 'package:hivmeet/presentation/widgets/loaders/hiv_loader.dart';
import 'package:image_picker/image_picker.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  File? _identity;
  File? _medical;
  File? _selfie;
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(LoadProfile()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            HIVToast.showError(context: context, message: _tr(state.message));
          }
          if (state is ProfileActionSuccess) {
            HIVToast.showSuccess(context: context, message: _tr(state.message));
            setState(() {
              _identity = null;
              _medical = null;
              _selfie = null;
            });
          }
        },
        builder: (context, state) {
          final loaded = _loadedFrom(state);
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Scaffold(body: Center(child: HIVLoader()));
          }
          if (loaded == null) {
            return Scaffold(
              body: RetryPanel(
                messageKey: 'profile.load_error',
                onRetry: () => context.read<ProfileBloc>().add(LoadProfile()),
              ),
            );
          }

          final verification = loaded.verification;
          _codeController.text = _codeController.text.isEmpty
              ? verification?.verificationCode ?? ''
              : _codeController.text;
          final isSubmitting = state is ProfileSectionLoading;

          return Scaffold(
            backgroundColor: AppColors.primaryWhite,
            appBar: AppBar(
              title: Text(_tr('profile.verification')),
              backgroundColor: AppColors.primaryWhite,
            ),
            body: ListView(
              padding: EdgeInsets.all(AppSpacing.md),
              children: [
                _StatusCard(status: verification?.status ?? 'not_started'),
                const SizedBox(height: 16),
                Text(
                  _tr('profile.verification_code'),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  verification?.verificationCode ??
                      _tr('profile.code_unavailable'),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppColors.primaryPurple,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: _tr('profile.selfie_code_used'),
                  ),
                ),
                const SizedBox(height: 16),
                _DocumentPickerTile(
                  title: _tr('profile.identity_document'),
                  file: _identity,
                  onPick: () => _pickDocument(
                    (file) => setState(() => _identity = file),
                  ),
                ),
                _DocumentPickerTile(
                  title: _tr('profile.medical_document'),
                  file: _medical,
                  onPick: () => _pickDocument(
                    (file) => setState(() => _medical = file),
                  ),
                ),
                _DocumentPickerTile(
                  title: _tr('profile.selfie_with_code'),
                  file: _selfie,
                  actionLabel: _tr('profile.take_selfie'),
                  onPick: () => _pickSelfie(
                    (file) => setState(() => _selfie = file),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _canSubmit(verification) && !isSubmitting
                      ? () => _submit(context)
                      : null,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_user_outlined),
                  label: Text(_tr('profile.submit_verification')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _canSubmit(VerificationDetails? verification) {
    final status = verification?.status;
    if (status == 'pending_review' || status == 'verified') return false;
    return _identity != null &&
        _medical != null &&
        _selfie != null &&
        _codeController.text.trim().isNotEmpty;
  }

  Future<void> _pickDocument(ValueChanged<File> onPicked) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;
    await _validateAndUse(File(path), onPicked, allowPdf: true);
  }

  Future<void> _pickSelfie(ValueChanged<File> onPicked) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (picked == null) return;
    await _validateAndUse(File(picked.path), onPicked, allowPdf: false);
  }

  Future<void> _validateAndUse(
    File file,
    ValueChanged<File> onPicked, {
    required bool allowPdf,
  }) async {
    final lower = file.path.toLowerCase();
    final isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
    final isPdf = lower.endsWith('.pdf');
    if (!isImage && !(allowPdf && isPdf)) {
      if (mounted) {
        HIVToast.showError(
          context: context,
          message: allowPdf
              ? _tr('profile.document_type_error')
              : _tr('profile.selfie_type_error'),
        );
      }
      return;
    }
    if (await file.length() > 10 * 1024 * 1024) {
      if (mounted) {
        HIVToast.showError(
          context: context,
          message: _tr('profile.document_size_error'),
        );
      }
      return;
    }
    onPicked(file);
  }

  void _submit(BuildContext context) {
    context.read<ProfileBloc>().add(SubmitVerificationDocuments(
          identityDocument: _identity!,
          medicalDocument: _medical!,
          selfieWithCode: _selfie!,
          selfieCode: _codeController.text.trim(),
        ));
  }
}

class _StatusCard extends StatelessWidget {
  final String status;

  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primaryPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${_tr('profile.status')}: ${_statusLabel(status)}'),
          ),
        ],
      ),
    );
  }
}

class _DocumentPickerTile extends StatelessWidget {
  final String title;
  final File? file;
  final String? actionLabel;
  final VoidCallback onPick;

  const _DocumentPickerTile({
    required this.title,
    required this.file,
    this.actionLabel,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          file == null ? Icons.upload_file_outlined : Icons.check_circle,
          color: file == null ? AppColors.slate : AppColors.success,
        ),
        title: Text(title),
        subtitle: Text(
          file == null
              ? _tr('profile.no_file_selected')
              : _tr('profile.file_selected'),
        ),
        trailing: TextButton(
          onPressed: onPick,
          child: Text(actionLabel ?? _tr('profile.choose_file')),
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'verified':
      return _tr('profile.verified');
    case 'pending_review':
      return _tr('profile.verification_pending');
    case 'rejected':
      return _tr('profile.verification_rejected');
    case 'expired':
      return _tr('profile.verification_expired');
    default:
      return _tr('profile.verification_not_started');
  }
}

ProfileLoaded? _loadedFrom(ProfileState state) {
  if (state is ProfileLoaded) return state;
  if (state is ProfileActionSuccess) return state.loadedState;
  if (state is ProfileError) return state.loadedState;
  if (state is ProfileSectionLoading) return state.previousState;
  return null;
}

String _tr(String key) => LocalizationService.translate(key);
