import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.radius,
  });

  final UserDBISAR user;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayName = user.displayName();
    final radius = this.radius ?? 22.0;
    final pictureUrl = user.picture;

    Widget avatarWidget;

    if (pictureUrl != null && pictureUrl.isNotEmpty) {
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      avatarWidget = CachedNetworkImage(
        imageUrl: pictureUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => SizedBox.square(dimension: radius * 2,),
        errorWidget: (context, url, error) => _buildInitialsAvatar(
          context,
          colorScheme,
          displayName,
          radius,
        ),
        memCacheWidth: (radius * devicePixelRatio).round(),
        memCacheHeight: (radius * devicePixelRatio).round(),
        maxWidthDiskCache: (radius * devicePixelRatio).round(),
        maxHeightDiskCache: (radius * devicePixelRatio).round(),
      );
    } else {
      avatarWidget = _buildInitialsAvatar(
        context,
        colorScheme,
        displayName,
        radius,
      );
    }

    return avatarWidget;
  }

  Widget _buildInitialsAvatar(
    BuildContext context,
    ColorScheme colorScheme,
    String displayName,
    double radius,
  ) {
    return CircleAvatar(
      backgroundColor: colorScheme.primary,
      radius: radius,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius,
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}