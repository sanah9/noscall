import 'package:flutter/material.dart';
import 'package:noscall/core/account/model/user_db_isar.dart';
import 'package:noscall/core/account/account.dart' as chat_core;
import 'package:noscall/contacts/user_avatar.dart';
import 'package:noscall/contacts/services/contact_remark_service.dart';
import 'package:noscall/contacts/services/favorite_contacts_service.dart';

/// Shared contact row: avatar, name, subtitle, optional favorite star and call buttons.
/// Uses [Account.getUserNotifier] for live updates and [ContactRemarkService] for subtitle.
class ContactListTile extends StatelessWidget {
  const ContactListTile({
    super.key,
    required this.user,
    required this.onTap,
    this.onLongPress,
    this.onCallVoice,
    this.onCallVideo,
    this.showFavoriteStar = true,
    this.searchQuery,
    this.padding = const EdgeInsets.all(16),
  });

  final UserDBISAR user;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onCallVoice;
  final VoidCallback? onCallVideo;
  final bool showFavoriteStar;
  final String? searchQuery;
  final EdgeInsetsGeometry padding;

  static String _displayNameWithRemark(UserDBISAR u, String? query) {
    final nickName = (u.nickName ?? '').trim();
    final name = (u.name ?? '').trim();
    final nameMatched =
        query != null &&
        query.isNotEmpty &&
        name.toLowerCase().contains(query.toLowerCase());
    if (nameMatched && nickName.isNotEmpty && name.isNotEmpty) {
      return '$nickName($name)';
    }
    if (nickName.isNotEmpty) return nickName;
    if (name.isNotEmpty) return name;
    return u.shortEncodedPubkey;
  }

  static List<TextSpan> _highlightSpans({
    required String text,
    required String query,
    required TextStyle normalStyle,
    required TextStyle highlightStyle,
  }) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: normalStyle)];
    }
    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (start < text.length) {
      final index = textLower.indexOf(queryLower, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: normalStyle));
        }
        break;
      }
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: normalStyle),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: highlightStyle,
        ),
      );
      start = index + query.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;

    return ValueListenableBuilder<UserDBISAR>(
      valueListenable: chat_core.Account.sharedInstance.getUserNotifier(
        user.pubKey,
      ),
      builder: (context, updatedUser, child) {
        final displayName = _displayNameWithRemark(updatedUser, searchQuery);
        final titleStyle = theme.textTheme.titleMedium?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w500,
        );
        final highlightStyle = theme.textTheme.titleMedium?.copyWith(
          color: primary,
          fontWeight: FontWeight.w600,
          backgroundColor: primary.withValues(alpha: 0.2),
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: padding,
              child: Row(
                children: [
                  UserAvatar(user: updatedUser, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        searchQuery != null && searchQuery!.isNotEmpty
                            ? RichText(
                                text: TextSpan(
                                  style: titleStyle,
                                  children: _highlightSpans(
                                    text: displayName,
                                    query: searchQuery!,
                                    normalStyle: titleStyle!,
                                    highlightStyle: highlightStyle!,
                                  ),
                                ),
                              )
                            : Text(
                                displayName,
                                style: titleStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        const SizedBox(height: 4),
                        ValueListenableBuilder<Map<String, String>>(
                          valueListenable:
                              ContactRemarkService().remarksNotifier,
                          builder: (context, remarks, _) {
                            final remark = remarks[updatedUser.pubKey] ?? '';
                            final subtitle = remark.isNotEmpty
                                ? remark
                                : updatedUser.shortEncodedPubkey;
                            return Text(
                              subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: onSurfaceVariant,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (showFavoriteStar ||
                      onCallVoice != null ||
                      onCallVideo != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showFavoriteStar) _FavoriteStar(user: updatedUser),
                        if (showFavoriteStar &&
                            (onCallVoice != null || onCallVideo != null))
                          const SizedBox(width: 4),
                        if (onCallVoice != null)
                          _CallButton(
                            icon: Icons.call,
                            onPressed: onCallVoice!,
                          ),
                        if (onCallVoice != null && onCallVideo != null)
                          const SizedBox(width: 8),
                        if (onCallVideo != null)
                          _CallButton(
                            icon: Icons.videocam,
                            onPressed: onCallVideo!,
                          ),
                      ],
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

class _FavoriteStar extends StatelessWidget {
  const _FavoriteStar({required this.user});

  final UserDBISAR user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoriteContactsService().favoritePubkeysNotifier,
      builder: (context, set, _) {
        final isFav = set.contains(user.pubKey);
        return GestureDetector(
          onTap: () => FavoriteContactsService().toggleFavorite(user.pubKey),
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              isFav ? Icons.star : Icons.star_border,
              size: 24,
              color: isFav ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 24, color: colorScheme.primary),
      ),
    );
  }
}
