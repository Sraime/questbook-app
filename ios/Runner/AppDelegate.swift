import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    excludeApplicationSupportFromBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Drift stores the local SQLite database (characters and cached table
  /// payloads) under Application Support, which iCloud backs up by default.
  /// Those files stay on this device.
  private func excludeApplicationSupportFromBackup() {
    guard let support = FileManager.default.urls(
      for: .applicationSupportDirectory, in: .userDomainMask
    ).first else { return }

    try? FileManager.default.createDirectory(
      at: support, withIntermediateDirectories: true
    )

    var url = support
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? url.setResourceValues(values)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
