import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:noscall/core/common/thread/thread_pool_manager.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/core/navigation/go_router_app_navigator.dart';
import 'package:noscall/utils/http_client.dart';
import 'package:noscall/utils/router.dart';
import 'package:noscall/utils/loading.dart';
import 'package:noscall/auth/auth_service.dart';
import 'package:noscall/call/call_kit_manager.dart';
import 'package:noscall/call/local_notification_service.dart';
import 'package:noscall/call/nostr_relay_push_service.dart';
import 'package:noscall/contacts/services/favorite_contacts_service.dart';
import 'package:noscall/contacts/services/contact_remark_service.dart';
import 'package:noscall/core/ui/status_bar_style.dart';
import 'package:noscall/setting/services/theme_service.dart';
import 'package:noscall/setting/services/notification_settings_service.dart';
import 'package:noscall/setting/services/accessibility_service.dart';

const MethodChannel navigatorChannel = MethodChannel('NativeNavigator');

/// Runs in a separate isolate when an FCM data message arrives while the app
/// is in the background or terminated (Android only).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (_isCallOfferPayload(message.data)) {
    await LocalNotificationService.showIncomingCallBackground();
  }
}

/// Returns true if [data] looks like a NIP-AC call offer push payload.
bool _isCallOfferPayload(Map<String, dynamic> data) {
  try {
    final eventRaw = data['event'];
    final Map<String, dynamic> eventMap;
    if (eventRaw is Map) {
      eventMap = Map<String, dynamic>.from(eventRaw);
    } else if (eventRaw is String) {
      eventMap = jsonDecode(eventRaw) as Map<String, dynamic>;
    } else {
      return false;
    }
    if (eventMap['kind'] != 21059) return false;
    final tags = eventMap['tags'];
    if (tags is! List) return false;
    return tags.any((tag) =>
        tag is List &&
        tag.length >= 2 &&
        tag[0] == 'k' &&
        tag[1] == '25050');
  } catch (_) {
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  AppLoading.configLoading();
  HttpOverrides.global = CustomHttpOverrides();
  await _initializeServices();

  runApp(const MainApp());
}

Future<void> _initializeServices() async {
  await _initializeService(
    'ThreadPoolManager',
    ThreadPoolManager.sharedInstance.initialize,
  );
  await _initializeService('ThemeService', ThemeService().initialize);
  await _initializeService(
    'FavoriteContactsService',
    FavoriteContactsService().initialize,
  );
  await _initializeService(
    'NotificationSettingsService',
    NotificationSettingsService().initialize,
  );
  await _initializeService(
    'ContactRemarkService',
    ContactRemarkService().initialize,
  );
  await _initializeService(
    'AccessibilityService',
    AccessibilityService().initialize,
  );
  await _initializeService('AuthService', AuthService().initialize);
  await _initializeService(
    'LocalNotificationService',
    LocalNotificationService.instance.initialize,
  );
}

Future<void> _initializeService(
  String name,
  Future<void> Function() initialize,
) async {
  try {
    await initialize();
  } catch (e, stack) {
    debugPrint('Failed to initialize $name: $e\n$stack');
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  bool _runtimeServicesDisposed = false;
  bool _preferenceServicesDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _disposeRuntimeServices() {
    if (_runtimeServicesDisposed) return;
    _runtimeServicesDisposed = true;
    CallKitManager.instance.dispose();
    AuthService().dispose();
    ThreadPoolManager.sharedInstance.dispose();
  }

  void _disposePreferenceServices() {
    if (_preferenceServicesDisposed) return;
    _preferenceServicesDisposed = true;
    AccessibilityService().dispose();
    ContactRemarkService().dispose();
    NotificationSettingsService().dispose();
    FavoriteContactsService().dispose();
    ThemeService().dispose();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeRuntimeServices();
    _disposePreferenceServices();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _disposeRuntimeServices();
    } else if (state == AppLifecycleState.resumed &&
        AuthService().isAuthenticated) {
      unawaited(NostrRelayPushService().syncIfDue());
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return ValueListenableBuilder<ThemeModeOption>(
      valueListenable: themeService.themeModeNotifier,
      builder: (context, themeModeOption, _) {
        return ValueListenableBuilder<int>(
          valueListenable: themeService.seedColorValueNotifier,
          builder: (context, seedColorValue, __) {
            return ValueListenableBuilder<double?>(
              valueListenable: AccessibilityService().textScaleFactorNotifier,
              builder: (context, textScale, ___) {
                final themeMode =
                    themeService.toFlutterThemeMode(themeModeOption);
                final seedColor = Color(seedColorValue);

                return MaterialApp.router(
                  title: 'NosCall',
                  theme: ThemeData(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: seedColor,
                      brightness: Brightness.light,
                    ),
                    useMaterial3: true,
                    appBarTheme: AppBarTheme(
                      systemOverlayStyle:
                          StatusBarStyle.forBrightness(Brightness.light),
                    ),
                  ),
                  darkTheme: ThemeData(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: seedColor,
                      brightness: Brightness.dark,
                    ),
                    useMaterial3: true,
                    appBarTheme: AppBarTheme(
                      systemOverlayStyle:
                          StatusBarStyle.forBrightness(Brightness.dark),
                    ),
                  ),
                  themeMode: themeMode,
                  routerConfig: AppRouter.router,
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) {
                    Widget w = EasyLoading.init()(context, child);
                    if (textScale != null) {
                      w = MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(textScale),
                        ),
                        child: w,
                      );
                    }
                    w = AppNavigatorScope(
                      navigator: GoRouterAppNavigator(),
                      child: w,
                    );
                    return w;
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
