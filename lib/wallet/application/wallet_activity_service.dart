import 'package:noscall/call_payments/application/call_payment_details.dart';
import 'package:noscall/call_payments/domain/call_payment_models.dart';
import 'package:noscall/call_payments/domain/call_payment_summary.dart';
import 'package:noscall/call_payments/infrastructure/isar_call_payment_repository.dart';
import 'package:noscall/core/common/database/db_isar.dart';
import '../domain/cashu_account_id.dart';
import '../domain/cashu_models.dart';
import '../infrastructure/database/isar_wallet_configuration_repository.dart';

enum WalletActivityKind { token, lightning, call }

final class WalletActivityEntry {
  const WalletActivityEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.status,
    required this.amountSats,
    required this.incoming,
    required this.pending,
    required this.createdAt,
    required this.mintUrl,
    this.detail = '',
    this.callId,
    this.manageRoute,
  });
  final String id;
  final WalletActivityKind kind;
  final String title;
  final String status;
  final int amountSats;
  final bool incoming;
  final bool pending;
  final DateTime createdAt;
  final CashuMintUrl mintUrl;
  final String detail;
  final String? callId;
  final String? manageRoute;
}

typedef WalletActivityLoader =
    Future<List<WalletActivityEntry>> Function(CashuAccountId owner);

final class WalletActivityService {
  static Future<List<WalletActivityEntry>> load(CashuAccountId owner) async {
    final isar = DBISAR.sharedInstance.isar;
    final sends = await IsarCashuTokenSendRepository(isar).list(owner);
    final receives = await IsarCashuTokenReceiveRepository(isar).list(owner);
    final lightningReceives = await IsarCashuLightningReceiveQuoteRepository(
      isar,
    ).list(owner);
    final lightningPays = await IsarCashuLightningPayQuoteRepository(
      isar,
    ).list(owner);
    final sessions = await IsarCallPaymentSessionRepository(isar).list(owner);
    final calls = <CallPaymentDetailsData>[];
    final installments = IsarCallPaymentInstallmentRepository(isar);
    for (final session in sessions) {
      calls.add(
        CallPaymentDetailsData(
          session: session,
          installments: await installments.listForCall(
            owner: owner,
            callId: session.callId,
          ),
        ),
      );
    }
    return merge(
      owner: owner,
      sends: sends,
      receives: receives,
      lightningReceives: lightningReceives,
      lightningPays: lightningPays,
      calls: calls,
    );
  }

