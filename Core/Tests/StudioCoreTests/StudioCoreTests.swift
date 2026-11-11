import XCTest
@testable import StudioCore

final class StudioCoreTests: XCTestCase {
    func testOverlapsAndCaptionBoundaries() {
        let project = StudioProject()
        XCTAssertEqual(project.duration, 19.25, accuracy: 0.00001)
        for pair in zip(project.timeline, project.timeline.dropFirst()) {
            XCTAssertEqual(pair.0.captionEnd, pair.1.start, accuracy: 0.00001)
            XCTAssertEqual(pair.0.end - pair.1.start, 0.35, accuracy: 0.00001)
        }
    }
    func testHardCutsAndSingleScene() {
        var project = StudioProject(); project.dissolves = false
        XCTAssertEqual(project.duration, 21)
        project.scenes = [project.scenes[0]]; project.dissolves = true
        XCTAssertEqual(project.duration, 3.5)
    }
    func testShortScenesNeverHaveOverlappingTransitionWindows() {
        var project = StudioProject()
        for index in project.scenes.indices { project.scenes[index].duration = 0.5 }
        XCTAssertEqual(project.duration, 1.75, accuracy: 0.00001)
        for index in 1..<(project.scenes.count - 1) {
            let incoming = Timeline.transitionDuration(from: project.scenes[index - 1], to: project.scenes[index])
            let outgoing = Timeline.transitionDuration(from: project.scenes[index], to: project.scenes[index + 1])
            XCTAssertLessThanOrEqual(incoming + outgoing, project.scenes[index].effectiveDuration)
        }
    }
    func testTrimClampsToAvailableFootage() throws {
        var scene = Scene(title: "Clip", caption: "")
        scene.media = Media(filename: "clip.mov", kind: .video, duration: 2)
        scene.trimStart = 1
        XCTAssertEqual(scene.effectiveDuration, 1)
        var project = StudioProject(); project.scenes = [scene]
        try project.validate()
        project.scenes[0].trimStart = 2
        XCTAssertThrowsError(try project.validate())
    }
    func testPersistenceRoundtripAndPathTraversal() throws {
        let original = StudioProject()
        let decoded = try JSONDecoder().decode(StudioProject.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(original, decoded)
        for path in ["../private.mov", "..\\private.mov", "C:clip.mov", "/tmp/a", "..", ""] {
            XCTAssertFalse(StudioProject.safeFilename(path))
        }
        XCTAssertTrue(StudioProject.safeFilename("a-b.mov"))
    }
    func testBadDurationsAndLimits() {
        var project = StudioProject()
        project.scenes[0].duration = .nan
        XCTAssertThrowsError(try project.validate())
        project = StudioProject()
        for index in project.scenes.indices { project.scenes[index].duration = 30 }
        XCTAssertThrowsError(try project.validate())
        project.scenes = []
        XCTAssertThrowsError(try project.validate())
    }
    func testStoryboardUsesBriefAndRejectsMalformedAI() {
        XCTAssertEqual(Storyboard.make(brief: "Dawn. Open road.")[1].caption, "Open road")
        XCTAssertEqual(Storyboard.make(brief: " ").count, 6)
        XCTAssertNil(Storyboard.captions(from: "one line"))
        XCTAssertEqual(Storyboard.captions(from: "a\nb\nc\nd\ne\nf")?.count, 6)
    }
}
