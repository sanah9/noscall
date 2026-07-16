import UIKit
import Flutter
import PushKit
import UserNotifications
import callkeep
import Security

@main
@objc class AppDelegate: FlutterAppDelegate {
    var voipRegistry: PKPushRegistry?
    var voipPushChannel: FlutterMethodChannel?
    var standardPushChannel: FlutterMethodChannel?
    var standardAPNsToken: String?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let controller = FlutterViewController()

        GeneratedPluginRegistrant.register(with: controller)
        registerCustomPlugins(with: controller)

        // Register standard APNs push notifications so the device token is
        // available in the Xcode console for direct APNs testing.
        setupStandardPushNotification(application: application, controller: controller)

        // Setup VoIP push notification
        setupVoIPPushNotification(controller: controller)

        window.rootViewController = controller
        window.makeKeyAndVisible()

        self.window = window;

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setupStandardPushNotification(application: UIApplication, controller: FlutterViewController) {
        standardPushChannel = FlutterMethodChannel(
            name: "sh.noscall.standard_push",
            binaryMessenger: controller.binaryMessenger
        )

        standardPushChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "getStandardAPNsToken":
                result(self?.standardAPNsToken)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error = error {
                print("[APNs Standard] Authorization request failed: \(error.localizedDescription)")
            }
            print("[APNs Standard] Authorization granted: \(granted)")

            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
                print("[APNs Standard] registerForRemoteNotifications requested")
            }
        }
    }

    private func setupVoIPPushNotification(controller: FlutterViewController) {
        // Initialize VoIP push registry
        voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry?.delegate = self
        voipRegistry?.desiredPushTypes = [.voIP]

        // Setup method channel for VoIP push communication
        voipPushChannel = FlutterMethodChannel(
            name: "sh.noscall.voip_push",
            binaryMessenger: controller.binaryMessenger
        )

        voipPushChannel?.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "endVoIPPlaceholderCall", let uuid = call.arguments as? String {
                // Flutter determined the push was invalid/stale — dismiss the
                // placeholder call that was reported to satisfy Apple's requirement.
                CallKeep.endCall(withUUID: uuid, reason: 1) // 1 = unanswered
            }
            result(nil)
        }
    }

    private func registerCustomPlugins(with controller: FlutterViewController) {
        // Register NativeMethodHandler
        if let registrar = controller.registrar(forPlugin: "NativeMethodHandler") {
            NativeMethodHandler.register(with: registrar)
        } else {
            print("Failed to get registrar for NativeMethodHandler")
        }

        // Register WebRTCPiPPlugin
        if #available(iOS 15.0, *) {
            if let registrar = controller.registrar(forPlugin: "WebRTCPiPPlugin") {
                    WebRTCPiPPlugin.register(with: registrar)
            } else {
                print("Failed to get registrar for WebRTCPiPPlugin")
            }
        }

        setupAccountSecretStore(controller: controller)
    }

    private func setupAccountSecretStore(controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "sh.noscall.account_secrets",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let args = call.arguments as? [String: Any],
                  let key = args["key"] as? String,
                  !key.isEmpty else {
                result(FlutterError(
                    code: "invalid_key",
                    message: "Secret key is required.",
                    details: nil
                ))
                return
            }

            switch call.method {
            case "read":
                result(AccountKeychainStore.read(key: key))
            case "write":
                guard let value = args["value"] as? String else {
                    result(FlutterError(
                        code: "invalid_value",
                        message: "Secret value is required.",
                        details: nil
                    ))
                    return
                }
                let error = AccountKeychainStore.write(key: key, value: value)
                if let error = error {
                    result(error)
                } else {
                    result(nil)
                }
            case "delete":
                let error = AccountKeychainStore.delete(key: key)
                if let error = error {
                    result(error)
                } else {
                    result(nil)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        signal(SIGPIPE, SIG_IGN)
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        signal(SIGPIPE, SIG_IGN)
    }

    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = hexString(from: deviceToken)
        standardAPNsToken = token
        print("[APNs Standard] Device Token: \(token)")
        standardPushChannel?.invokeMethod("onStandardAPNsTokenUpdated", arguments: token)
        super.application(
            application,
            didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
        )
    }

    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[APNs Standard] Registration failed: \(error.localizedDescription)")
        super.application(
            application,
            didFailToRegisterForRemoteNotificationsWithError: error
        )
    }

    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("[APNs Standard] Received remote notification: \(userInfo)")
        completionHandler(.newData)
    }

    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("[APNs Standard] Will present notification: \(notification.request.content.userInfo)")
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }

    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("[APNs Standard] Notification response: \(response.notification.request.content.userInfo)")
        completionHandler()
    }

    private func hexString(from data: Data) -> String {
        data.map { String(format: "%02.2hhx", $0) }.joined()
    }
}

private enum AccountKeychainStore {
    private static let service = "sh.noscall.account_secrets"

    static func read(key: String) -> String? {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }

        guard let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    static func write(key: String, value: String) -> FlutterError? {
        guard let data = value.data(using: .utf8) else {
            return FlutterError(
                code: "invalid_value",
                message: "Secret value is not valid UTF-8.",
                details: nil
            )
        }

        let query = baseQuery(key: key)
        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if updateStatus == errSecSuccess {
            return nil
        }
        if updateStatus != errSecItemNotFound {
            return error(status: updateStatus)
        }

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] =
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(attributes as CFDictionary, nil)
        return addStatus == errSecSuccess ? nil : error(status: addStatus)
    }

    static func delete(key: String) -> FlutterError? {
        let status = SecItemDelete(baseQuery(key: key) as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            return nil
        }
        return error(status: status)
    }

    private static func baseQuery(key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }

    private static func error(status: OSStatus) -> FlutterError {
        FlutterError(
            code: "account_secret_store",
            message: "Keychain operation failed with status \(status).",
            details: nil
        )
    }
}

// MARK: - PKPushRegistryDelegate
extension AppDelegate: PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let token = hexString(from: pushCredentials.token)
        print("[APNs VoIP] Device Token: \(token)")
        voipPushChannel?.invokeMethod("onVoIPTokenUpdated", arguments: token)
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("[APNs VoIP] Received push payload: \(payload.dictionaryPayload)")
        let callUUID = UUID().uuidString
        let payloadData = payload.dictionaryPayload

        // iOS 13+ requires reportNewIncomingCall before calling completion().
        // Failure to do so causes the system to stop delivering VoIP pushes.
        // CallKeep's shared CXProvider handles the report; completion() is called
        // inside its own completion handler, guaranteeing correct ordering.
        CallKeep.reportNewIncomingCall(
            callUUID,
            handle: "Incoming Call",
            handleType: "generic",
            hasVideo: false,
            callerName: nil,
            fromPushKit: true,
            payload: payloadData
        ) {
            completion()
        }

        // Tell Flutter the payload AND the UUID so it can end the placeholder
        // call once it knows whether the event is valid.
        var args = payloadData as [AnyHashable: Any]
        args["_callUUID"] = callUUID
        voipPushChannel?.invokeMethod("onVoIPPushReceived", arguments: args) { (result: Any?) in
            if let error = result as? FlutterError {
                print("Error forwarding VoIP push to Flutter: \(error)")
            }
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("[APNs VoIP] Token invalidated")
        voipPushChannel?.invokeMethod("onVoIPTokenInvalidated", arguments: nil)
    }
}
