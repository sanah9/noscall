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
        
        voipPushChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            // Handle any method calls from Flutter if needed in the future
            result(FlutterMethodNotImplemented)
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
        // Convert push token to hex string
        let tokenParts = pushCredentials.token.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        print("VoIP Push Token: \(token)")
        
        // Send token to Flutter layer
        voipPushChannel?.invokeMethod("onVoIPTokenUpdated", arguments: token)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("Received VoIP push notification")
        
        // Extract payload data
        let payloadData = payload.dictionaryPayload
        
        // Send push notification data to Flutter layer
        voipPushChannel?.invokeMethod("onVoIPPushReceived", arguments: payloadData) { (result: Any?) in
            if let error = result as? FlutterError {
                print("Error sending VoIP push to Flutter: \(error)")
            }
        }
        
        // Call completion handler
        completion()
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("VoIP push token invalidated")
        // Notify Flutter layer
        voipPushChannel?.invokeMethod("onVoIPTokenInvalidated", arguments: nil)
    }
}
