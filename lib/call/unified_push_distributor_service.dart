import 'dart:io';

import 'package:flutter/material.dart';
import 'package:unifiedpush/unifiedpush.dart';

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
class UnifiedPushDistributorService {
  static final UnifiedPushDistributorService sharedInstance =
      UnifiedPushDistributorService._internal();
  UnifiedPushDistributorService._internal();
  factory UnifiedPushDistributorService() => sharedInstance;

  final PreferencesStore _prefs = PreferencesStore.shared;

  Future<String?> getStoredDistributor() =>
      _prefs.getString(_kDistributorKey);

  Future<void> _saveDistributor(String distributor) async {
    await UnifiedPush.saveDistributor(distributor);
    await _prefs.setString(_kDistributorKey, distributor);
  }

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
      LogUtils.i(
          () => 'UnifiedPush: using stored distributor $stored');
      await UnifiedPush.registerApp('default', null);
      return stored;
    }

    final distributors = await UnifiedPush.getDistributors(null);
    LogUtils.i(
        () => 'UnifiedPush: found ${distributors.length} distributor(s): $distributors');

    if (distributors.isEmpty) {
      if (context.mounted) {
        await showNoDistributorDialog(context);
      }
      return null;
    }

    if (distributors.length == 1) {
      final picked = distributors.first;
      await _saveDistributor(picked);
      await UnifiedPush.registerApp('default', null);
      LogUtils.i(() => 'UnifiedPush: auto-selected $picked');
      return picked;
    }

    if (!context.mounted) return null;
    final picked = await showDistributorPicker(context, distributors);
    if (picked == null) return null;

    await _saveDistributor(picked);
    await UnifiedPush.registerApp('default', null);
    LogUtils.i(() => 'UnifiedPush: user selected $picked');
    return picked;
  }

  /// Re-opens the picker so the user can change their distributor.
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

    await _saveDistributor(picked);
    await UnifiedPush.registerApp('default', null);
    LogUtils.i(() => 'UnifiedPush: distributor changed to $picked');
    return picked;
  }
}
