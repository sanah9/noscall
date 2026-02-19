import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/account+relay.dart';
import 'package:noscall/core/account/relays.dart';
import 'package:noscall/core/common/network/connect.dart';
import 'package:noscall/utils/toast.dart';
import 'package:noscall/component/icon.dart';

class RelayManagementPage extends StatefulWidget {
  const RelayManagementPage({super.key});

  @override
  State<RelayManagementPage> createState() => _RelayManagementPageState();
}

class _RelayManagementPageState extends State<RelayManagementPage> {
  List<String> _relays = [];
  List<String> _defaultRelays = [];
  bool _isLoading = false;
  Map<String, bool> _testingRelays = {};
  Map<String, bool> _testResults = {};

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
      await Connect.sharedInstance.connectRelays(
        [relay],
        relayKind: RelayKind.temp,
      );

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
      return (uri.scheme == 'ws' || uri.scheme == 'wss') &&
          uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _addRelay() async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Relay'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter relay URL (e.g., wss://relay.example.com)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                Navigator.of(context).pop(url);
              }
            },
            child: const Text('Test & Add'),
          ),
        ],
      ),
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
    final TextEditingController controller = TextEditingController(text: oldRelay);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Relay'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter relay URL',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                Navigator.of(context).pop(url);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
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
              foregroundColor: Colors.red,
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
              foregroundColor: Colors.orange,
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
    final connectedCount = _getConnectedCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relay Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Default',
            onPressed: _resetToDefault,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      SSIcon(
                        icon: Icons.dns,
                        size: 32,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_relays.length} Relay${_relays.length != 1 ? 's' : ''}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$connectedCount connected',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: connectedCount > 0
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          connectedCount > 0 ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: connectedCount > 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Relay list
                Expanded(
                  child: _relays.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_off,
                                size: 64,
                                color: colorScheme.onSurfaceVariant,
                              ),
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
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _relays.length,
                          itemBuilder: (context, index) {
                            final relay = _relays[index];
                            final socket = Connect.sharedInstance.webSockets[relay];
                            final status = socket?.connectStatus ?? 3;
                            final isConnected = status == 1;
                            final isTesting = _testingRelays[relay] ?? false;
                            final testResult = _testResults[relay];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: _buildStatusIndicator(
                                  isConnected,
                                  isTesting,
                                  testResult,
                                ),
                                title: Text(
                                  relay,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  _getStatusText(status, isTesting),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _editRelay(index),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () => _deleteRelay(index),
                                      tooltip: 'Delete',
                                      color: colorScheme.error,
                                    ),
                                  ],
                                ),
                                isThreeLine: false,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRelay,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusIndicator(
    bool isConnected,
    bool isTesting,
    bool? testResult,
  ) {
    if (isTesting) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (isConnected) {
      return const Icon(
        CupertinoIcons.check_mark_circled,
        color: Colors.green,
        size: 24,
      );
    }

    if (testResult == false) {
      return const Icon(
        Icons.error_outline,
        color: Colors.red,
        size: 24,
      );
    }

    return Icon(
      Icons.circle_outlined,
      color: Colors.grey,
      size: 24,
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

