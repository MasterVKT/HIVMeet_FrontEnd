// lib/presentation/widgets/dialogs/hiv_dialogs.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';

class HIVDialog extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String? content;
  final Widget? contentWidget;
  final List<DialogAction>? actions;
  final bool showCloseButton;
  final EdgeInsetsGeometry? contentPadding;

  const HIVDialog({
    super.key,
    this.title,
    this.titleWidget,
    this.content,
    this.contentWidget,
    this.actions,
    this.showCloseButton = true,
    this.contentPadding,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    Widget? titleWidget,
    String? content,
    Widget? contentWidget,
    List<DialogAction>? actions,
    bool showCloseButton = true,
    bool barrierDismissible = true,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => HIVDialog(
        title: title,
        titleWidget: titleWidget,
        content: content,
        contentWidget: contentWidget,
        actions: actions,
        showCloseButton: showCloseButton,
        contentPadding: contentPadding,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            if (title != null || titleWidget != null || showCloseButton)
              Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  showCloseButton ? AppSpacing.sm : AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: titleWidget ??
                          Text(
                            title ?? '',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                    if (showCloseButton)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            
            // Content
            if (content != null || contentWidget != null)
              Flexible(
                child: SingleChildScrollView(
                  padding: contentPadding ??
                      EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                  child: contentWidget ??
                      Text(
                        content!,
                        style: theme.textTheme.bodyMedium,
                      ),
                ),
              ),
            
            // Actions
            if (actions != null && actions!.isNotEmpty)
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!.map((action) {
                    final isLast = actions!.last == action;
                    return Padding(
                      padding: EdgeInsets.only(
                        left: isLast ? 0 : AppSpacing.sm,
                      ),
                      child: _buildActionButton(context, action),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, DialogAction action) {
    switch (action.type) {
      case DialogActionType.primary:
        return AppButton(
          onPressed: () => action.onPressed(context),
          text: action.label,
          type: ButtonType.primary,
          fullWidth: false,
        );
      case DialogActionType.secondary:
        return AppButton(
          onPressed: () => action.onPressed(context),
          text: action.label,
          type: ButtonType.secondary,
          fullWidth: false,
        );
      case DialogActionType.text:
        return AppButton(
          onPressed: () => action.onPressed(context),
          text: action.label,
          type: ButtonType.tertiary,
          fullWidth: false,
        );
      case DialogActionType.danger:
        return ElevatedButton(
          onPressed: () => action.onPressed(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(action.label),
        );
    }
  }
}

// Dialog action model
class DialogAction {
  final String label;
  final Function(BuildContext) onPressed;
  final DialogActionType type;

  const DialogAction({
    required this.label,
    required this.onPressed,
    this.type = DialogActionType.primary,
  });
}

enum DialogActionType {
  primary,
  secondary,
  text,
  danger,
}

// Confirmation dialog
class HIVConfirmDialog {
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    bool isDangerous = false,
  }) async {
    final result = await HIVDialog.show<bool>(
      context: context,
      title: title,
      content: message,
      showCloseButton: false,
      barrierDismissible: false,
      actions: [
        DialogAction(
          label: cancelLabel,
          type: DialogActionType.text,
          onPressed: (context) => Navigator.of(context).pop(false),
        ),
        DialogAction(
          label: confirmLabel,
          type: isDangerous ? DialogActionType.danger : DialogActionType.primary,
          onPressed: (context) => Navigator.of(context).pop(true),
        ),
      ],
    );
    
    return result ?? false;
  }
}

// Alert dialog with single action
class HIVAlertDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String actionLabel = 'OK',
    VoidCallback? onAction,
  }) {
    return HIVDialog.show(
      context: context,
      title: title,
      content: message,
      showCloseButton: false,
      actions: [
        DialogAction(
          label: actionLabel,
          type: DialogActionType.primary,
          onPressed: (context) {
            Navigator.of(context).pop();
            onAction?.call();
          },
        ),
      ],
    );
  }
}

// Loading dialog
class HIVLoadingDialog {
  static Future<void> show({
    required BuildContext context,
    String? message,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryPurple,
                    ),
                  ),
                  if (message != null) ...[
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

// Success/Error toast notifications
class HIVToast {
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showToast(
      context: context,
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle,
      duration: duration,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showToast(
      context: context,
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error,
      duration: duration,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showToast(
      context: context,
      message: message,
      backgroundColor: AppColors.info,
      icon: Icons.info,
      duration: duration,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showToast(
      context: context,
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning,
      duration: duration,
    );
  }

  static void _showToast({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Start fade out before the end
    Future.delayed(widget.duration - const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + AppSpacing.md,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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