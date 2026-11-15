import Foundation
import IOKit.ps

extension Notification.Name {
    static let powerSourceDidChange = Notification.Name("SbuSeasonsPowerSourceDidChange")
}

/// Il Mac va a batteria? Su un Mac fisso (nessuna batteria) è sempre false.
func isOnBattery() -> Bool {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let type = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() else { return false }
    return (type as String) == kIOPMBatteryPowerKey
}

/// Avvisa con `.powerSourceDidChange` quando il Mac passa da batteria a corrente o viceversa.
/// Il sorgente va tenuto vivo finché serve.
func observePowerSource() -> CFRunLoopSource? {
    guard let source = IOPSNotificationCreateRunLoopSource({ _ in
        NotificationCenter.default.post(name: .powerSourceDidChange, object: nil)
    }, nil)?.takeRetainedValue() else { return nil }
    CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
    return source
}
