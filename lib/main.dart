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
import 'contacts/services/favorite_contacts_service.dart';
import 'setting/services/theme_service.dart';
import 'setting/services/notification_settings_service.dart';

const MethodChannel navigatorChannel = MethodChannel('NativeNavigator');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLoading.configLoading();
  HttpOverrides.global = CustomHttpOverrides();
  try {
    await ThreadPoolManager.sharedInstance.initialize();
    await AuthService().initialize();
    await ThemeService().initialize();
    await FavoriteContactsService().initialize();
    await NotificationSettingsService().initialize();
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
    ThemeService().dispose();
    FavoriteContactsService().dispose();
    NotificationSettingsService().dispose();
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
    final themeService = ThemeService();
    const seedColor = Color(0xFF3937A3);

    return ValueListenableBuilder<ThemeModeOption>(
      valueListenable: themeService.themeModeNotifier,
      builder: (context, themeModeOption, _) {
        final themeMode = themeService.toFlutterThemeMode(themeModeOption);

        return MaterialApp.router(
          title: 'NosCall',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeMode,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
          builder: EasyLoading.init(),
        );
      },
    );
  }
}