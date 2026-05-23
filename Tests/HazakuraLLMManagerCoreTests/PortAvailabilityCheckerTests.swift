import Darwin
import XCTest
@testable import HazakuraLLMManagerCore

final class PortAvailabilityCheckerTests: XCTestCase {
    func testReportsOccupiedPortAsUnavailable() throws {
        let descriptor = try bindLoopbackSocketToEphemeralPort()
        defer { close(descriptor.socket) }

        XCTAssertFalse(PortAvailabilityChecker().isPortAvailable(descriptor.port))
    }

    func testRejectsInvalidPorts() {
        let checker = PortAvailabilityChecker()

        XCTAssertFalse(checker.isPortAvailable(0))
        XCTAssertFalse(checker.isPortAvailable(65_536))
    }

    func testReportsRecentlyClosedListeningPortAsAvailable() throws {
        let descriptor = try bindLoopbackSocketToEphemeralPort()
        let port = descriptor.port
        close(descriptor.socket)

        XCTAssertTrue(PortAvailabilityChecker().isPortAvailable(port))
    }

    private func bindLoopbackSocketToEphemeralPort() throws -> (socket: Int32, port: Int) {
        let descriptor = socket(AF_INET, SOCK_STREAM, 0)
        guard descriptor >= 0 else {
            throw POSIXError(.EIO)
        }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = 0
        address.sin_addr = in_addr(s_addr: INADDR_LOOPBACK.bigEndian)

        let didBind = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                Darwin.bind(descriptor, socketAddress, socklen_t(MemoryLayout<sockaddr_in>.size)) == 0
            }
        }

        guard didBind else {
            close(descriptor)
            throw POSIXError(.EADDRINUSE)
        }

        var boundAddress = sockaddr_in()
        var boundAddressLength = socklen_t(MemoryLayout<sockaddr_in>.size)
        let didReadPort = withUnsafeMutablePointer(to: &boundAddress) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                getsockname(descriptor, socketAddress, &boundAddressLength) == 0
            }
        }

        guard didReadPort else {
            close(descriptor)
            throw POSIXError(.EIO)
        }

        return (descriptor, Int(UInt16(bigEndian: boundAddress.sin_port)))
    }
}
