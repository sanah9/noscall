import 'package:flutter/material.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/account/account+profile.dart';
import 'package:noscall/core/common/network/connect.dart';

/// Mixin that syncs profile once when general relay connects.
/// Use [initProfileSync] in initState and [disposeProfileSync] in dispose.
mixin ProfileSyncOnConnectMixin<T extends StatefulWidget> on State<T> {
  bool _profileSynced = false;

  void initProfileSync() {
    Connect.sharedInstance.addConnectStatusListener(_onConnectStatusChanged);
    _syncProfileIfNeeded();
  }

  void disposeProfileSync() {
    Connect.sharedInstance.removeConnectStatusListener(_onConnectStatusChanged);
  }

  void _onConnectStatusChanged(String relay, int status, List<RelayKind> relayKinds) {
    if (status == 1 && relayKinds.contains(RelayKind.general)) {
      _syncProfileIfNeeded();
    }
  }

  Future<void> _syncProfileIfNeeded() async {
    if (_profileSynced) return;

    final connectedRelays = Connect.sharedInstance.relays(relayKinds: [RelayKind.general]);
    if (connectedRelays.isEmpty) return;

    final me = Account.sharedInstance.me;
    if (me == null || (me.name ?? '').isEmpty) return;

    final result = await Account.sharedInstance.updateProfile(me);
    if (result != null && mounted) {
      setState(() {
        _profileSynced = true;
      });
    }
  }
}
