import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/account/account.dart' as ChatCore;
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/contacts/user_avatar.dart';

class ContactSelectPage extends StatefulWidget {
  final List<String>? excludePubKeys;

  const ContactSelectPage({
    super.key,
    this.excludePubKeys,
  });

  @override
  State<ContactSelectPage> createState() => _ContactSelectPageState();
}

class _ContactSelectPageState extends State<ContactSelectPage> {
  final Set<String> _selectedPubKeys = {};
  final Set<String> _excludePubKeys;

  _ContactSelectPageState()
      : _excludePubKeys = {};

  @override
  void initState() {
    super.initState();
    if (widget.excludePubKeys != null) {
      _excludePubKeys.addAll(widget.excludePubKeys!);
    }
  }

  List<UserDBISAR> get _availableContacts {
    return Contacts.sharedInstance.allContacts.values
        .where((contact) => !_excludePubKeys.contains(contact.pubKey))
        .toList();
  }

  void _toggleSelection(String pubKey) {
    setState(() {
      if (_selectedPubKeys.contains(pubKey)) {
        _selectedPubKeys.remove(pubKey);
      } else {
        _selectedPubKeys.add(pubKey);
      }
    });
  }

  void _onComplete() {
    context.pop(_selectedPubKeys.toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contacts'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _selectedPubKeys.isEmpty ? null : _onComplete,
            child: Text(
              'Done',
              style: TextStyle(
                color: _selectedPubKeys.isEmpty
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                    : colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: _availableContacts.isEmpty
          ? _buildEmptyState(colorScheme)
          : _buildContactsList(colorScheme),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No contacts available',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(ColorScheme colorScheme) {
    return ListView.builder(
      itemCount: _availableContacts.length,
      itemBuilder: (context, index) {
        final contact = _availableContacts[index];
        final isSelected = _selectedPubKeys.contains(contact.pubKey);

        return _buildContactCard(context, contact, isSelected, colorScheme);
      },
    );
  }

  Widget _buildContactCard(BuildContext context, UserDBISAR contact,
      bool isSelected, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<UserDBISAR>(
      valueListenable: ChatCore.Account.sharedInstance.getUserNotifier(contact.pubKey),
      builder: (context, updatedUser, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleSelection(contact.pubKey),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(contact.pubKey),
                  ),
                  const SizedBox(width: 12),
                  UserAvatar(
                    user: updatedUser,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          updatedUser.displayName(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          updatedUser.shortEncodedPubkey,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

