import 'package:noscall/core/common/utils/log_utils.dart';
import 'package:noscall/core/common/storage/preferences_store.dart';

/// Service for managing VoIP push notification tokens
/// 
/// Follows Apple's best practices:
/// - Does not persist token itself (server is the source of truth)
/// - Only persists "last uploaded token" for change detection
/// - Uploads token only when it changes
/// - Clears token on user logout
class PushTokenService {
  static final PushTokenService sharedInstance = PushTokenService._internal();
  PushTokenService._internal();
  factory PushTokenService() => sharedInstance;

  // Key for storing the last uploaded token (only for change detection)
  static const String _lastUploadedTokenKey = 'noscall_voip_last_uploaded_token';
  final PreferencesStore _prefs = PreferencesStore.shared;

  /// Upload VoIP push token to server
  /// 
  /// This method should upload the VoIP push token to your backend server.
  /// The server will use this token to send VoIP push notifications for incoming calls.
  /// 
  /// According to Apple's best practices:
  /// - Token should be uploaded immediately to server
  /// - Server is the source of truth for token storage
  /// - Only persist "last uploaded token" locally for change detection
  /// 
  /// [token] - The VoIP push token (hex string format)
  /// 
  /// Returns true if upload was successful, false otherwise
  Future<bool> uploadVoIPToken(String token) async {
    if (token.isEmpty) {
      LogUtils.w(() => 'PushTokenService: Cannot upload empty VoIP token');
      return false;
    }

    try {
      final previewLength = token.length < 20 ? token.length : 20;
      LogUtils.i(() => 'PushTokenService: Uploading VoIP token: ${token.substring(0, previewLength)}...');

      // TODO: Implement VoIP token upload to server
      // 
      // Best practices implementation:
      // 1. Get current user information (pubkey) if needed
      // 2. Call server API endpoint to upload token
      // 3. Handle authentication if required
      // 4. Handle response and errors
      // 5. Only save locally AFTER successful upload (for change detection)
      //
      // Example code structure:
      // try {
      //   final response = await dio.post(
      //     '$serverUrl/api/voip-token',
      //     data: {
      //       'token': token,
      //       'platform': 'ios',
      //       'userId': currentUserPubkey, // or user ID
      //     },
      //     options: Options(
      //       headers: {
      //         'Authorization': 'Bearer $authToken', // if needed
      //         'Content-Type': 'application/json',
      //       },
      //     ),
      //   );
      //   
      //   if (response.statusCode == 200 || response.statusCode == 201) {
      //     // Only save locally AFTER successful upload (for change detection only)
      //     await _markTokenAsUploaded(token);
      //     LogUtils.i(() => 'PushTokenService: VoIP token uploaded successfully');
      //     return true;
      //   } else {
      //     LogUtils.e(() => 'PushTokenService: Failed to upload VoIP token: ${response.statusCode}');
      //     return false;
      //   }
      // } catch (e) {
      //   LogUtils.e(() => 'PushTokenService: Error uploading VoIP token: $e');
      //   return false;
      // }

      // Placeholder: Mark as uploaded locally (for testing/debugging)
      // In production, this should only happen AFTER successful server upload
      await _markTokenAsUploaded(token);
      
      LogUtils.w(() => 'PushTokenService: VoIP token upload not implemented, marked as uploaded locally only');
      return false; // Return false until server implementation is complete
    } catch (e, stack) {
      LogUtils.e(() => 'PushTokenService: Error in uploadVoIPToken: $e, $stack');
      return false;
    }
  }

  /// Mark token as uploaded (for change detection only)
  /// 
  /// According to Apple's best practices, we only persist the "last uploaded token"
  /// for change detection, not for storage purposes. The server is the source of truth.
  Future<void> _markTokenAsUploaded(String token) async {
    final ok = await _prefs.setString(_lastUploadedTokenKey, token);
    if (ok) {
      LogUtils.v(() => 'PushTokenService: Token marked as uploaded (for change detection)');
    } else {
      LogUtils.e(() => 'PushTokenService: Failed to mark token as uploaded');
    }
  }

  /// Get the last uploaded token (for change detection only)
  /// 
  /// This is NOT for retrieving the token for use.
  /// It's only used to detect if the token has changed since last upload.
  Future<String?> getLastUploadedToken() async {
    return _prefs.getString(_lastUploadedTokenKey);
  }

  /// Check if token needs to be uploaded (token changed)
  /// 
  /// Compares the new token with the last uploaded token to determine if upload is needed.
  /// This follows Apple's best practice of only uploading when token changes.
  Future<bool> shouldUploadVoIPToken(String newToken) async {
    final lastUploadedToken = await getLastUploadedToken();
    
    // If no previous token, need to upload
    if (lastUploadedToken == null) {
      return true;
    }
    
    // If token changed, need to upload
    return lastUploadedToken != newToken;
  }

  /// Clear saved VoIP token data (should be called on logout)
  /// 
  /// According to Apple's best practices, token data should be cleared when:
  /// - User logs out
  /// - User data is cleared
  /// 
  /// This ensures that token is re-uploaded for the next user session.
  Future<void> clearVoIPToken() async {
    final ok = await _prefs.remove(_lastUploadedTokenKey);
    if (ok) {
      LogUtils.i(() => 'PushTokenService: VoIP token data cleared');
    } else {
      LogUtils.e(() => 'PushTokenService: Failed to clear VoIP token data');
    }
  }
}

