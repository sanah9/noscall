import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/core/common/network/connect_timeout_checker.dart';
import 'package:noscall/core/common/network/connect_types.dart';

const _relay = 'wss://relay.example.com';
const _subscriptionId =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

Requests request({
  required int requestTime,
  bool closeSubscription = true,
  EOSECallBack? eoseCallBack,
}) {
  return Requests(
    'request-id',
    [_relay],
    requestTime,
    {_relay: _subscriptionId},
    null,
    eoseCallBack,
    '["REQ","$_subscriptionId"]',
    closeSubscription,
  );
}

void main() {
  group('ConnectTimeoutChecker', () {
    test('emits OK timeout for every pending relay', () {
      final checker = ConnectTimeoutChecker(timeoutSeconds: 10);
      final okTimeouts = <Map<String, String>>[];

      checker.check(
        now: DateTime.fromMillisecondsSinceEpoch(20 * 1000),
        sendsMap: {
          'event-id': Sends(
            'send-id',
            ['relay-a', 'relay-b'],
            9 * 1000,
            'event-id',
            null,
            '{}',
          ),
        },
        requestsMap: {},
        onOkTimeout: (ok, relay) {
          okTimeouts.add({
            'eventId': ok.eventId,
            'status': ok.status.toString(),
            'message': ok.message,
            'relay': relay,
          });
        },
        onRequestTimeout: (_, __) {},
      );

      expect(okTimeouts, [
        {
          'eventId': 'event-id',
          'status': 'false',
          'message': 'Time Out',
          'relay': 'relay-a',
        },
        {
          'eventId': 'event-id',
          'status': 'false',
          'message': 'Time Out',
          'relay': 'relay-b',
        },
      ]);
    });

    test('emits request timeout when request waits past threshold', () {
      final checker = ConnectTimeoutChecker(timeoutSeconds: 10);
      final requestTimeouts = <Map<String, String>>[];

      checker.check(
        now: DateTime.fromMillisecondsSinceEpoch(20 * 1000),
        sendsMap: {},
        requestsMap: {
          '$_subscriptionId$_relay': request(requestTime: 9 * 1000),
        },
        onOkTimeout: (_, __) {},
        onRequestTimeout: (eose, relay) {
          requestTimeouts.add({
            'eose': eose,
            'relay': relay,
          });
        },
      );

      expect(requestTimeouts, [
        {
          'eose': '["request-id"]',
          'relay': _relay,
        },
      ]);
    });

    test('skips long-lived request without EOSE callback', () {
      final checker = ConnectTimeoutChecker(timeoutSeconds: 10);
      var timeoutCount = 0;

      checker.check(
        now: DateTime.fromMillisecondsSinceEpoch(20 * 1000),
        sendsMap: {},
        requestsMap: {
          '$_subscriptionId$_relay': request(
            requestTime: 9 * 1000,
            closeSubscription: false,
          ),
        },
        onOkTimeout: (_, __) {},
        onRequestTimeout: (_, __) => timeoutCount += 1,
      );

      expect(timeoutCount, 0);
    });
  });
}
