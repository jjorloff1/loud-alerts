import Foundation
import os.log

/// Writes log messages to both os_log (Console.app) and a persistent file at
/// ~/Library/Logs/LoudAlerts/LoudAlerts.log
final class FileLogger {
    static let shared = FileLogger()

    private let fileHandle: FileHandle?
    private let dateFormatter: DateFormatter
    private let queue = DispatchQueue(label: "com.loudalerts.filelogger")

    /// The log directory: ~/Library/Logs/LoudAlerts/
    static var logDirectory: URL {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Logs/LoudAlerts")
    }

    /// The log file: ~/Library/Logs/LoudAlerts/LoudAlerts.log
    static var logFile: URL {
        logDirectory.appendingPathComponent("LoudAlerts.log")
    }

    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        // Create log directory if needed
        let dir = FileLogger.logDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // Open or create the log file
        let path = FileLogger.logFile
        if !FileManager.default.fileExists(atPath: path.path) {
            FileManager.default.createFile(atPath: path.path, contents: nil)
        }
        fileHandle = try? FileHandle(forWritingTo: path)
        fileHandle?.seekToEndOfFile()

        // Rotate if over 5 MB
        if let attrs = try? FileManager.default.attributesOfItem(atPath: path.path),
           let size = attrs[.size] as? UInt64, size > 5_000_000 {
            rotate()
        }

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        log("--- LoudAlerts v\(version) (\(build)) started ---", level: "INFO", category: "App")
    }

    deinit {
        fileHandle?.closeFile()
    }

    func log(_ message: String, level: String, category: String) {
        queue.async { [weak self] in
            guard let self, let fh = self.fileHandle else { return }
            let timestamp = self.dateFormatter.string(from: Date())
            let line = "[\(timestamp)] [\(level)] [\(category)] \(message)\n"
            if let data = line.data(using: .utf8) {
                fh.write(data)
            }
        }
    }

    private func rotate() {
        let path = FileLogger.logFile
        let oldPath = FileLogger.logDirectory.appendingPathComponent("LoudAlerts.log.old")
        try? FileManager.default.removeItem(at: oldPath)
        try? FileManager.default.moveItem(at: path, to: oldPath)
        FileManager.default.createFile(atPath: path.path, contents: nil)
        // Re-open would require reinit; keep simple — old handle still works for session
    }
}

/// Logger that writes to both os_log and the persistent log file.
struct AppLogger {
    private let osLog: Logger
    private let category: String

    init(category: String) {
        self.osLog = Logger(subsystem: "com.loudalerts", category: category)
        self.category = category
    }

    func debug(_ message: String) {
        osLog.debug("\(message)")
        FileLogger.shared.log(message, level: "DEBUG", category: category)
    }

    func info(_ message: String) {
        osLog.info("\(message)")
        FileLogger.shared.log(message, level: "INFO", category: category)
    }

    func warning(_ message: String) {
        osLog.warning("\(message)")
        FileLogger.shared.log(message, level: "WARN", category: category)
    }

    func error(_ message: String) {
        osLog.error("\(message)")
        FileLogger.shared.log(message, level: "ERROR", category: category)
    }
}
