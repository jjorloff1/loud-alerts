import AppKit
import AVFoundation

struct SoundPlayer {
    private static var player: AVAudioPlayer?

    static func playAlertSound() {
        // Use system alert sound
        NSSound.beep()

        // Also play a more noticeable sound if available
        if let sound = NSSound(named: "Purr") {
            sound.play()
        }
    }
}
