import Testing

@testable import FrameitKit

struct FrameitTests {
    @Test func buildsRenderCommand() {
        #expect(
            Frameit().render(screenshotsDirectory: "screens", outputDirectory: "framed").command().arguments == [
                "--path", "screens", "--output", "framed",
            ])
    }
}
