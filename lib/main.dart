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
import 'call/call_manager.dart';

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

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Cleanup resources on app shutdown
    ThreadPoolManager.sharedInstance.dispose();
    AuthService().dispose();
    CallKitManager().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // App is being terminated, cleanup resources
      ThreadPoolManager.sharedInstance.dispose();
      AuthService().dispose();
      CallKitManager().dispose();
    }
  }

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