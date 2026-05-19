import Foundation

public enum ProcessTerminationRequest: Sendable {
    case stop
    case restart
}

public enum ProcessTerminationMessage {
    public static func describe(
        status: Int32,
        reason: Process.TerminationReason,
        requestedAction: ProcessTerminationRequest? = nil
    ) -> String {
        if let requestedAction {
            return describeRequestedTermination(status: status, reason: reason, requestedAction: requestedAction)
        }

        switch reason {
        case .exit:
            return "Process exited with code \(status)."
        case .uncaughtSignal:
            return "Process terminated by signal \(status)."
        @unknown default:
            return "Process ended with status \(status)."
        }
    }

    private static func describeRequestedTermination(
        status: Int32,
        reason: Process.TerminationReason,
        requestedAction: ProcessTerminationRequest
    ) -> String {
        switch requestedAction {
        case .stop:
            return "Stop request completed with \(terminationOutcome(status: status, reason: reason))."
        case .restart:
            return "Restart request stopped the current process with \(terminationOutcome(status: status, reason: reason))."
        }
    }

    private static func terminationOutcome(status: Int32, reason: Process.TerminationReason) -> String {
        switch reason {
        case .exit:
            return "exit code \(status)"
        case .uncaughtSignal:
            return "signal \(status)"
        @unknown default:
            return "status \(status)"
        }
    }
}
