# Nexus Video Studio

A standalone, portrait-first iPhone filmmaking workspace. Built for **iPhone 18 Pro Max / iOS 27** with SwiftUI and a pinned local Kadr/AVFoundation engine. This project is deliberately independent of the existing Nexus app.

**Status:** implemented source project and local validation evidence. An iOS binary has not yet been compiled or installed: this Windows machine has no Xcode. Run the prepared public-repository GitHub Actions workflow to pass that gate. No repository has been created or pushed, and no Apple credentials or model weights have been requested.

## What you can do

Write a brief; build six editable storyboard shots; import stills, generated keyframes or videos from Photos/Files; capture a clip; trim, reorder and caption shots; animate stills; mix music, recorded/imported narration and optional source audio; render a review copy; export a watermark-free portrait MP4 and share it. The included original landscape keyframes allow an entirely offline first film without importing anything.

Optional Apple on-device text assistance drafts captions when its system model is available. There is no local text-to-video model, diffusion-image generation, paid API, account screen, subscription or cloud upload. See the in-app **ⓘ Inside Studio** screen and [capability/architecture notes](docs/ARCHITECTURE.md).

## First film

1. Open Studio. Replace the brief, then choose **Build storyboard** and confirm replacing the draft.
2. Tap a storyboard card to edit its title, caption, duration or motion. Use Move earlier/later to reorder.
3. The last selected shot receives imports from **CAMERA → Photos / Files / Capture**. Import a generated image just like any other still.
4. Under **EDIT**, choose captions, dissolves and source audio. Add music, import narration, or record narration; stop recording before rendering. Set music low enough to hear speech.
5. Tap **Preview**. It renders a 540p review copy including captions/audio, then plays with a scrubber. Edit as needed and render again.
6. Tap **Export** for 1080×1920 / 30fps H.264, then the share button. Choose Save to Files, Save Video or another installed destination.

Limits: 1–12 scenes, two-minute output, 200 MB/import. Single saved project. Centered portrait crop, no manual crop positioning. Music/narration start at 0:00; short audio does not loop. Scene captions are not automatic transcription. Keep Studio foregrounded for rendering. It does not currently offer 4K or a PC render node.

## Windows → GitHub Actions → iPhone (free route)

### 1. Publish only this reviewed folder

Publication is the one material external gate: **creating a public repository named `nexus-video-studio` and uploading the contents of this folder** makes its source publicly visible. It is necessary for the requested free standard-runner route. The agent has not performed it. Review the source and approve that exact action before asking the agent to proceed, or perform these steps yourself.

Install Git for Windows. Create an **empty public** repository in your free GitHub account; do not initialize it with a README. Open PowerShell in this `NexusVideoStudio` folder. Replace `YOUR-USERNAME` with your own account name:

```powershell
git init -b main
git add .
git status --short
git commit -m "Add standalone Nexus Video Studio"
git remote add origin https://github.com/YOUR-USERNAME/nexus-video-studio.git
git push -u origin main
```

Authenticate in Git's official browser/device flow. Do not paste tokens or passwords into source files, workflow inputs or this chat. Push this folder only, not the parent scratch directory. The project already contains the generated `.xcodeproj`, local packages, icon and licenses; no XcodeGen install is needed.

### 2. Build the unsigned IPA

1. Open your repository → **Actions**. Enable Actions if prompted.
2. Select **Build unsigned iPhone app** → **Run workflow** → `main` → **Run workflow**.
3. Wait for the run. It checks the toolchain, validates source integrity, runs Swift unit tests, builds the device app unsigned, packages the IPA, and builds/launches the iPhone 18 Pro Max simulator.
4. Open the completed run. Download **NexusVideoStudio-unsigned-and-evidence** from Artifacts within **3 days**. Extract the downloaded ZIP in Windows. Keep `NexusVideoStudio-unsigned.ipa` and the `evidence` folder.
5. Verify the IPA hash against `evidence/ipa-sha256.txt`:

```powershell
Get-FileHash .\NexusVideoStudio-unsigned.ipa -Algorithm SHA256
```

The workflow uses `xcode-27`, the standard arm64 runner listed by GitHub, and runs only on manual dispatch in a public repository. Standard public runners are free; do not choose a larger runner or enable paid services. It needs no repository secrets, signing certificate, provisioning profile, paid Apple membership or GitHub write permission. See [GitHub's public runner table](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

If the run fails, download the evidence and inspect the first compiler/test failure. An IPA present after a later simulator failure is not a fully green acceptance result. If GitHub changes the runner or simulator inventory, review the official inventory and update the workflow; do not silently downgrade the requested SDK.

### 3. Install AltStore Classic using Windows

Follow the current [official Windows guide](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows), including its Apple iTunes/iCloud prerequisites and any supported alternate installation steps. Use **AltStore Classic**, not AltStore PAL.

Install AltServer for Windows, connect and unlock the iPhone, trust the PC and enable Wi-Fi sync in iTunes. Use AltServer's tray menu → Install AltStore → your device. Complete Apple sign-in only in the official local UI. On iPhone, trust the developer profile under Settings → General → VPN & Device Management if prompted. Enable Settings → Privacy & Security → Developer Mode and restart if required.

### 4. Sideload Studio

Transfer the extracted `.ipa` to Files on your iPhone (for example using your own iCloud Drive). Keep AltServer running and reachable on the same network or via USB. Open AltStore Classic → My Apps → **+**, choose `NexusVideoStudio-unsigned.ipa`, and let AltStore sign/install it with your free Apple account. Complete any authentication in AltStore itself. Launch Nexus Video Studio.

The IPA is intentionally unsigned. A build artifact is not installable by simply tapping it; AltStore performs local signing. Actual installation with the user's current iOS/AltServer versions remains untested.

### 5. Refresh and protect your work

Free-account apps expire after **7 days** and have a **3 active sideloaded-app** limit, including AltStore. Keep AltServer accessible and use AltStore → My Apps → Refresh All before expiry. See [AltStore's explanation](https://faq.altstore.io/altstore-classic/your-altstore). If an app expires, refresh/reinstall through the official process. Back up `Files → On My iPhone → Nexus Video Studio → Studio` before uninstalling; uninstalling removes local project data. Studio never handles Apple account credentials.

## Validation and development

On Windows with Node.js 22+:

```powershell
node --test scripts/validate.test.mjs
```

This verifies the Xcode project, pinned dependency inventory, permissions, workflow guardrails, resources and source packaging. It is not a Swift compiler. The Foundation-only Swift unit tests run in CI using `swift test --package-path Core`. See [validation evidence](docs/VALIDATION.md) and the [staged test plan](docs/TEST-PLAN.md).

After adding/removing app Swift files, regenerate with `node scripts/generate-project.mjs`. The original icon is reproducible with `node scripts/generate-icon.mjs`. Neither script needs npm dependencies. The checked-in Xcode project is the build input.

On a Mac with Xcode 27, open `NexusVideoStudio.xcodeproj`, select the shared `NexusVideoStudio` scheme and a simulator. For the exact unsigned device build command, see `.github/workflows/ios-build.yml`. Caption rendering needs physical-device acceptance because of Kadr's documented simulator overlay limitation.

## Licenses

Original Studio source and procedural artwork: [MIT](LICENSE). Kadr: [Apache-2.0](Vendor/Kadr/LICENSE), pinned at `ff6c4bf2ee6663aa7ce973ee5a678c67f6d63475`. Full upstream audit and exclusions: [UPSTREAM-AUDIT.md](docs/UPSTREAM-AUDIT.md). No model weights, stock photos, music, embedded credentials or paid dependencies are distributed.
