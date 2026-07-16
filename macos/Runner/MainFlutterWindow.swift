import Cocoa
import FlutterMacOS
import Security

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    self.minSize = NSSize(width: 900, height: 600)

    RegisterGeneratedPlugins(registry: flutterViewController)
    MacOSPluginRegistry.registerAll(with: flutterViewController)
    AccountSecretStore.register(with: flutterViewController)

    super.awakeFromNib()
  }
}

private enum AccountSecretStore {
  private static let service = "sh.noscall.account_secrets"

  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "sh.noscall.account_secrets",
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
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
        result(read(key: key))
      case "write":
        guard let value = args["value"] as? String else {
          result(FlutterError(
            code: "invalid_value",
            message: "Secret value is required.",
            details: nil
          ))
          return
        }
        if let error = write(key: key, value: value) {
          result(error)
        } else {
          result(nil)
        }
      case "delete":
        if let error = delete(key: key) {
          result(error)
        } else {
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func read(key: String) -> String? {
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

  private static func write(key: String, value: String) -> FlutterError? {
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

  private static func delete(key: String) -> FlutterError? {
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
