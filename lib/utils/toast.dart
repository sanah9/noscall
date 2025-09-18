import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ToastType { success, error, warning, info }

class AppToast {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;
  static bool _isDismissing = false;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    required Duration duration,
    ToastPosition position = ToastPosition.bottom,
    bool showCloseButton = false,
  }) {
    _hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        position: position,
        showCloseButton: showCloseButton,
        onDismiss: _hide,
        isDismissing: _isDismissing,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;
    _isDismissing = false;

    Future.delayed(duration, () {
      _hideWithAnimation();
    });
  }

  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    show(context, message, type: ToastType.success, duration: duration ?? const Duration(seconds: 2));
  }

  static void showError(BuildContext context, String message, {Duration? duration}) {
    show(context, message, type: ToastType.error, duration: duration ?? const Duration(seconds: 4));
  }

  static void showWarning(BuildContext context, String message, {Duration? duration}) {
    show(context, message, type: ToastType.warning, duration: duration ?? const Duration(seconds: 3));
  }

  static void showInfo(BuildContext context, String message, {Duration? duration}) {
    show(context, message, type: ToastType.info, duration: duration ?? const Duration(seconds: 3));
  }

  static void _hide() {
    if (_isVisible && _overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isVisible = false;
      _isDismissing = false;
    }
  }

  static void _hideWithAnimation() {
    if (_isVisible && _overlayEntry != null && !_isDismissing) {
      _isDismissing = true;
      _overlayEntry!.markNeedsBuild();
    }
  }
}

enum ToastPosition { top, center, bottom }

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final ToastPosition position;
  final bool showCloseButton;
  final VoidCallback onDismiss;
  final bool isDismissing;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.position,
    required this.showCloseButton,
    required this.onDismiss,
    this.isDismissing = false,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    if (widget.isDismissing) {
      _startDismissAnimation();
    }
  }

  @override
  void didUpdateWidget(_ToastWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDismissing && !oldWidget.isDismissing) {
      _startDismissAnimation();
    }
  }

  void _startDismissAnimation() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaTop = mediaQuery.padding.top;
    final safeAreaBottom = mediaQuery.padding.bottom;

    return Positioned(
      top: widget.position == ToastPosition.top ? safeAreaTop - 4 : null,
      bottom: widget.position == ToastPosition.bottom ? safeAreaBottom + 16 : null,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Material(
                elevation: 8,
                shadowColor: _getShadowColor(colorScheme),
                borderRadius: BorderRadius.circular(16),
                color: _getBackgroundColor(colorScheme),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getBorderColor(colorScheme),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        label: _getSemanticLabel(),
                        child: Icon(
                          _getIcon(),
                          color: _getIconColor(colorScheme),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _getTextColor(colorScheme),
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      if (widget.showCloseButton) ...[
                        const SizedBox(width: 8),
                        Semantics(
                          label: 'Close notification',
                          button: true,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _startDismissAnimation();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: _getTextColor(colorScheme).withOpacity(0.1),
                              ),
                              child: Icon(
                                Icons.close,
                                color: _getTextColor(colorScheme).withOpacity(0.7),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (widget.type) {
      case ToastType.success:
        return colorScheme.inverseSurface;
      case ToastType.error:
        return colorScheme.errorContainer;
      case ToastType.warning:
        return colorScheme.tertiaryContainer;
      case ToastType.info:
        return colorScheme.primaryContainer;
    }
  }

  Color _getTextColor(ColorScheme colorScheme) {
    switch (widget.type) {
      case ToastType.success:
        return colorScheme.onInverseSurface;
      case ToastType.error:
        return colorScheme.onErrorContainer;
      case ToastType.warning:
        return colorScheme.onTertiaryContainer;
      case ToastType.info:
        return colorScheme.onPrimaryContainer;
    }
  }

  Color _getIconColor(ColorScheme colorScheme) {
    switch (widget.type) {
      case ToastType.success:
        return colorScheme.primary;
      case ToastType.error:
        return colorScheme.error;
      case ToastType.warning:
        return colorScheme.tertiary;
      case ToastType.info:
        return colorScheme.primary;
    }
  }

  Color _getBorderColor(ColorScheme colorScheme) {
    return colorScheme.outline.withOpacity(0.2);
  }

  Color _getShadowColor(ColorScheme colorScheme) {
    return colorScheme.shadow.withOpacity(0.1);
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.warning:
        return Icons.warning_outlined;
      case ToastType.info:
        return Icons.info_outline;
    }
  }

  String _getSemanticLabel() {
    switch (widget.type) {
      case ToastType.success:
        return 'Success notification';
      case ToastType.error:
        return 'Error notification';
      case ToastType.warning:
        return 'Warning notification';
      case ToastType.info:
        return 'Info notification';
    }
  }
}
