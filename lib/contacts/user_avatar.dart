import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.size,
  });

  final UserDBISAR user;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayName = user.displayName();
    final size = this.size ?? 44.0;
    final pictureUrl = user.picture;

    Widget avatarWidget;

    if (pictureUrl != null && pictureUrl.isNotEmpty) {
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      avatarWidget = CachedNetworkImage(
        imageUrl: pictureUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: size / 2,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => _buildInitialsAvatar(
          context,
          colorScheme,
          displayName,
          size,
        ),
        errorWidget: (context, url, error) => _buildInitialsAvatar(
          context,
          colorScheme,
          displayName,
          size,
        ),
        fit: BoxFit.cover,
        height: size,
        width: size,
        memCacheWidth: (size * devicePixelRatio).round(),
        memCacheHeight: (size * devicePixelRatio).round(),
        maxWidthDiskCache: (size * devicePixelRatio).round(),
        maxHeightDiskCache: (size * devicePixelRatio).round(),
      );
    } else {
      avatarWidget = _buildInitialsAvatar(
        context,
        colorScheme,
        displayName,
        size,
      );
    }

    return avatarWidget;
  }

  // Widget _build

  Widget _buildInitialsAvatar(
    BuildContext context,
    ColorScheme colorScheme,
    String displayName,
    double size,
  ) {
    return CircleAvatar(
      backgroundColor: colorScheme.primary,
      radius: size / 2,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: (size / 2).floorToDouble(),
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}