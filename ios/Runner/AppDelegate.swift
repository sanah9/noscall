import UIKit
import Flutter
import PushKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    var voipRegistry: PKPushRegistry?
    var voipPushChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let controller = FlutterViewController()
        
        GeneratedPluginRegistrant.register(with: controller)
        registerCustomPlugins(with: controller)
        
        // Setup VoIP push notification
        setupVoIPPushNotification(controller: controller)
        
        window.rootViewController = controller
        window.makeKeyAndVisible()
        
        self.window = window;
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        signal(SIGPIPE, SIG_IGN)
    }
    
    override func applicationWillEnterForeground(_ application: UIApplication) {
        signal(SIGPIPE, SIG_IGN)
    }
}

// MARK: - PKPushRegistryDelegate
extension AppDelegate: PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let tokenParts = pushCredentials.token.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("VoIP Push Token: \(token)")
        voipPushChannel?.invokeMethod("onVoIPTokenUpdated", arguments: token)
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("Received VoIP push notification")
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
        print("VoIP push token invalidated")
        voipPushChannel?.invokeMethod("onVoIPTokenInvalidated", arguments: nil)
    }
}
