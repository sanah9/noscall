import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:unifiedpush/unifiedpush.dart';

import 'package:noscall/call/nostr_relay_push_service.dart';
import 'package:noscall/call/widgets/push_distributor_picker.dart';
import 'package:noscall/core/common/storage/preferences_store.dart';
import 'package:noscall/core/common/utils/log_utils.dart';

const _kDistributorKey = 'noscall_up_distributor';

/// Manages UnifiedPush distributor selection and persistence.
///
/// On first launch (or after clearing the stored distributor):
///   - Zero distributors available → shows the "install a distributor" guidance.
///   - One distributor available  → selects it silently.
///   - Multiple distributors      → shows a picker bottom sheet.
///
/// On subsequent launches the stored distributor is used directly.
///
/// After any successful registration [PushTokenService._onNewEndpoint] fires
/// and triggers [NostrRelayPushService.sync] automatically.
class UnifiedPushDistributorService {
  static final UnifiedPushDistributorService sharedInstance =
      UnifiedPushDistributorService._internal();
  UnifiedPushDistributorService._internal();
  factory UnifiedPushDistributorService() => sharedInstance;

  final PreferencesStore _prefs = PreferencesStore.shared;

  Future<String?> getStoredDistributor() =>
      _prefs.getString(_kDistributorKey);

  Future<void> _saveAndRegister(String distributor) async {
    await UnifiedPush.saveDistributor(distributor);
    await _prefs.setString(_kDistributorKey, distributor);
    // registerApp() triggers onNewEndpoint → uploadToken → relay sync.
    await UnifiedPush.registerApp('default', null);
  }

  /// Unregisters from the current distributor and removes local state.
  /// Relay subscription cleanup is handled by [PushTokenService._onUnregistered].
  Future<void> clearDistributor() async {
    await UnifiedPush.unregister('default');
    await _prefs.remove(_kDistributorKey);
  }

  /// Call this once when the app is ready and has a [BuildContext]
  /// (e.g., after the user logs in, before syncing relay push).
  ///
  /// Returns the package name of the selected distributor, or null if none.
  Future<String?> ensureDistributorSelected(BuildContext context) async {
    if (!Platform.isAndroid) return null;

    final stored = await getStoredDistributor();
    if (stored != null && stored.isNotEmpty) {
      LogUtils.i(() => 'UnifiedPush: using stored distributor $stored');
      // Re-register to ensure onNewEndpoint fires (idempotent if unchanged).
      await UnifiedPush.registerApp('default', null);
      return stored;
    }

    final distributors = await UnifiedPush.getDistributors(null);
    LogUtils.i(
        () => 'UnifiedPush: found ${distributors.length} distributor(s): $distributors');

    if (distributors.isEmpty) {
      if (context.mounted) await showNoDistributorDialog(context);
      return null;
    }

    if (distributors.length == 1) {
      final picked = distributors.first;
      LogUtils.i(() => 'UnifiedPush: auto-selected $picked');
      await _saveAndRegister(picked);
      return picked;
    }

    if (!context.mounted) return null;
    final picked = await showDistributorPicker(context, distributors);
    if (picked == null) return null;

    LogUtils.i(() => 'UnifiedPush: user selected $picked');
    await _saveAndRegister(picked);
    return picked;
  }

  /// Re-opens the picker so the user can change their distributor.
  /// The old distributor is unregistered first so [_onUnregistered] clears
  /// the stale server registration before the new endpoint is uploaded.
  Future<String?> changeDistributor(BuildContext context) async {
    if (!Platform.isAndroid) return null;

    final distributors = await UnifiedPush.getDistributors(null);
    if (distributors.isEmpty) {
      if (context.mounted) await showNoDistributorDialog(context);
      return null;
    }

    if (!context.mounted) return null;
    final picked = await showDistributorPicker(context, distributors);
    if (picked == null) return null;

    // Unregister old distributor first → triggers _onUnregistered → server cleanup.
    final stored = await getStoredDistributor();
    if (stored != null && stored != picked) {
      try {
        await UnifiedPush.unregister('default');
      } catch (e) {
        LogUtils.w(() => 'UnifiedPush: failed to unregister old distributor: $e');
      }
    }

    LogUtils.i(() => 'UnifiedPush: distributor changed to $picked');
    await _saveAndRegister(picked);

    // Relay sync happens automatically via onNewEndpoint → uploadToken → sync.
    // But if user is already logged in and registration was immediate, nudge it.
    unawaited(NostrRelayPushService().syncIfDue(force: true));
    return picked;
  }
}
