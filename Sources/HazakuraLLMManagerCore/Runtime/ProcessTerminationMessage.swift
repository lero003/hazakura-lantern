import Foundation

public enum ProcessTerminationMessage {
    public static func describe(status: Int32, reason: Process.TerminationReason) -> String {
        switch reason {
        case .exit:
            return "Process exited with code \(status)."
        case .uncaughtSignal:
            return "Process terminated by signal \(status)."
        @unknown default:
            return "Process ended with status \(status)."
        }
    }
}
