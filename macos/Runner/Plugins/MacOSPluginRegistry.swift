import FlutterMacOS

class MacOSPluginRegistry {
    static func registerAll(with controller: FlutterViewController) {
        MacOSPermissionsPlugin.register(with: controller.registrar(forPlugin: "MacOSPermissionsPlugin"))
    }
}
