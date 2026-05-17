import Foundation

public enum LaunchProcessFailureMessage {
    public static func describe(_ error: Error, command: LaunchCommand) -> String {
        let nsError = error as NSError
        let systemError = "System error: \(error.localizedDescription)"

        if nsError.domain == NSPOSIXErrorDomain {
            switch POSIXErrorCode(rawValue: Int32(nsError.code)) {
            case .ENOENT:
                return "Runtime process could not start because macOS could not find the executable at \(command.executablePath). Choose an existing llama-server binary and start again. \(systemError)."
            case .EACCES:
                return "Runtime process could not start because macOS refused permission for \(command.executablePath). Check that the llama-server binary is executable. \(systemError)."
            case .ENOEXEC:
                return "Runtime process could not start because macOS could not execute \(command.executablePath). Check that the selected path is a llama-server binary for this Mac. \(systemError)."
            default:
                break
            }
        }

        return "Runtime process could not start. Check the selected llama-server binary, model, and launch options, then try again. \(systemError)."
    }
}
