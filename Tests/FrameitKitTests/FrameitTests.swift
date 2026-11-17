import Testing

@testable import FrameitKit

struct FrameitTests {
    @Test func buildsRenderCommand() {
        #expect(
            Frameit().render(screenshotsDirectory: "screens", outputDirectory: "framed").command().arguments == [
                "--path", "screens", "--output", "framed",
            ])
    }

    @Test func honoursExecutablePath() {
        let command = Frameit(executablePath: "/opt/frameit").render(screenshotsDirectory: "a", outputDirectory: "b").command()
        #expect(command.executableName == "/opt/frameit")
    }

    @Test func selectingAnOperationReplacesThePreviousOne() {
        let frameit = Frameit().render(screenshotsDirectory: "a", outputDirectory: "b")
        #expect(frameit.render(screenshotsDirectory: "c", outputDirectory: "d").command().arguments == ["--path", "c", "--output", "d"])
    }
}
