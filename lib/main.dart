import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:noscall/core/common/utils/log_utils.dart';
import 'core/common/thread/threadPoolManager.dart';
import 'utils/http_client.dart';
import 'utils/router.dart';
import 'utils/loading.dart';

import 'auth/auth_service.dart';

const MethodChannel navigatorChannel = MethodChannel('NativeNavigator');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLoading.configLoading();
  HttpOverrides.global = CustomHttpOverrides();
  try {
    await ThreadPoolManager.sharedInstance.initialize();
    await AuthService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize services: $e');
  }
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NosCall',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0x3937a3)),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
    );
  }
}