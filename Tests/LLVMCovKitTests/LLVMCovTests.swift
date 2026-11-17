import Testing

@testable import LLVMCovKit

struct LLVMCovTests {
    @Test(
        "Builds coverage reports and source displays",
        arguments: [
            (
                LLVMCov(executablePath: "xcrun").report(binary: "App", instrumentProfile: "coverage.profdata"),
                ["llvm-cov", "report", "-instr-profile=coverage.profdata", "App"]
            ),
            (LLVMCov(executablePath: "xcrun").report(binary: "App"), ["llvm-cov", "report", "App"]),
            (
                LLVMCov(executablePath: "xcrun").show(binary: "App", instrumentProfile: "coverage.profdata"),
                ["llvm-cov", "show", "-instr-profile=coverage.profdata", "App"]
            ),
            (LLVMCov(executablePath: "xcrun").show(binary: "App"), ["llvm-cov", "show", "App"]),
        ] as [(LLVMCov, [String])]
    )
    func operations(llvMcov: LLVMCov, expected: [String]) {
        let command = llvMcov.command()
        #expect(command.executableName == "xcrun")
        #expect(command.arguments == expected)
    }
}
