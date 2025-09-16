import 'package:flutter/services.dart';

class ChatCoreInitConfig {
  const ChatCoreInitConfig({
    required this.pubkey,
    required this.databasePath,
    required this.encryptionPassword,
    this.circleId,
    this.isLite = false,
    this.circleRelay,
    this.contactUpdatedCallBack,
    this.allowSendNotification = false,
    this.allowReceiveNotification = false,
    this.pushServerRelay = '',
  });

  // User identity
  final String pubkey;
  final String? circleId;

  // Database configuration
  final String databasePath;
  final String encryptionPassword;

  // Mode configuration
  final bool isLite;
  final String? circleRelay;

  // Callbacks
  final VoidCallback? contactUpdatedCallBack;

  // Notification configuration
  final bool allowSendNotification;
  final bool allowReceiveNotification;
  final String pushServerRelay;

  // Derived properties for MLS
  String get mlsIdentity => circleId != null ? '$pubkey-$circleId' : pubkey;
  String get mlsPath => databasePath; // MLS uses same directory as circle database
} 