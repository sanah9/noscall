import 'package:flutter/material.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/account_relay.dart';
import 'package:noscall/core/account/relays.dart';
import 'package:noscall/core/common/network/connect.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/setting/widgets/crud_entry_dialog.dart';
import 'package:noscall/setting/widgets/crud_list_tile_card.dart';
import 'package:noscall/utils/toast.dart';

Color _connectedGreen(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF66BB6A)
      : const Color(0xFF43A047);
}

class RelayManagementPage extends StatefulWidget {
  const RelayManagementPage({super.key});

  @override
  State<RelayManagementPage> createState() => _RelayManagementPageState();
}

class _RelayManagementPageState extends State<RelayManagementPage> {
  List<String> _relays = [];
  List<String> _defaultRelays = [];
  bool _isLoading = false;
  final Map<String, bool> _testingRelays = {};
  final Map<String, bool> _testResults = {};

  @override
  void initState() {
    super.initState();
    _defaultRelays = List.from(Relays.sharedInstance.recommendGeneralRelays);
    _loadRelays();
  }

  void _loadRelays() {
    setState(() {
      final userRelays = Account.sharedInstance.me?.relayList ?? [];
      if (userRelays.isNotEmpty) {
        _relays = List.from(userRelays);
      } else {
        _relays = List.from(_defaultRelays);
      }
    });
  }

  Future<void> _saveRelays() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final account = Account.sharedInstance;
      await account.setGeneralRelayListToLocal(_relays);
      if (mounted) {
        AppToast.showSuccess(context, 'Relay list saved successfully');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Failed to save relay list: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _testRelayConnection(String relay) async {
    setState(() {
      _testingRelays[relay] = true;
      _testResults.remove(relay);
    });

    try {
      await Connect.sharedInstance.connectRelays([
        relay,
      ], relayKind: RelayKind.temp);

      await Future.delayed(const Duration(seconds: 2));

      final socket = Connect.sharedInstance.webSockets[relay];
      bool isConnected = socket?.connectStatus == 1;

      await Connect.sharedInstance.closeTempConnects([relay]);

      setState(() {
        _testingRelays[relay] = false;
        _testResults[relay] = isConnected;
      });

      return isConnected;
    } catch (e) {
      setState(() {
        _testingRelays[relay] = false;
        _testResults[relay] = false;
      });
      return false;
    }
  }

  bool _isValidRelayUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return (uri.scheme == 'ws' || uri.scheme == 'wss') && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _addRelay() async {
    final result = await showCrudEntryDialog(
      context: context,
      title: 'Add Relay',
      hintText: 'Enter relay URL (e.g., wss://relay.example.com)',
      initialValue: '',
      confirmLabel: 'Test & Add',
      cancelLabel: 'Cancel',
    );

    if (result != null && result.isNotEmpty) {
      String relayUrl = result.trim();

      if (relayUrl.endsWith('/')) {
        relayUrl = relayUrl.substring(0, relayUrl.length - 1);
      }

      if (!_isValidRelayUrl(relayUrl)) {
        if (mounted) {
          AppToast.showError(
            context,
            'Invalid relay URL. Must start with ws:// or wss://',
          );
        }
        return;
      }

      if (_relays.contains(relayUrl)) {
        if (mounted) {
          AppToast.showError(context, 'Relay already exists');
        }
        return;
      }

      bool isConnected = await _testRelayConnection(relayUrl);
      if (!isConnected) {
        if (mounted) {
          final shouldAdd = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Connection Test Failed'),
              content: const Text(
                'Failed to connect to the relay. Do you still want to add it?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Add Anyway'),
                ),
              ],
            ),
          );
          if (shouldAdd != true) return;
        }
      }

      setState(() {
        _relays.add(relayUrl);
      });
      await _saveRelays();
    }
  }

  Future<void> _editRelay(int index) async {
    final oldRelay = _relays[index];
    final result = await showCrudEntryDialog(
      context: context,
      title: 'Edit Relay',
      hintText: 'Enter relay URL',
      initialValue: oldRelay,
      confirmLabel: 'Save',
      cancelLabel: 'Cancel',
    );

    if (result != null && result.isNotEmpty) {
      String relayUrl = result.trim();

      if (relayUrl.endsWith('/')) {
        relayUrl = relayUrl.substring(0, relayUrl.length - 1);
      }

      if (!_isValidRelayUrl(relayUrl)) {
        if (mounted) {
          AppToast.showError(
            context,
            'Invalid relay URL. Must start with ws:// or wss://',
          );
        }
        return;
      }

      if (_relays.contains(relayUrl) && relayUrl != oldRelay) {
        if (mounted) {
          AppToast.showError(context, 'Relay already exists');
        }
        return;
      }

      setState(() {
        _relays[index] = relayUrl;
      });
      await _saveRelays();
    }
  }

  Future<void> _deleteRelay(int index) async {
    final relay = _relays[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Relay'),
        content: Text('Are you sure you want to delete "$relay"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _relays.removeAt(index);
      });
      await _saveRelays();
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Default'),
        content: const Text(
          'Are you sure you want to reset to the default relay list? '
          'This will replace all your current relays.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.tertiary,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Update default list (in case it has changed)
      _defaultRelays = List.from(Relays.sharedInstance.recommendGeneralRelays);
      setState(() {
        _relays = List.from(_defaultRelays);
      });
      await _saveRelays();
    }
  }

  int _getConnectedCount() {
    int count = 0;
    for (var relay in _relays) {
      final socket = Connect.sharedInstance.webSockets[relay];
      if (socket?.connectStatus == 1) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: _buildAppBar(context, theme, colorScheme),
      body: _buildBody(context, theme, colorScheme),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRelay,
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      title: Text(
        'Relays',
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        onPressed: () => AppNavigatorScope.requireOf(context).pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: colorScheme.onSurface),
          tooltip: 'Reset to Default',
          onPressed: _resetToDefault,
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      );
    }

    return Column(
      children: [
        _buildSummaryCard(theme, colorScheme),
        Expanded(
          child: _relays.isEmpty
              ? _buildEmptyState(theme, colorScheme)
              : _buildRelayList(context, theme, colorScheme),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme, ColorScheme colorScheme) {
    final connectedCount = _getConnectedCount();
    final primary = colorScheme.primary;
    final onPrimary = colorScheme.onPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              primary,
              primary.withValues(alpha: 0.9),
              Color.lerp(primary, colorScheme.tertiary, 0.4)!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: onPrimary.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bolt, color: onPrimary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_relays.length} Relay${_relays.length != 1 ? 's' : ''}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$connectedCount connected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onPrimary.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: onPrimary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                connectedCount > 0 ? 'Active' : 'Inactive',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No relays configured',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a relay to get started',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelayList(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _relays.length,
      itemBuilder: (context, index) {
        final relay = _relays[index];
        final socket = Connect.sharedInstance.webSockets[relay];
        final status = socket?.connectStatus ?? 3;
        final isConnected = status == 1;
        final isTesting = _testingRelays[relay] ?? false;
        final testResult = _testResults[relay];
        final statusText = _getStatusText(status, isTesting);
        return _RelayListTile(
          relay: relay,
          statusText: statusText,
          isConnected: isConnected,
          isTesting: isTesting,
          testResult: testResult,
          onEdit: () => _editRelay(index),
          onDelete: () => _deleteRelay(index),
        );
      },
    );
  }

  String _getStatusText(int status, bool isTesting) {
    if (isTesting) return 'Testing connection...';

    switch (status) {
      case 0:
        return 'Connecting...';
      case 1:
        return 'Connected';
      case 2:
        return 'Closing...';
      case 3:
      default:
        return 'Disconnected';
    }
  }
}

