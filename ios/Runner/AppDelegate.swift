import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let controller = FlutterViewController()
        
        GeneratedPluginRegistrant.register(with: controller)
        registerCustomPlugins(with: controller)
        
        window.rootViewController = controller
        window.makeKeyAndVisible()
        
        self.window = window;
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
