import 'package:flutter/material.dart';
import 'package:noscall/utils/profile_sync_mixin.dart';
import 'desktop_scaffold.dart';
import 'desktop_navigator.dart';

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({super.key});

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> with ProfileSyncOnConnectMixin<DesktopHomePage> {
  int _selectedIndex = 0;
  double _sidebarWidth = 280;
  bool _isResizing = false;

  double resizeDividerWidth = 8;

  static const double _minSidebarWidth = 200;
  static const double _maxSidebarWidth = 400;

  final GlobalKey<DesktopNavigatorState> _navigatorKey = GlobalKey<DesktopNavigatorState>();

  @override
  void initState() {
    super.initState();
    initProfileSync();
  }

  @override
  void dispose() {
    disposeProfileSync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: _sidebarWidth,
                child: DesktopScaffold(
                  selectedIndex: _selectedIndex,
                  onNavigationChanged: _onNavigationChanged,
                ),
              ),
              Expanded(
                child: DesktopNavigator(
                  key: _navigatorKey,
                  selectedIndex: _selectedIndex,
                  onNavigationChanged: _onNavigationChanged,
                ),
              ),
            ],
          ),
          Positioned(
            left: _sidebarWidth - resizeDividerWidth / 2,
            top: 0,
            bottom: 0,
            child: _buildResizeDivider(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildResizeDivider(ColorScheme colorScheme) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragStart: (_) {
          setState(() {
            _isResizing = true;
          });
        },
        onHorizontalDragUpdate: (details) {
          setState(() {
            _sidebarWidth = (_sidebarWidth + details.delta.dx)
                .clamp(_minSidebarWidth, _maxSidebarWidth);
          });
        },
        onHorizontalDragEnd: (_) {
          setState(() {
            _isResizing = false;
          });
        },
        child: Container(
          width: resizeDividerWidth,
          color: _isResizing
              ? colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          child: Center(
            child: Container(
              width: 1,
              color: _isResizing
                  ? Colors.transparent
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  void _onNavigationChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}