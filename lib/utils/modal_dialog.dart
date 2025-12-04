import 'package:flutter/material.dart';

class ModalDialogConfig {
  final bool barrierDismissible;
  final Color? barrierColor;
  final Duration transitionDuration;
  final Curve curve;
  final double scaleBegin;
  final double scaleEnd;
  final bool useFadeAnimation;
  final bool useScaleAnimation;
  final EdgeInsets? insetPadding;
  final double borderRadius;

  const ModalDialogConfig({
    this.barrierDismissible = true,
    this.barrierColor,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutBack,
    this.scaleBegin = 0.0,
    this.scaleEnd = 1.0,
    this.useFadeAnimation = true,
    this.useScaleAnimation = true,
    this.insetPadding,
    this.borderRadius = 20.0,
  });

  factory ModalDialogConfig.custom({
    bool? barrierDismissible,
    Color? barrierColor,
    Duration? transitionDuration,
    Curve? curve,
    double? scaleBegin,
    double? scaleEnd,
    bool? useFadeAnimation,
    bool? useScaleAnimation,
    EdgeInsets? insetPadding,
    double? borderRadius,
  }) {
    return ModalDialogConfig(
      barrierDismissible: barrierDismissible ?? true,
      barrierColor: barrierColor,
      transitionDuration: transitionDuration ?? const Duration(milliseconds: 300),
      curve: curve ?? Curves.easeOutCubic,
      scaleBegin: scaleBegin ?? 0.9,
      scaleEnd: scaleEnd ?? 1.0,
      useFadeAnimation: useFadeAnimation ?? true,
      useScaleAnimation: useScaleAnimation ?? true,
      insetPadding: insetPadding,
      borderRadius: borderRadius ?? 20.0,
    );
  }
}

class AppModalDialog {
  static void show(
      BuildContext context, {
        required WidgetBuilder builder,
        ModalDialogConfig? config,
      }) {
    final dialogConfig = config ?? const ModalDialogConfig();

    showGeneralDialog(
      context: context,
      barrierDismissible: dialogConfig.barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: dialogConfig.barrierColor ?? Colors.black.withValues(alpha: 0.5),
      transitionDuration: dialogConfig.transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        Widget result = child;

        if (dialogConfig.useScaleAnimation) {
          result = ScaleTransition(
            scale: Tween<double>(
              begin: dialogConfig.scaleBegin,
              end: dialogConfig.scaleEnd,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: dialogConfig.curve,
              ),
            ),
            child: result,
          );
        }

        if (dialogConfig.useFadeAnimation) {
          result = FadeTransition(
            opacity: animation,
            child: result,
          );
        }

        return result;
      },
    );
  }

  static void showDialog({
    required BuildContext context,
    required Widget child,
    ModalDialogConfig? config,
  }) {
    final dialogConfig = config ?? const ModalDialogConfig();
    final insetPadding = dialogConfig.insetPadding ?? const EdgeInsets.symmetric(horizontal: 20);

    show(
      context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: insetPadding,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(dialogConfig.borderRadius),
          child: child,
        ),
      ),
      config: config,
    );
  }

  static void showStandardDialog({
    required BuildContext context,
    required IconData headerIcon,
    required String title,
    String? subtitle,
    required Widget content,
    ModalDialogConfig? config,
  }) {
    showDialog(
      context: context,
      config: config,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              context: context,
              headerIcon: headerIcon,
              title: title,
              subtitle: subtitle,
            ),
            content,
          ],
        ),
      ),
    );
  }

  static Widget _buildHeader({
    required BuildContext context,
    required IconData headerIcon,
    required String title,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    return Container(
      color: primaryColor,
      padding: const EdgeInsets.only(
        left: 20,
        right: 6,
        top: 12,
        bottom: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color.alphaBlend(Colors.white.withValues(alpha: 0.2), primaryColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              headerIcon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}