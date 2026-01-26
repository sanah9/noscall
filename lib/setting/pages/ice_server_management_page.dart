import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../call/ice_server_manager.dart';
import '../../utils/toast.dart';
import '../../component/icon.dart';

class IceServerManagementPage extends StatefulWidget {
  const IceServerManagementPage({super.key});

  @override
  State<IceServerManagementPage> createState() => _IceServerManagementPageState();
}

class _IceServerManagementPageState extends State<IceServerManagementPage> {
  List<ICEServerModel> _iceServers = [];
  List<ICEServerModel> _defaultServers = [];
  bool _isLoading = false;
  bool _useCustomServers = false;

  @override
  void initState() {
    super.initState();
    _defaultServers = List.from(ICEServerManager.shared.defaultICEServers);
    _loadServers();
  }

  Future<void> _loadServers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customServers = await ICEServerManager.shared.loadCustomServers();
      setState(() {
        _useCustomServers = customServers.isNotEmpty;
        _iceServers = customServers.isNotEmpty
            ? List.from(customServers)
            : List.from(_defaultServers);
      });
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Failed to load ICE servers: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveServers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_useCustomServers && _iceServers.isNotEmpty) {
        final success = await ICEServerManager.shared.saveCustomServers(_iceServers);
        if (success && mounted) {
          AppToast.showSuccess(context, 'ICE servers saved successfully');
        } else if (mounted) {
          AppToast.showError(context, 'Failed to save ICE servers');
        }
      } else {
        final success = await ICEServerManager.shared.clearCustomServers();
        if (success && mounted) {
          AppToast.showSuccess(context, 'Reset to default servers');
        } else if (mounted) {
          AppToast.showError(context, 'Failed to reset servers');
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Failed to save ICE servers: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidIceServerUrl(String url) {
    if (url.isEmpty) return false;
    
    // Support STUN format: stun:host:port or stuns:host:port
    if (url.startsWith('stun:') || url.startsWith('stuns:')) {
      try {
        final uri = Uri.parse(url);
        return uri.host.isNotEmpty;
      } catch (e) {
        return false;
      }
    }
    
    // Support TURN format: turn:username:password@host:port
    if (url.startsWith('turn:') || url.startsWith('turns:')) {
      if (!url.contains('@')) return false;
      try {
        final parts = url.split('@');
        if (parts.length != 2) return false;
        final credentialPart = parts[0];
        final hostPart = parts[1];
        
        // Check credential format: turn:username:password
        final credentialParts = credentialPart.split(':');
        if (credentialParts.length < 3) return false;
        
        // Check host format
        final uri = Uri.parse('turn://$hostPart');
        return uri.host.isNotEmpty;
      } catch (e) {
        return false;
      }
    }
    
    return false;
  }

  Future<void> _addServer() async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add ICE Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter ICE server URL',
                border: OutlineInputBorder(),
                helperText: 'Format: stun:host:port or turn:user:pass@host:port',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Examples:\n'
              '• stun:stun.l.google.com:19302\n'
              '• turn:username:password@turn.example.com:3478',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
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
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      String serverUrl = result.trim();

      if (!_isValidIceServerUrl(serverUrl)) {
        if (mounted) {
          AppToast.showError(
            context,
            'Invalid ICE server URL. Must be in format:\n'
            'stun:host:port or turn:user:pass@host:port',
          );
        }
        return;
      }

      if (_iceServers.any((s) => s.url == serverUrl)) {
        if (mounted) {
          AppToast.showError(context, 'ICE server already exists');
        }
        return;
      }

      setState(() {
        _iceServers.add(ICEServerModel(url: serverUrl));
        _useCustomServers = true;
      });
      await _saveServers();
    }
  }

  Future<void> _editServer(int index) async {
    final oldServer = _iceServers[index];
    final TextEditingController controller = TextEditingController(text: oldServer.url);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit ICE Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter ICE server URL',
                border: OutlineInputBorder(),
                helperText: 'Format: stun:host:port or turn:user:pass@host:port',
              ),
              autofocus: true,
            ),
          ],
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
      String serverUrl = result.trim();

      if (!_isValidIceServerUrl(serverUrl)) {
        if (mounted) {
          AppToast.showError(
            context,
            'Invalid ICE server URL. Must be in format:\n'
            'stun:host:port or turn:user:pass@host:port',
          );
        }
        return;
      }

      if (_iceServers.any((s) => s.url == serverUrl && s.url != oldServer.url)) {
        if (mounted) {
          AppToast.showError(context, 'ICE server already exists');
        }
        return;
      }

      setState(() {
        _iceServers[index] = ICEServerModel(url: serverUrl);
        _useCustomServers = true;
      });
      await _saveServers();
    }
  }

  Future<void> _deleteServer(int index) async {
    final server = _iceServers[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ICE Server'),
        content: Text('Are you sure you want to delete "${server.url}"?'),
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
        _iceServers.removeAt(index);
        if (_iceServers.isEmpty) {
          _useCustomServers = false;
        }
      });
      await _saveServers();
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Default'),
        content: const Text(
          'Are you sure you want to reset to the default ICE server list? '
          'This will replace all your current servers.',
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
      setState(() {
        _iceServers = List.from(_defaultServers);
        _useCustomServers = false;
      });
      await _saveServers();
    }
  }

  String _getServerType(ICEServerModel server) {
    if (server.url.startsWith('stun:')) return 'STUN';
    if (server.url.startsWith('stuns:')) return 'STUNS';
    if (server.url.startsWith('turn:')) return 'TURN';
    if (server.url.startsWith('turns:')) return 'TURNS';
    return 'Unknown';
  }

  String _getServerDisplayUrl(ICEServerModel server) {
    // For TURN servers, show a simplified version
    if (server.isTurnAddress) {
      return server.domain;
    }
    return server.url;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ICE Server Management'),
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
                        icon: Icons.settings_ethernet,
                        size: 32,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_iceServers.length} ICE Server${_iceServers.length != 1 ? 's' : ''}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _useCustomServers ? 'Custom configuration' : 'Default configuration',
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
                          color: _useCustomServers
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _useCustomServers ? 'Custom' : 'Default',
                          style: TextStyle(
                            color: _useCustomServers ? Colors.blue : Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Server list
                Expanded(
                  child: _iceServers.isEmpty
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
                                'No ICE servers configured',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add an ICE server to get started',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _iceServers.length,
                          itemBuilder: (context, index) {
                            final server = _iceServers[index];
                            final serverType = _getServerType(server);
                            final displayUrl = _getServerDisplayUrl(server);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Icon(
                                  server.isTurnAddress
                                      ? Icons.swap_horiz
                                      : Icons.dns,
                                  color: colorScheme.primary,
                                ),
                                title: Text(
                                  displayUrl,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Type: $serverType',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (server.isTurnAddress)
                                      Text(
                                        'User: ${server.username}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _editServer(index),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () => _deleteServer(index),
                                      tooltip: 'Delete',
                                      color: colorScheme.error,
                                    ),
                                  ],
                                ),
                                isThreeLine: server.isTurnAddress,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addServer,
        child: const Icon(Icons.add),
      ),
    );
  }
}
