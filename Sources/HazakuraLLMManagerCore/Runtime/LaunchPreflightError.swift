import Foundation

public enum LaunchPreflightError: Error, Equatable, LocalizedError {
    case runtimeNotExecutable(String)
    case modelFileMissing(String)

    public var errorDescription: String? {
        switch self {
        case .runtimeNotExecutable(let path):
            "Runtime executable is not executable. Choose the llama-server binary file and check file permissions. Current path: \(path)."
        case .modelFileMissing(let path):
            "Model file does not exist. Choose an existing .gguf model before starting. Current path: \(path)."
        }
    }
}
