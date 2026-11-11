# Architecture and foundation decision

Studio is an isolated app, not an extension of the existing Nexus checkout. No existing Nexus files were inspected or used.

The smallest reliable reusable foundation from the requested candidates is **Kadr's engine alone**. A 488 KB source snapshot provides AVFoundation composition, still encoding, motion, transitions, audio mixing and export. The custom SwiftUI shell preserves the approved portrait-first visual hierarchy without pulling in a second editor's UI or its remote dependencies. The app uses no package registry at build time: both packages are local.

| Module | Responsibility |
|---|---|
| `Core/StudioCore` | Codable project, safe media references, trim math, overlap timeline, brief template and AI output validation; Foundation only |
| `App/StudioStore` | Main-actor state, atomic JSON persistence, import validation, recording lifecycle, job lifecycle |
| `App/LocalRenderer` | Maps a project snapshot to Kadr clips/audio/overlays, produces a review copy or final MP4 |
| `App/StudioRendering` | Replaceable renderer boundary; future PC implementation can use the same project value |
| `App/BriefAssistant` | Explicitly selected Apple on-device text model, availability check, bounded output, no automatic network fallback |
| `App/StudioView`, `SceneEditor` | Portrait panels, editing controls, selection, preview, share sheet |
| `Vendor/Kadr` | Unmodified engine Swift sources at an audited commit, reduced local package manifest |

The app targets iOS 27, iPhone only, portrait orientation. The CI simulator target is iPhone 18 Pro Max. App sources use Swift 5 language mode on the Swift compiler bundled with Xcode 27; Kadr and StudioCore use Swift 6. The language-mode choice avoids introducing an unrelated strict-concurrency migration into the first UI slice.

## Media and timing

Imports copy to `Documents/Studio/UUID.ext`; security-scoped access is released after copying. Images are orientation-normalized and downsampled to at most 2400 pixels on the long edge. Import size limit: 200 MB per file. Original source files are never overwritten. Project media references are basenames, not security-scoped external paths. Invalid or missing inputs surface an error.

One project contains 1–12 shots. Clip trims are clamped to available source duration; render validates a maximum two-minute timeline. Dissolves overlap adjacent scenes by up to 0.35 seconds, capped at half of each neighboring shot so transitions also fit very short clips. Caption intervals switch to the incoming shot at its start. Captions are authored per shot, not inferred from speech. Source audio is independently selectable; music and narration start at zero, each has a level, and music has short fades. Short audio tracks are not looped.

Rendering takes a value snapshot. Editing is locked during media work and recording. Review files use 540×960, final files 1080×1920, both 30fps H.264. Preview plays the actual review output, so it includes the same caption/mix/transition path as final export. The UI does not pretend to provide a zero-latency live compositing timeline. The timeline uses duration-scaled thumbnails and AVKit's playback scrubber; reorder and trim are in the shot inspector.

Kadr's `Exporter` single-image fast path bypasses full motion/mix processing. Studio applies a full-canvas crop to force the full compositor for all scene counts. Text overlays have explicit safe-area bounds. Kadr documents an iOS Simulator limitation for Core Animation caption export; Studio displays that limitation and requires a physical device for caption-render acceptance.

## Storage and failures

Edits save atomically after a short debounce and on scene backgrounding. A failed project decode preserves the original file, disables overwrite and offers New project, which first creates a recovery copy. Old imports and exports remain available in Files for manual backup/removal; this version does not have a project library or automatic garbage collection. Cancellation removes partial output. Keep the app foregrounded during export.

## Future PC node

Add a `StudioRendering` adapter with an explicit paired-host setup, file manifest/hashes, cancellation and progress mapping. Transfer media only after user initiation. Preserve the versioned `StudioProject` schema and local fallback. No dormant upload endpoint, account system, credentials or network transport exists in v1.

## Visual fidelity

Reference: user-approved “ChatGPT Image Nov 11, 2026, 12_32_28 AM.png”. Studio follows the near-black/deep-green surfaces, fine mint strokes, amber uppercase headings, teal controls and exact section sequence. Native scrolling and 44-point controls replace the reference's compressed poster proportions. Original procedural landscapes make the app usable before media import; they do not reproduce the reference's automotive photographs or imply image-model output.
