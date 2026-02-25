import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/call/ice_server_manager.dart';
import 'package:noscall/utils/toast.dart';

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

    // Support STUN format: stun:host or stun:host:port (Uri.parse does not fill host for stun:host:port)
    if (url.startsWith('stun:') || url.startsWith('stuns:')) {
      try {
        final rest = url.substring(url.indexOf(':') + 1);
        if (rest.isEmpty) return false;
        final lastColon = rest.lastIndexOf(':');
        if (lastColon >= 0) {
          final portStr = rest.substring(lastColon + 1);
          final port = int.tryParse(portStr);
          if (port != null && port >= 0 && port <= 65535) {
            final host = rest.substring(0, lastColon);
            return host.isNotEmpty;
          }
        }
        return rest.isNotEmpty;
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
              foregroundColor: Theme.of(context).colorScheme.error,
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
              foregroundColor: Theme.of(context).colorScheme.tertiary,
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
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: _buildAppBar(context, theme, colorScheme),
      body: _buildBody(context, theme, colorScheme),
      floatingActionButton: FloatingActionButton(
        onPressed: _addServer,
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
        'ICE Servers',
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: colorScheme.surface,
      elevation: 1,
      scrolledUnderElevation: 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        onPressed: () => context.pop(),
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
          child: _iceServers.isEmpty
              ? _buildEmptyState(theme, colorScheme)
              : _buildServerList(context, theme, colorScheme),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme, ColorScheme colorScheme) {
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
              child: Icon(
                Icons.settings_ethernet,
                color: onPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_iceServers.length} ICE Server${_iceServers.length != 1 ? 's' : ''}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _useCustomServers
                        ? 'Custom configuration'
                        : 'Default configuration',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onPrimary.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: onPrimary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _useCustomServers ? 'Custom' : 'Default',
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
    );
  }

  Widget _buildServerList(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _iceServers.length,
      itemBuilder: (context, index) => _buildServerItem(
        context,
        theme,
        colorScheme,
        index,
      ),
    );
  }

  Widget _buildServerItem(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    int index,
  ) {
    final server = _iceServers[index];
    final serverType = _getServerType(server);
    final displayUrl = _getServerDisplayUrl(server);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                server.isTurnAddress ? Icons.swap_horiz : Icons.dns,
                size: 16,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayUrl,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    server.isTurnAddress
                        ? '$serverType · ${server.username}'
                        : serverType,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.edit_outlined,
              backgroundColor: colorScheme.surfaceContainerHighest,
              iconColor: colorScheme.onSurfaceVariant,
              onPressed: () => _editServer(index),
              tooltip: 'Edit',
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.delete_outlined,
              backgroundColor: colorScheme.errorContainer,
              iconColor: colorScheme.error,
              onPressed: () => _deleteServer(index),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Material(
      color: backgroundColor.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}
