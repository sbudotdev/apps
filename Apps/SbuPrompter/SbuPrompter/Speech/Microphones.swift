import AVFoundation
import CoreAudio

/// The Mac's audio inputs, by Core Audio UID (`AVCaptureDevice.uniqueID`).
enum Microphones {
    struct Device: Identifiable, Hashable {
        let id: String
        let name: String
    }

    static var all: [Device] {
        AVCaptureDevice.DiscoverySession(deviceTypes: [.microphone, .external], mediaType: .audio, position: .unspecified)
            .devices
            .map { Device(id: $0.uniqueID, name: $0.localizedName) }
    }

    /// The input macOS uses when none is chosen.
    static var systemDefaultName: String? {
        AVCaptureDevice.default(for: .audio)?.localizedName
    }

    static func name(of uid: String) -> String? {
        AVCaptureDevice(uniqueID: uid)?.localizedName
    }

    /// Points the engine's input at the device with `uid`. False when the device is gone.
    static func select(_ uid: String, on input: AVAudioInputNode) -> Bool {
        guard let unit = input.audioUnit, var device = deviceID(for: uid) else { return false }
        return AudioUnitSetProperty(unit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0,
                                    &device, UInt32(MemoryLayout<AudioDeviceID>.size)) == noErr
    }

    private static func deviceID(for uid: String) -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyTranslateUIDToDevice,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var device = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var cfUID = uid as CFString
        let status = withUnsafeMutablePointer(to: &cfUID) { pointer in
            AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address,
                                       UInt32(MemoryLayout<CFString>.size), pointer, &size, &device)
        }
        return status == noErr && device != kAudioObjectUnknown ? device : nil
    }
}
