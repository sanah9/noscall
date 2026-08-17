import 'package:noscall/wallet/domain/account_wallet.dart';
import 'package:noscall/wallet/domain/cashu_account_id.dart';

import '../domain/call_payment_models.dart';
import '../domain/call_payment_repositories.dart';
import '../infrastructure/call_payment_wallet_adapter.dart';
import 'call_payment_ack_service.dart';
import 'call_payment_coordinator.dart';
import 'call_payment_event_handler.dart';
import 'call_payment_incoming_transfer_service.dart';
import 'call_payment_initial_payment_service.dart';
import 'call_payment_start_guard.dart';
import 'call_payment_top_up_service.dart';

final class CallPaymentRuntime {
  CallPaymentRuntime({
    required CashuAccountId owner,
    required AccountWalletSession wallet,
    required CallPaymentPolicyRepository policyRepository,
    required CallPaymentSessionRepository sessionRepository,
    required CallPaymentInstallmentRepository installmentRepository,
    required CallPaymentTransferGateway gateway,
    required CallPaymentContactChecker peerIsContact,
    CallPaymentClock? clock,
    CallPaymentLifecycleScheduler scheduler =
        const TimerCallPaymentLifecycleScheduler(),
    Future<void> Function()? dispose,
  }) : _owner = owner,
       _policyRepository = policyRepository,
       _sessionRepository = sessionRepository,
       _installmentRepository = installmentRepository,
       _gateway = gateway,
       _peerIsContact = peerIsContact,
       _clock = clock,
       _scheduler = scheduler,
       _dispose = dispose,
       _walletAdapter = AccountWalletCallPaymentAdapter(wallet);

  final CashuAccountId _owner;
  final CallPaymentPolicyRepository _policyRepository;
  final CallPaymentSessionRepository _sessionRepository;
  final CallPaymentInstallmentRepository _installmentRepository;
  final CallPaymentTransferGateway _gateway;
  final CallPaymentContactChecker _peerIsContact;
  final CallPaymentClock? _clock;
  final CallPaymentLifecycleScheduler _scheduler;
  final Future<void> Function()? _dispose;
  final AccountWalletCallPaymentAdapter _walletAdapter;

  CashuAccountId get owner => _owner;

  late final CallPaymentStartGuard startGuard = CallPaymentStartGuard(
    loadPeerPolicy: _loadPeerPolicy,
    loadBalancesByMintSats: _walletAdapter.loadBalancesByMintSats,
    peerIsContact: _peerIsContact,
  );

  late final CallPaymentInitialPaymentService initialPaymentService =
      CallPaymentInitialPaymentService(
        sessionRepository: _sessionRepository,
        installmentRepository: _installmentRepository,
        tokenSender: _walletAdapter,
        gateway: _gateway,
        clock: _clock,
      );

  late final CallPaymentTopUpService topUpService = CallPaymentTopUpService(
    sessionRepository: _sessionRepository,
    installmentRepository: _installmentRepository,
    tokenSender: _walletAdapter,
    gateway: _gateway,
    clock: _clock,
  );

  late final CallPaymentIncomingTransferService incomingTransferService =
      CallPaymentIncomingTransferService(
        sessionRepository: _sessionRepository,
        installmentRepository: _installmentRepository,
        tokenReceiver: _walletAdapter,
        gateway: _gateway,
        clock: _clock,
      );

  late final CallPaymentAckService ackService = CallPaymentAckService(
    sessionRepository: _sessionRepository,
    installmentRepository: _installmentRepository,
    clock: _clock,
  );

  late final CallPaymentCoordinator coordinator = CallPaymentCoordinator(
    owner: _owner,
    sessionRepository: _sessionRepository,
    installmentRepository: _installmentRepository,
    prepareTopUp: topUpService.prepareAndSend,
    scheduler: _scheduler,
    clock: _clock,
  );

  CallPaymentEventHandler eventHandler({
    CallPaymentEventCallTypeResolver? resolveCallType,
  }) {
    return CallPaymentEventHandler(
      owner: _owner,
      receiveTransfer: incomingTransferService.receiveAndAck,
      applyAck: ackService.apply,
      resolveCallType: resolveCallType,
    );
  }

  Future<CallPaymentPolicy?> _loadPeerPolicy(String peerPubkey) {
    return _policyRepository.find(CashuAccountId.fromNostrPubkey(peerPubkey));
  }

  Future<CallPaymentInitialPaymentResult> prepareInitialPayment(
    CallPaymentInitialPaymentRequest request,
  ) {
    return initialPaymentService.prepareAndSend(request);
  }

  Future<CallPaymentTopUpResult> prepareTopUp(CallPaymentTopUpRequest request) {
    return topUpService.prepareAndSend(request);
  }

  Future<void> dispose() async {
    await _dispose?.call();
  }
}
