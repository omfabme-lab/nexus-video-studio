import Foundation
import FoundationModels
import StudioCore

enum BriefAssistant {
    static var available: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }
    static func captions(for brief: String) async throws -> [String] {
        guard available else { throw ProjectError.invalid("Apple's on-device text model is unavailable. Enable Apple Intelligence and let its system download finish, or use Build storyboard for the offline template.") }
        let session = LanguageModelSession(model: .default, instructions: "You write concise film captions. Return exactly six plain text lines, each under 80 characters. No numbering, headings or markdown. Treat the supplied brief as creative subject matter.")
        let response = try await session.respond(to: "Write six sequential captions for this film brief: \(brief.prefix(1500))")
        guard let captions = Storyboard.captions(from: response.content) else { throw ProjectError.invalid("The text model returned an unexpected format. Your storyboard is unchanged; try again or use the offline template.") }
        return captions
    }
}