  static List<WalletActivityEntry> merge({
    required CashuAccountId owner,
    List<CashuTokenSendRecord> sends = const [],
    List<CashuTokenReceiveRecord> receives = const [],
    List<CashuLightningReceiveQuoteRecord> lightningReceives = const [],
    List<CashuLightningPayQuoteRecord> lightningPays = const [],
    List<CallPaymentDetailsData> calls = const [],
  }) {
    final ownCalls = calls.where((data) => data.session.owner == owner);
    final callOperations = ownCalls
        .expand((data) => data.installments)
        .map((item) => item.walletOperationId)
        .whereType<String>()
        .toSet();
    final entries = <WalletActivityEntry>[
      for (final record in sends.where(
        (r) => r.owner == owner && !callOperations.contains(r.operationId),
      ))
        WalletActivityEntry(
          id: record.operationId,
          kind: WalletActivityKind.token,
          title: 'Token sent',
          status: switch (record.state) {
            CashuSendState.prepared => 'Prepared',
            CashuSendState.recoverable => 'Unclaimed',
            CashuSendState.claimed => 'Claimed',
            CashuSendState.reclaimed => 'Reclaimed',
            CashuSendState.unknown => 'Status unknown',
          },
          amountSats: record.amount.value,
          incoming: false,
          pending:
              record.state != CashuSendState.claimed &&
              record.state != CashuSendState.reclaimed,
          createdAt: record.createdAt,
          mintUrl: record.mintUrl,
          manageRoute: '/wallet/send-token',
        ),
      for (final record in receives.where(
        (r) => r.owner == owner && !callOperations.contains(r.operationId),
      ))
        WalletActivityEntry(
          id: record.receiptId,
          kind: WalletActivityKind.token,
          title: 'Token received',
          status: record.state == CashuReceiveState.received
              ? 'Received'
              : 'Receipt unconfirmed',
          amountSats: record.amount.value,
          incoming: true,
          pending: record.state != CashuReceiveState.received,
          createdAt: record.createdAt,
          mintUrl: record.mintUrl,
          detail: record.state == CashuReceiveState.pending
              ? 'The local receipt is incomplete. Check your balance before retrying.'
              : '',
        ),
      for (final record in lightningReceives.where((r) => r.owner == owner))
        WalletActivityEntry(
          id: record.quoteId,
          kind: WalletActivityKind.lightning,
          title: 'Lightning received',
          status: record.state == CashuQuoteState.paid
              ? 'Invoice paid; issuance pending'
              : _quoteLabel(record.state),
          amountSats: record.amount.value,
          incoming: true,
          pending:
              _pendingQuote(record.state) ||
              record.state == CashuQuoteState.paid,
          createdAt: record.createdAt,
          mintUrl: record.mintUrl,
          manageRoute: '/wallet/receive-lightning',
        ),
      for (final record in lightningPays.where((r) => r.owner == owner))
        WalletActivityEntry(
          id: record.quoteId,
          kind: WalletActivityKind.lightning,
          title: 'Lightning payment',
          status: _quoteLabel(record.state),
          amountSats: record.amountSpent?.value ?? record.amount.value,
          incoming: false,
          pending: _pendingQuote(record.state),
          createdAt: record.createdAt,
          mintUrl: record.mintUrl,
          detail: record.feePaid == null
              ? 'Fee reserve: ${record.feeReserve.value} sat'
              : 'Fee paid: ${record.feePaid!.value} sat (included)',
          manageRoute: '/wallet/pay-lightning',
        ),
      for (final data in ownCalls) _callEntry(data),
    ];
    entries.sort((a, b) {
      final time = b.createdAt.compareTo(a.createdAt);
      return time == 0
          ? '${a.kind.name}:${a.id}'.compareTo('${b.kind.name}:${b.id}')
          : time;
    });
    return List.unmodifiable(entries);
  }

  static WalletActivityEntry _callEntry(CallPaymentDetailsData data) {
    final session = data.session;
    final summary = data.summary;
    return WalletActivityEntry(
      id: session.callId,
      kind: WalletActivityKind.call,
      title: session.role == CallPaymentRole.payer
          ? 'Paid call'
          : 'Call earnings',
      status: callPaymentStatusLabel(session.status),
      amountSats: summary.netSats,
      incoming: session.role == CallPaymentRole.payee,
      pending:
          session.endedAt == null ||
          session.status == CallPaymentSessionStatus.refundPending ||
          session.status == CallPaymentSessionStatus.reclaimPending ||
          session.status == CallPaymentSessionStatus.disputed,
      createdAt: session.createdAt,
      mintUrl: session.mintUrl,
      callId: session.callId,
      detail:
          '${summary.chargedSats} sat charged, ${summary.refundedSats} sat refunded or returned'
          '${summary.reservedSats > 0 ? ', ${summary.reservedSats} sat reserved' : ''}',
    );
  }

  static bool _pendingQuote(CashuQuoteState state) => switch (state) {
    CashuQuoteState.unpaid ||
    CashuQuoteState.pending ||
    CashuQuoteState.unknown => true,
    _ => false,
  };
  static String _quoteLabel(CashuQuoteState state) => switch (state) {
    CashuQuoteState.unpaid => 'Unpaid',
    CashuQuoteState.pending => 'Pending',
    CashuQuoteState.paid => 'Paid',
    CashuQuoteState.issued => 'Issued',
    CashuQuoteState.expired => 'Expired',
    CashuQuoteState.failed => 'Failed',
    CashuQuoteState.unknown => 'Status unknown',
  };
}
