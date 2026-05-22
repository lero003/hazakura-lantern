import Darwin
import Foundation

public protocol PortAvailabilityChecking: Sendable {
    func isPortAvailable(_ port: Int) -> Bool
}

public struct PortAvailabilityChecker: PortAvailabilityChecking, Sendable {
    public init() {}

    public func isPortAvailable(_ port: Int) -> Bool {
        guard (1...65535).contains(port) else {
            return false
        }

        let descriptor = socket(AF_INET, SOCK_STREAM, 0)
        guard descriptor >= 0 else {
            return false
        }
        defer { close(descriptor) }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(port).bigEndian
        address.sin_addr = in_addr(s_addr: INADDR_ANY)

        return withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                bind(descriptor, socketAddress, socklen_t(MemoryLayout<sockaddr_in>.size)) == 0
            }
        }
    }
}
