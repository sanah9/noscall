import 'package:noscall/wallet/domain/cashu_models.dart';

final class CallPaymentPolicyException implements Exception {
  const CallPaymentPolicyException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'CallPaymentPolicyException($code): $message';
}

final class NoAcceptedCallPaymentMintException
    extends CallPaymentPolicyException {
  const NoAcceptedCallPaymentMintException()
    : super(
        'no_accepted_mint',
        'Paid calls require at least one accepted Mint.',
      );
}

final class InvalidCallPaymentPriceException
    extends CallPaymentPolicyException {
  const InvalidCallPaymentPriceException()
    : super(
        'invalid_price',
        'Paid call prices must be non-negative integer sat values.',
      );
}

final class InvalidCallPaymentTimingException
    extends CallPaymentPolicyException {
  const InvalidCallPaymentTimingException()
    : super(
        'invalid_timing',
        'Paid call billing period and grace period are invalid.',
      );
}

final class UnsupportedCallPaymentMintException
    extends CallPaymentPolicyException {
  UnsupportedCallPaymentMintException(this.mintUrl)
    : super(
        'unsupported_mint',
        'The selected Mint cannot be used for paid calls.',
      );

  final CashuMintUrl mintUrl;
}
