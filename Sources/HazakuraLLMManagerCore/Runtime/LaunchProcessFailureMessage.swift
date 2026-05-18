import Foundation

public enum LaunchProcessFailureMessage {
    public static func describe(
        _ error: Error,
        command: LaunchCommand,
        runtimeExecutableName: String,
        fallbackRecoveryHint: String
    ) -> String {
        let nsError = error as NSError
        let systemError = "System error: \(error.localizedDescription)"

        if nsError.domain == NSPOSIXErrorDomain {
            switch POSIXErrorCode(rawValue: Int32(nsError.code)) {
            case .ENOENT:
                return "Runtime process could not start because macOS could not find the executable at \(command.executablePath). Choose an existing \(runtimeExecutableName) and start again. \(systemError)."
            case .EACCES:
                return "Runtime process could not start because macOS refused permission for \(command.executablePath). Check that the \(runtimeExecutableName) is executable. \(systemError)."
            case .ENOEXEC:
                return "Runtime process could not start because macOS could not execute \(command.executablePath). Check that the selected path is a \(runtimeExecutableName) for this Mac. \(systemError)."
            default:
                break
            }
        }

        return "Runtime process could not start. \(fallbackRecoveryHint) \(systemError)."
    }
}
