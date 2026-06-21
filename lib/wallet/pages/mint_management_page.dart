import 'dart:async';

import 'package:flutter/material.dart';

import '../application/mint_management_controller.dart';
import '../application/mint_registry_service.dart';
import '../domain/cashu_models.dart';
import '../domain/mint_configuration.dart';
import '../domain/wallet_configuration.dart';
import '../domain/wallet_errors.dart';
import '../infrastructure/mobile/mobile_mint_management_controller_factory.dart';

final class MintManagementPage extends StatefulWidget {
  const MintManagementPage({super.key, this.controllerFactory});

  final MintManagementControllerFactory? controllerFactory;

  @override
  State<MintManagementPage> createState() => _MintManagementPageState();
}

final class _MintManagementPageState extends State<MintManagementPage> {
  MintManagementController? _controller;
  MintManagementSnapshot? _snapshot;
  bool _loading = true;
  bool _mutating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  Future<void> _initialize() async {
    MintManagementController? candidate;
    try {
      final factory =
          widget.controllerFactory ??
          () => MobileMintManagementControllerFactory.create();
      candidate = await factory();
      final snapshot = await candidate.load();
      if (!mounted) {
        await candidate.dispose();
        return;
      }
      setState(() {
        _controller = candidate;
        _snapshot = snapshot;
        _loading = false;
        _errorMessage = null;
      });
    } catch (_) {
      await candidate?.dispose();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Mints could not be loaded.';
      });
    }
  }

  Future<void> _reload() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final snapshot = await controller.load();
      if (mounted) setState(() => _snapshot = snapshot);
    } catch (error) {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mints')),
      floatingActionButton: _snapshot == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _mutating ? null : _addManualMint,
              icon: const Icon(Icons.add),
              label: const Text('Add Mint'),
            ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage case final message?) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _initialize, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final snapshot = _snapshot!;
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Choose Mints carefully'),
              subtitle: Text(
                'Mints custody the bitcoin backing your ecash. noscall does not operate or endorse a Mint.',
              ),
            ),
          ),
          if (snapshot.suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Suggestions', style: Theme.of(context).textTheme.titleMedium),
            ...snapshot.suggestions.map(_buildSuggestion),
          ],
          const SizedBox(height: 16),
          Text('Your Mints', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (snapshot.mints.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.hub_outlined, size: 48),
                    SizedBox(height: 12),
                    Text('No Mint configured'),
                    SizedBox(height: 4),
                    Text(
                      'Add a Mint URL to validate its capabilities before use.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...snapshot.mints.map(_buildMint),
        ],
      ),
    );
  }

  Widget _buildSuggestion(DefaultMintSuggestion suggestion) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.recommend_outlined),
        title: Text(suggestion.displayName ?? suggestion.url.uri.host),
        subtitle: Text(suggestion.url.toString()),
        trailing: const Text('Review'),
        onTap: _mutating ? null : () => _reviewSuggestion(suggestion),
      ),
    );
  }

  Widget _buildMint(MintConfiguration mint) {
    final subtitle = [
      mint.url.toString(),
      if (mint.lastError != null) 'Last check failed: ${mint.lastError}',
    ].join('\n');
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(mint.enabled ? Icons.hub : Icons.hub_outlined),
            title: Text(mint.name ?? mint.url.uri.host),
            subtitle: Text(subtitle),
            value: mint.enabled,
            onChanged: _mutating
                ? null
                : (enabled) => _setEnabled(mint.url, enabled),
          ),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _mutating ? null : () => _refresh(mint.url),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              TextButton.icon(
                onPressed: _mutating ? null : () => _remove(mint),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addManualMint() async {
    final input = await _requestMintUrl();
    if (input == null || !mounted) return;
    await _validateAndConfirm(() => _controller!.validateManual(input));
  }

  Future<void> _reviewSuggestion(DefaultMintSuggestion suggestion) =>
      _validateAndConfirm(() => _controller!.validateSuggestion(suggestion));

  Future<String?> _requestMintUrl() async {
    var input = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Mint'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.url,
          autocorrect: false,
          onChanged: (value) => input = value,
          decoration: const InputDecoration(
            labelText: 'HTTPS Mint URL',
            hintText: 'https://mint.example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(input),
            child: const Text('Validate'),
          ),
        ],
      ),
    );
  }

  Future<void> _validateAndConfirm(
    Future<MintRegistrationPreview> Function() validate,
  ) async {
    setState(() => _mutating = true);
    try {
      final preview = await validate();
      if (!mounted) return;
      final confirmed = await _showPreview(preview);
      if (confirmed != true || !mounted) return;
      final snapshot = await _controller!.confirm(preview);
      if (mounted) setState(() => _snapshot = snapshot);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<bool?> _showPreview(MintRegistrationPreview preview) {
    final mint = preview.snapshot;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(mint.name ?? mint.url.uri.host),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mint.url.toString()),
              if (mint.description case final description?) ...[
                const SizedBox(height: 12),
                Text(description),
              ],
              const SizedBox(height: 16),
              const Text('Cashu: supported'),
              Text(
                'Lightning receive: ${preview.capabilities.canMintBolt11 ? 'supported' : 'unavailable'}',
              ),
              Text(
                'Lightning pay: ${preview.capabilities.canMeltBolt11 ? 'supported' : 'unavailable'}',
              ),
              const SizedBox(height: 16),
              const Text(
                'Trust warning: this Mint will custody the bitcoin backing your ecash. Only continue if you accept that risk.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add Mint'),
          ),
        ],
      ),
    );
  }

  Future<void> _setEnabled(CashuMintUrl url, bool enabled) =>
      _mutate(() => _controller!.setEnabled(url, enabled));

  Future<void> _refresh(CashuMintUrl url) =>
      _mutate(() => _controller!.refresh(url));

  Future<void> _remove(MintConfiguration mint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Mint?'),
        content: const Text(
          'This removes the Mint from noscall settings. It does not delete ecash data held by the wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _mutate(() => _controller!.remove(mint.url));
    }
  }

  Future<void> _mutate(
    Future<MintManagementSnapshot> Function() operation,
  ) async {
    setState(() => _mutating = true);
    try {
      final snapshot = await operation();
      if (mounted) setState(() => _snapshot = snapshot);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = switch (error) {
      CashuProtocolException(:final message) => message,
      UnsupportedMintException(:final supportsSat, :final missingNutNumbers) =>
        supportsSat
            ? 'Mint is missing required NUTs: ${missingNutNumbers.toList()..sort()}.'
            : 'Mint does not provide a usable sat keyset.',
      _ => 'Mint operation failed. Please try again.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