/// List tile for a single relay: status indicator, title, subtitle, edit/delete.
class _RelayListTile extends StatelessWidget {
  const _RelayListTile({
    required this.relay,
    required this.statusText,
    required this.isConnected,
    required this.isTesting,
    this.testResult,
    required this.onEdit,
    required this.onDelete,
  });

  final String relay;
  final String statusText;
  final bool isConnected;
  final bool isTesting;
  final bool? testResult;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return CrudListTileCard(
      leading: _RelayStatusIndicator(
        isConnected: isConnected,
        isTesting: isTesting,
        testResult: testResult,
      ),
      title: relay,
      subtitle: statusText,
      subtitleColor: isConnected ? _connectedGreen(context) : null,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

/// Status indicator: spinner when testing, circle when connected/disconnected/failed.
class _RelayStatusIndicator extends StatelessWidget {
  const _RelayStatusIndicator({
    required this.isConnected,
    required this.isTesting,
    this.testResult,
  });

  final bool isConnected;
  final bool isTesting;
  final bool? testResult;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isTesting) {
      return SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      );
    }

    final bool showError = testResult == false;
    final Color tintColor = showError
        ? colorScheme.error
        : (isConnected
              ? _connectedGreen(context)
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.6));

    return SizedBox(
      width: 28,
      height: 28,
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: tintColor, width: 2),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tintColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
