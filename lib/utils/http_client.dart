import 'dart:io';

import 'package:flutter_socks_proxy/socks_proxy.dart';

class CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = createProxyHttpClient(context: context)
      ..findProxy = (Uri uri) {
        return 'DIRECT';
      }
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true;
      };
    return client;
  }
}