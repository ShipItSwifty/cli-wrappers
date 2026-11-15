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

    @Test(
        "Each combination of options renders in a fixed order",
        arguments: [
            (false, nil as String?, ["8100:8100", "-u", "U"]),
            (true, nil, ["8100:8100", "-u", "U", "-n"]),
            (false, "0.0.0.0", ["8100:8100", "-u", "U", "-s", "0.0.0.0"]),
            (true, "0.0.0.0", ["8100:8100", "-u", "U", "-n", "-s", "0.0.0.0"]),
        ]
    )
    func forwardMatrix(network: Bool, address: String?, expected: [String]) {
        let command = IProxy().forward(localPort: 8100, devicePort: 8100, udid: "U", network: network, listenAddress: address).command()
        #expect(command.arguments == expected)
    }

    @Test("Version replaces a forward")
    func versionReplacesForward() {
        #expect(IProxy().forward(localPort: 1, devicePort: 2, udid: "U").version().command().arguments == ["--version"])
    }
}
