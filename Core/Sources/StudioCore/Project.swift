import Foundation

public enum MediaKind: String, Codable, Hashable, Sendable { case image, video }
public enum CameraMotion: String, Codable, CaseIterable, Hashable, Sendable { case still = "Locked", push = "Push in", pull = "Pull out", drift = "Drift" }
public struct Media: Codable, Hashable, Sendable {
    public var filename: String
    public var kind: MediaKind
    public var duration: Double
    public init(filename: String, kind: MediaKind, duration: Double = 0) {
        self.filename = filename; self.kind = kind; self.duration = duration
    }
}
public struct Scene: Identifiable, Codable, Equatable, Sendable {
    public var id = UUID()
    public var title: String
    public var caption: String
    public var duration: Double = 3.5
    public var trimStart: Double = 0
    public var motion: CameraMotion = .push
    public var media: Media?
    public var artwork: Int = 0
    public init(title: String, caption: String, artwork: Int = 0) {
        self.title = title; self.caption = caption; self.artwork = artwork
    }
    public var effectiveDuration: Double {
        let requested = duration.isFinite ? min(30, max(0.5, duration)) : 3.5
        guard let media, media.kind == .video else { return requested }
        return min(requested, max(0, media.duration - max(0, trimStart)))
    }
}
public struct StudioProject: Codable, Equatable, Sendable {
    public var version = 1
    public var brief = "A quiet escape. Mountain roads at golden hour. A journey beyond the ordinary."
    public var scenes: [Scene] = []
    public var captionsEnabled = true
    public var dissolves = true
    public var sourceAudio = false
    public var music: String?
    public var narration: String?
    public var musicVolume = 0.22
    public var narrationVolume = 1.0
    public init() { scenes = Storyboard.make(brief: brief) }
    public var timeline: [SceneWindow] { Timeline.windows(scenes: scenes, dissolves: dissolves) }
    public var duration: Double { timeline.last?.end ?? 0 }
    public func validate(forRendering: Bool = true) throws {
        guard version == 1 else { throw ProjectError.invalid("This project version is not supported.") }
        guard !scenes.isEmpty, scenes.count <= 12 else { throw ProjectError.invalid("Use 1–12 scenes.") }
        guard Set(scenes.map(\.id)).count == scenes.count else { throw ProjectError.invalid("Duplicate scene IDs.") }
        guard !forRendering || duration <= 120 else { throw ProjectError.invalid("Keep this first cut under two minutes.") }
        for scene in scenes {
            guard scene.duration.isFinite, scene.trimStart.isFinite, scene.trimStart >= 0,
                  scene.effectiveDuration >= 0.5 else { throw ProjectError.invalid("A clip is too short or its trim is outside the source.") }
            if let media = scene.media {
                guard Self.safeFilename(media.filename), media.duration.isFinite else { throw ProjectError.invalid("Invalid media reference.") }
            }
        }
        for name in [music, narration].compactMap({ $0 }) {
            guard Self.safeFilename(name) else { throw ProjectError.invalid("Invalid audio reference.") }
        }
        guard musicVolume.isFinite, narrationVolume.isFinite,
              (0...1).contains(musicVolume), (0...1).contains(narrationVolume) else { throw ProjectError.invalid("Invalid audio level.") }
    }
    public static func safeFilename(_ name: String) -> Bool {
        !name.isEmpty && name != "." && name != ".." && !name.contains("/") && !name.contains("\\") && !name.contains(":")
    }
}
public enum ProjectError: LocalizedError {
    case invalid(String)
    public var errorDescription: String? { if case .invalid(let message) = self { return message }; return nil }
}
public struct SceneWindow: Equatable, Sendable {
    public var start: Double
    public var end: Double
    public var captionEnd: Double
}
public enum Timeline {
    public static let overlap = 0.35
    public static func transitionDuration(from first: Scene, to second: Scene) -> Double {
        // Incoming and outgoing transitions must fit even in a half-second shot.
        min(overlap, first.effectiveDuration / 2, second.effectiveDuration / 2)
    }
    public static func windows(scenes: [Scene], dissolves: Bool) -> [SceneWindow] {
        var cursor = 0.0
        return scenes.enumerated().map { index, scene in
            let end = cursor + scene.effectiveDuration
            let overlap = dissolves && index < scenes.count - 1
                ? transitionDuration(from: scene, to: scenes[index + 1]) : 0
            let result = SceneWindow(start: cursor, end: end, captionEnd: end - overlap)
            cursor = end - overlap
            return result
        }
    }
}
public enum Storyboard {
    public static let shots = ["The opening", "The journey", "A wider world", "In motion", "The detail", "The arrival"]
    public static func make(brief: String) -> [Scene] {
        let parts = brief.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return shots.enumerated().map { index, shot in
            Scene(title: shot, caption: String((parts.isEmpty ? shot : parts[index % parts.count]).prefix(80)), artwork: index)
        }
    }
    public static func captions(from response: String) -> [String]? {
        let lines = response.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        guard lines.count == 6, lines.allSatisfy({ $0.count <= 80 }) else { return nil }
        return lines
    }
}
