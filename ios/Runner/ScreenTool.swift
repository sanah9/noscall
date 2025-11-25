import UIKit

final class ScreenTool {
    
    static let shared = ScreenTool()
    
    private init() {}
    
    private var activeScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
    }
    
    var rootViewController: UIViewController? {
        if #available(iOS 15.0, *) {
            return activeScene?.keyWindow?.rootViewController
        } else {
            return activeScene?.windows.first?.rootViewController
        }
    }
    
    var bounds: CGRect {
        activeScene?.coordinateSpace.bounds ?? UIScreen.main.bounds
    }
    
    var screenBounds: CGRect {
        activeScene?.screen.bounds ?? UIScreen.main.bounds
    }

    var safeAreaInsets: UIEdgeInsets {
        guard let window = activeScene?.windows.first else { return .zero }
        return window.safeAreaInsets
    }

    var width: CGFloat { bounds.width }
    
    var height: CGFloat { bounds.height }
    
    var orientation: UIInterfaceOrientation {
        activeScene?.interfaceOrientation ?? .portrait
    }
    
    var isLandscape: Bool {
        orientation.isLandscape
    }

    var isPortrait: Bool {
        orientation.isPortrait
    }
    
    var scale: CGFloat {
        activeScene?.screen.scale ?? UIScreen.main.scale
    }
    
    var pixelSize: CGSize {
        CGSize(width: bounds.width * scale, height: bounds.height * scale)
    }
    
    var hasExternalDisplay: Bool {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .contains(where: { $0.screen != UIScreen.main })
    }
}

