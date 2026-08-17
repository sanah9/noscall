import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:noscall/call_payments/application/call_payment_recovery_service.dart';
import 'package:noscall/call_payments/application/call_payment_runtime.dart';
import 'package:noscall/call_payments/infrastructure/call_payment_nostr_gateway.dart';
import 'package:noscall/call_payments/infrastructure/isar_call_payment_repository.dart';
import 'package:noscall/core/account/account.dart';
import 'package:noscall/core/call/contacts/contacts.dart';
import 'package:noscall/core/common/database/db_isar.dart';
import 'package:noscall/wallet/application/wallet_session_manager.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';
import 'package:noscall/wallet/domain/wallet_errors.dart';
import 'package:noscall/wallet/infrastructure/cdk/cdk_account_wallet.dart';
import 'package:noscall/wallet/infrastructure/security/development_file_wallet_key_store.dart';

typedef CallPaymentRuntimeFactory = Future<CallPaymentRuntime> Function();

final class MobileCallPaymentRuntimeFactory {
  const MobileCallPaymentRuntimeFactory._();

  static Future<CallPaymentRuntime> create() async {
    if (!kDebugMode) {
      throw StateError(
        'Secure wallet storage is required before release builds can use paid calls.',
      );
    }

    final account = Account.sharedInstance;
    final pubkey = account.currentPubkey;
    final privkey = account.currentPrivkey;
    if (pubkey.isEmpty || privkey.isEmpty) {
      throw StateError('A Nostr account is required to use paid calls.');
    }

    final owner = CashuAccountId.fromNostrPubkey(pubkey);
    final supportDirectory = await getApplicationSupportDirectory();
    final walletRoot = Directory('${supportDirectory.path}/cashu');
    final walletFactory = CdkAccountWalletFactory(
      walletsRoot: Directory('${walletRoot.path}/accounts'),
      keyStore: DevelopmentFileWalletKeyStore(
        Directory('${walletRoot.path}/development-seeds'),
      ),
      allowInsecureDevelopmentStore: true,
    );
    final sessionManager = WalletSessionManager(factory: walletFactory);
    final state = await sessionManager.activate(owner);
    final wallet = state.wallet;
    if (wallet == null) {
      await sessionManager.dispose();
      throw const WalletNotReadyException();
    }

    final isar = DBISAR.sharedInstance.isar;
    return CallPaymentRuntime(
      owner: owner,
      wallet: wallet,
      policyRepository: IsarCallPaymentPolicyRepository(isar),
      sessionRepository: IsarCallPaymentSessionRepository(isar),
      installmentRepository: IsarCallPaymentInstallmentRepository(isar),
      gateway: CallPaymentNostrGateway(pubkey: pubkey, privkey: privkey),
      peerIsContact: Contacts.sharedInstance.allContacts.containsKey,
      dispose: sessionManager.dispose,
    );
  }

  static Future<CallPaymentRecoveryReport> recoverPendingPayments() async {
    final runtime = await create();
    try {
      return await runtime.recoveryService.recover(runtime.owner);
    } finally {
      await runtime.dispose();
    }
  }
}
