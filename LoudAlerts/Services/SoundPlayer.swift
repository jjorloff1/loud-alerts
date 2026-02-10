import AppKit

struct SoundPlayer {
    static func playAlertSound() {
        NSSound.beep()

        if let sound = NSSound(named: "Purr") {
            sound.play()
        }
    }
}
