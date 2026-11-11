# Staged acceptance plan

Do not equate source/configuration checks with a successful iOS compile or physical-device export. Preserve each stage's evidence before advancing.

## Stage 1 — Windows, completed locally

- Run `node --test scripts/validate.test.mjs`. Tests cover deterministic project generation, PBX references, app source inclusion, iOS target/signing settings, Kadr file integrity, bundled license, workflow permissions/pins/retention, local dependencies, permission strings and icon/source packaging.
- Parse the generated PBX project, Info.plist/privacy manifest and workflow using independent parsers in the scratch validation environment.
- Parse original Swift source with a Swift grammar. This is syntax validation only; SDK types and Swift semantics require Xcode.
- Inspect a clearly labeled Windows design preview for clipping, contrast and hierarchy. It is not an iOS screenshot. CI produces the first real simulator screenshot.

## Stage 2 — Xcode 27, prepared / not run

Run the manual workflow in the approved public repository. Expected evidence: Xcode/SDK versions, successful portable Swift unit tests, successful device and simulator builds, simulator launch PID and iPhone 18 Pro Max screenshot, unsigned IPA and SHA-256.

`Core/Tests/StudioCoreTests` tests overlap and caption boundaries, hard cuts, single-scene duration, short video trim clamping, persistence round-trip, unsafe paths, malformed durations, two-minute limit, empty timeline and malformed AI output. Add regressions here when changing the project contract. They test production Swift logic, not a JavaScript port.

Inspect compiler diagnostics; warnings about deprecated platform APIs are not automatically runtime failures, but new errors must be resolved. Simulator export with caption overlays is explicitly unsupported by the pinned engine. The physical-device stage must cover it.

## Stage 3 — free-account install on physical iPhone 18 Pro Max / iOS 27

Install with the README's AltStore Classic Windows route. Record iOS build, AltServer/AltStore versions, free-account signing result and launch result. Confirm no paid entitlement, credential collection or external model/API dependency. Deny camera/mic once; verify an understandable error and recovery after enabling permission.

## Stage 4 — useful offline film

1. In airplane mode, launch the default project and render it. Verify six original keyframes, motion and dissolves, 19.25-second duration, visible readable captions, 1080×1920 dimensions and 30fps. Verify it has no watermark.
2. Turn captions/dissolves off separately. Confirm visible changes and 21-second hard-cut duration. Test one still with captions off, motion on and two audio tracks to exercise the full-composition workaround.
3. Import landscape/portrait/rotated HEIC/JPEG/PNG and H.264/HEVC clips. Check orientation, centered crop and thumbnails. Test a 0.5-second video and nonzero trim. Test iCloud-only media with a connection, then airplane mode after import. Reject unreadable, audio-only-as-video and >200 MB input without losing the prior shot.
4. Edit captions to 80 characters, including emoji and a long unbroken word. Test short/long durations, all four motions, reordering/deleting/adding and the 12-scene limit. Check transition boundaries for black flashes, overlap errors or caption duplication.
5. Import known music and spoken narration, test each level including zero, enable clip audio, and verify mix duration and fades. Record a short narration and a recording that reaches the two-minute cap. Interrupt with a phone call/backgrounding; errors must be surfaced without corrupting the project.
6. Compare review copy to final export: caption text/timing, crop, transition timing and mix should match apart from resolution. Scrub and replay. Cancel a long render and render again; partial output must not be offered for sharing.
7. Save using Share → Files/Photos; reopen the exported MP4 in a separate player and inspect actual metadata. Test low storage, screen locking/background during render, HDR footage and unsupported codecs; document limitations rather than claiming success.

## Stage 5 — persistence and accessibility

Force-quit/relaunch after import and edit. Confirm media references remain valid and recordings survive. Remove a media file in Files; export must report the missing input. Corrupt a backed-up copy of project.json; verify original preservation and recovery copy before New project. Confirm source media and exports are never overwritten. Back up before uninstalling.

Check VoiceOver labels/order, Large/Accessibility text sizes, 44-point targets, safe areas and contrast. Check the 3-column grid with long shot titles. Test on the requested device size and one narrower simulator to catch layout pressure.

## Stage 6 — refresh and readiness

Refresh with AltServer on Windows before free provisioning expires; relaunch and verify persisted project. A first-build acceptance requires Stages 2–5 to pass on the actual toolchain/device. This delivery is reviewable source awaiting those external gates, not a claim of App Store or device qualification.
