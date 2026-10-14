import Testing

@testable import IProxyKit

@Suite("IProxy")
struct IProxyTests {
    @Test("Forward maps local to device port for one UDID")
    func forward() {
        #expect(IProxy().forward(localPort: 1, devicePort: 2, udid: "U").command().arguments == ["1:2", "-u", "U"])
        #expect(
            IProxy(executablePath: "/opt/iproxy").forward(localPort: 1, devicePort: 2, udid: "U", network: true, listenAddress: "127.0.0.1")
                .command().arguments == ["1:2", "-u", "U", "-n", "-s", "127.0.0.1"])
        #expect(IProxy(executablePath: "/opt/iproxy").version().command().executableName == "/opt/iproxy")
    }
}
