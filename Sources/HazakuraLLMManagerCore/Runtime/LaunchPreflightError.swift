import Foundation

public enum LaunchPreflightError: Error, Equatable, LocalizedError {
    case runtimeFileMissing(String)
    case runtimePathIsDirectory(String)
    case runtimeNotExecutable(String)
    case modelFileMissing(String)
    case modelPathIsDirectory(String)
    case portUnavailable(Int)

    public var errorDescription: String? {
        switch self {
        case .runtimeFileMissing(let path):
            "Runtime executable does not exist. Choose an existing llama-server binary before starting. Current path: \(path)."
        case .runtimePathIsDirectory(let path):
            "Runtime executable path is a directory. Choose the llama-server binary file before starting. Current path: \(path)."
        case .runtimeNotExecutable(let path):
            "Runtime executable is not executable. Choose the llama-server binary file and check file permissions. Current path: \(path)."
        case .modelFileMissing(let path):
            "Model file does not exist. Choose an existing .gguf model before starting. Current path: \(path)."
        case .modelPathIsDirectory(let path):
            "Model path is a directory. Choose an existing .gguf model file before starting. Current path: \(path)."
        case .portUnavailable(let port):
            "Port \(port) is already in use. Choose a different port before starting."
        }
    }
}
