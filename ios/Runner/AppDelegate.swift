import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let securityChannelName = "com.dramapop.app/security"
  private var recordingShieldView: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Secure window against screenshots & screen recording
    self.window?.makeSecure()

    // Listen for Screen Recording / Capture changes
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptureChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )

    // Setup MethodChannel
    if let controller = window?.rootViewController as? FlutterViewController {
      let securityChannel = FlutterMethodChannel(name: securityChannelName, binaryMessenger: controller.binaryMessenger)
      securityChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "enableSecureScreen":
          self?.window?.makeSecure()
          result(true)
        case "disableSecureScreen":
          result(true)
        case "isScreenCaptured":
          result(UIScreen.main.isCaptured)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    // Check initial recording state
    screenCaptureChanged()

    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  @objc private func screenCaptureChanged() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self, let window = self.window else { return }

      if UIScreen.main.isCaptured {
        // Screen recording / mirroring is active: show black shield view
        if self.recordingShieldView == nil {
          let shield = UIView(frame: window.bounds)
          shield.backgroundColor = .black
          shield.autoresizingMask = [.flexibleWidth, .flexibleHeight]

          let label = UILabel()
          label.text = "Screen recording is disabled for privacy & copyright protection."
          label.textColor = .white
          label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
          label.numberOfLines = 0
          label.textAlignment = .center
          label.translatesAutoresizingMaskIntoConstraints = false

          shield.addSubview(label)
          NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: shield.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: shield.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: shield.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: shield.trailingAnchor, constant: -24),
          ])

          window.addSubview(shield)
          self.recordingShieldView = shield
        }
      } else {
        // Screen recording stopped: remove shield view
        self.recordingShieldView?.removeFromSuperview()
        self.recordingShieldView = nil
      }
    }
  }
}

extension UIWindow {
  func makeSecure() {
    let field = UITextField()
    field.isSecureTextEntry = true
    self.addSubview(field)
    field.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    field.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    self.layer.superlayer?.addSublayer(field.layer)
    field.layer.sublayers?.first?.addSublayer(self.layer)
  }
}
