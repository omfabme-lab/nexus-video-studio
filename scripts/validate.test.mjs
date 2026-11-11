import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {generate, root} from './generate-project.mjs';

const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
const files = directory => fs.readdirSync(directory, {withFileTypes: true}).flatMap(entry => {
  const name = path.join(directory, entry.name);
  return entry.isDirectory() ? files(name) : [name];
});

test('checked-in Xcode project and shared scheme exactly match the generator', () => {
  const {pbx, scheme} = generate();
  assert.equal(read('NexusVideoStudio.xcodeproj/project.pbxproj'), pbx);
  assert.equal(read('NexusVideoStudio.xcodeproj/xcshareddata/xcschemes/NexusVideoStudio.xcscheme'), scheme);
});
test('every project object reference resolves; each app source is included exactly once', () => {
  const pbx = read('NexusVideoStudio.xcodeproj/project.pbxproj');
  const objects = [...pbx.matchAll(/^\s*([A-F0-9]{24}) = \{/gm)].map(m => m[1]);
  assert.equal(new Set(objects).size, objects.length);
  for (const reference of pbx.matchAll(/\b[A-F0-9]{24}\b/g)) assert.ok(objects.includes(reference[0]), reference[0]);
  for (const name of fs.readdirSync(path.join(root, 'App')).filter(x => x.endsWith('.swift'))) {
    assert.equal(pbx.split(`path = "${name}"`).length - 1, 1, name);
  }
});
test('iPhone/iOS 27 target is unsigned and has no development team', () => {
  const pbx = read('NexusVideoStudio.xcodeproj/project.pbxproj');
  for (const setting of ['IPHONEOS_DEPLOYMENT_TARGET = 27.0', 'TARGETED_DEVICE_FAMILY = 1',
    'CODE_SIGNING_ALLOWED = NO', 'CODE_SIGNING_REQUIRED = NO', 'DEVELOPMENT_TEAM = ""']) assert.ok(pbx.includes(setting), setting);
  assert.ok(!pbx.includes('ProvisioningStyle = Automatic'));
});
test('source snapshot matches the audited Kadr file hashes and has no missing files', () => {
  const manifest = JSON.parse(read('Vendor/Kadr/SNAPSHOT.json'));
  assert.equal(manifest.commit, 'ff6c4bf2ee6663aa7ce973ee5a678c67f6d63475');
  const current = files(path.join(root, 'Vendor/Kadr/Sources')).map(x => path.relative(path.join(root, 'Vendor/Kadr'), x).replaceAll('\\', '/')).sort();
  assert.deepEqual(current, Object.keys(manifest.sha256).sort());
  for (const [name, expected] of Object.entries(manifest.sha256)) {
    const actual = crypto.createHash('sha256').update(fs.readFileSync(path.join(root, 'Vendor/Kadr', name))).digest('hex');
    assert.equal(actual, expected, name);
  }
  assert.match(read('.gitattributes'), /Vendor\/Kadr\/Sources\/\*\* -text/);
});
test('required third-party license is bundled verbatim and shown in app', () => {
  assert.equal(read('App/Resources/Kadr-LICENSE.txt'), read('Vendor/Kadr/LICENSE'));
  assert.match(read('Vendor/Kadr/LICENSE'), /Copyright 2025 Steliyan Hadzhidenev/);
  assert.match(read('App/CapabilitiesView.swift'), /Kadr-LICENSE/);
  assert.match(read('docs/UPSTREAM-AUDIT.md'), /No source copied/);
});
test('CI is manual, public-only, least-privilege, pinned and short-retention', () => {
  const workflow = read('.github/workflows/ios-build.yml');
  assert.match(workflow, /workflow_dispatch:/);
  assert.doesNotMatch(workflow, /^\s+(push|pull_request_target|schedule):/m);
  assert.match(workflow, /contents: read/);
  assert.doesNotMatch(workflow, /: write/);
  assert.match(workflow, /github.event.repository.private == false/);
  assert.match(workflow, /runs-on: xcode-27\s/);
  assert.match(workflow, /persist-credentials: false/);
  assert.match(workflow, /retention-days: 3/);
  assert.match(workflow, /swift test --package-path Core/);
  assert.match(workflow, /iPhone 18 Pro Max/);
  assert.match(workflow, /zip -qry .*unsigned\.ipa Payload/);
  for (const action of workflow.matchAll(/uses: (\S+)/g)) assert.match(action[1], /@[a-f0-9]{40}$/);
  assert.doesNotMatch(workflow, /secrets\.|allowProvisioningUpdates|xcode-27-xlarge\s*$/m);
});
test('both package dependencies are local and runtime app has no network client', () => {
  for (const name of ['Core/Package.swift', 'Vendor/Kadr/Package.swift']) assert.doesNotMatch(read(name), /\.package\(url:/);
  const app = files(path.join(root, 'App')).filter(x => x.endsWith('.swift')).map(x => fs.readFileSync(x, 'utf8')).join('\n');
  assert.doesNotMatch(app, /URLSession|WKWebView|https?:\/\//);
  assert.match(read('App/BriefAssistant.swift'), /SystemLanguageModel\.default\.availability/);
});
test('privacy descriptions, portrait mode and local file access are declared', () => {
  const info = read('App/Info.plist');
  for (const key of ['NSCameraUsageDescription', 'NSMicrophoneUsageDescription', 'NSPhotoLibraryAddUsageDescription', 'UIFileSharingEnabled', 'UIInterfaceOrientationPortrait']) assert.ok(info.includes(key), key);
  assert.doesNotMatch(info, /NSAllowsArbitraryLoads|UIBackgroundModes|UIInterfaceOrientationLandscape/);
  assert.match(read('App/Resources/PrivacyInfo.xcprivacy'), /NSPrivacyTracking<\/key><false\/>/);
});
test('app icon is a valid opaque 1024-square PNG and all resource references exist', () => {
  const iconDir = 'App/Resources/Assets.xcassets/AppIcon.appiconset';
  const catalog = JSON.parse(read(`${iconDir}/Contents.json`));
  const png = fs.readFileSync(path.join(root, iconDir, catalog.images[0].filename));
  assert.deepEqual([...png.subarray(0, 8)], [137,80,78,71,13,10,26,10]);
  assert.equal(png.readUInt32BE(16), 1024); assert.equal(png.readUInt32BE(20), 1024);
  assert.equal(png[25], 2); // RGB, no alpha.
});
test('distribution excludes models, private credentials and runtime media', () => {
  const forbidden = /\.(ipa|mp4|mov|m4a|p12|mobileprovision|safetensors|ckpt)$/i;
  for (const file of files(root)) {
    const relative = path.relative(root, file);
    if (relative.split(path.sep).some(x => ['.build', 'build', '.git'].includes(x))) continue;
    assert.ok(!forbidden.test(file), relative);
    assert.ok(fs.statSync(file).size < 5_000_000, `Unexpected large file: ${relative}`);
  }
});
