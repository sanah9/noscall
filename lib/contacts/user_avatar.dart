import 'package:flutter/material.dart';
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
    final displayName = user.getUserShowName();
    final radius = this.radius;
    return CircleAvatar(
      backgroundColor: colorScheme.primary,
      radius: radius,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '',
        style: TextStyle(
          fontSize: radius != null ? radius / 2 : null,
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}