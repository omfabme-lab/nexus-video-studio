# Validation evidence — 2026-11-11

## Result and exact remaining gate

The isolated source project is implemented and reviewable. **No Xcode compile, simulator execution, IPA generation, AltStore installation or device export has run yet.** This Windows environment has Node.js 24.20.0 but no Swift toolchain, Xcode or installed WSL. The next required gate is the manual Xcode 27 workflow after approval to publish this folder to a public GitHub repository. Successful physical iPhone export remains a separate acceptance gate after compilation.

## Checks performed on Windows

| Check | Observed result |
|---|---|
| `node --test scripts/validate.test.mjs` | 10 tests passed; 0 failed |
| Independent PBX/OpenStep parsing (`xcode` 3.0.1) | Parsed the generated project and found the NexusVideoStudio native application target |
| XML property-list parsing (`plist` 3.1.0) | Info.plist and PrivacyInfo.xcprivacy parsed successfully |
| Workflow YAML parsing (`yaml` 2.8.1) | Manual workflow parsed; 7 steps; runner `xcode-27` |
| Swift grammar parsing (`web-tree-sitter` 0.20.8 / `tree-sitter-wasms` 0.1.13) | 13 original Swift files parsed with 0 syntax errors; not SDK/type checking |
| Kadr source integrity | All 78 included source/documentation files matched the audited snapshot SHA-256 inventory |
| App icon | Opaque 1024×1024 RGB PNG, valid signature and asset catalog |
| Windows browser design preview | Rendered with headless Edge; 720×2000 capture; no horizontal document overflow at 390px viewport |
| Visual inspection | Confirmed ordered dark-green panels, mint borders/controls, amber hierarchy, original keyframes and readable spacing |

The supplemental parser/browser tools live only in the task's scratch `work/validation` directory; they are not runtime or build dependencies of the delivered app. The checked-in Node test suite has no npm dependency. The Swift parser needed V8's `--liftoff-only` flag on this Windows environment; the final run exited successfully. A single-line optional-await thumbnail expression was rewritten as explicit do/catch, and the final grammar pass was clean.

The independent PBX library's convenience accessor assumes section comments that the deterministic generator does not need; validation instead inspected the successfully parsed OpenStep object graph directly. Xcode/plutil validation is additionally enforced by the prepared CI job.

## Code review fixes made before delivery

- Forced full composition for single stills so Kadr's shortcut cannot skip motion or the second audio track.
- Explicit caption layout bounds and shared caption/transition timing for preview and export.
- Limited transition overlap for half-second clips to avoid overlapping incoming/outgoing transition regions.
- Kept export edits locked, cancellation cooperative, and partial outputs unavailable for sharing.
- Separated import/AI busy state from render cancellation controls.
- Downsampled thumbnails independently from full-resolution render images to reduce grid memory use.
- Guarded recording completion by the recorder URL to prevent an old callback from completing a newer recording.
- Preserved invalid saved projects and made render duration limits independent from reopening editable drafts.
- Preserved audited vendor file bytes through Git attributes so Windows and macOS checkouts retain identical snapshot hashes.

## Evidence files

- `windows-tests.txt`: checked-in dependency-free source/configuration test output.
- `windows-parsers.txt`: independent parsing output for the final original sources/configuration.
- `design-preview.png` and `design-preview.html`: clearly labeled Windows design companion, **not an iOS screenshot**.
- `Vendor/Kadr/SNAPSHOT.json`: source integrity inventory and upstream commit.

## Prepared but not executed

Seven Swift XCTest cases exercise production StudioCore logic: overlap/caption boundaries, hard cuts/single scene, very short scenes, trim clamping, JSON/path validation, malformed durations/limits and storyboard/AI output handling. They run with `swift test --package-path Core` in the macOS workflow. They have not been passed off as executed on Windows.

The workflow also builds the unsigned physical-device app, packages `Payload/NexusVideoStudio.app` into an IPA, builds/launches the iPhone 18 Pro Max simulator and captures its screen. It retains logs and artifacts for three days. Public-repository creation/push is intentionally not performed. No Apple credential or signing secret is required in CI.

See [TEST-PLAN.md](TEST-PLAN.md) for physical-device rendering, media edge cases, accessibility, persistence and provisioning-refresh acceptance. No claim of 4K, photorealistic local text-to-video, automatic transcription, universal codec support or verified iOS 27 AltStore installation is made.
