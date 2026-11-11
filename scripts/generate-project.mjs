import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

export const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const id = text => crypto.createHash('sha256').update(text).digest('hex').slice(0, 24).toUpperCase();
const quote = text => JSON.stringify(text);
export function generate() {
  const objects = [];
  const add = (key, body) => { objects.push(`\t\t${id(key)} = { ${body} };`); return id(key); };
  const sources = fs.readdirSync(path.join(root, 'App')).filter(x => x.endsWith('.swift')).sort();
  const resources = ['Resources/Kadr-LICENSE.txt', 'Resources/PrivacyInfo.xcprivacy', 'Resources/Assets.xcassets'];
  const sourceIDs = sources.map(name => {
    const file = add(`file:${name}`, `isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ${quote(name)}; sourceTree = "<group>";`);
    return add(`build:${name}`, `isa = PBXBuildFile; fileRef = ${file};`);
  });
  const resourceIDs = resources.map(name => {
    const type = name.endsWith('xcassets') ? 'folder.assetcatalog' : name.endsWith('xcprivacy') ? 'text.xml' : 'text';
    const file = add(`file:${name}`, `isa = PBXFileReference; lastKnownFileType = ${type}; path = ${quote(name)}; sourceTree = "<group>";`);
    return add(`build:${name}`, `isa = PBXBuildFile; fileRef = ${file};`);
  });
  add('info', 'isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>";');
  add('product', 'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = NexusVideoStudio.app; sourceTree = BUILT_PRODUCTS_DIR;');
  add('appGroup', `isa = PBXGroup; children = (${[...sources, ...resources].map(x => id(`file:${x}`)).join(',')},${id('info')},); path = App; sourceTree = "<group>";`);
  add('products', `isa = PBXGroup; children = (${id('product')},); name = Products; sourceTree = "<group>";`);
  add('mainGroup', `isa = PBXGroup; children = (${id('appGroup')},${id('products')},); sourceTree = "<group>";`);
  const packages = [['Core', 'StudioCore'], ['Vendor/Kadr', 'Kadr']];
  for (const [directory, name] of packages) {
    add(`package:${name}`, `isa = XCLocalSwiftPackageReference; relativePath = ${quote(directory)};`);
    add(`dependency:${name}`, `isa = XCSwiftPackageProductDependency; package = ${id(`package:${name}`)}; productName = ${name};`);
    add(`framework:${name}`, `isa = PBXBuildFile; productRef = ${id(`dependency:${name}`)};`);
  }
  add('sources', `isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (${sourceIDs.join(',')},); runOnlyForDeploymentPostprocessing = 0;`);
  add('resources', `isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (${resourceIDs.join(',')},); runOnlyForDeploymentPostprocessing = 0;`);
  add('frameworks', `isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (${packages.map(([, n]) => id(`framework:${n}`)).join(',')},); runOnlyForDeploymentPostprocessing = 0;`);
  for (const configuration of ['Debug', 'Release']) {
    add(`project:${configuration}`, `isa = XCBuildConfiguration; buildSettings = { CLANG_ENABLE_MODULES = YES; SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 27.0; SWIFT_VERSION = 5.0; SWIFT_STRICT_CONCURRENCY = targeted; ${configuration === 'Debug' ? 'SWIFT_OPTIMIZATION_LEVEL = "-Onone"; DEBUG_INFORMATION_FORMAT = dwarf;' : 'SWIFT_OPTIMIZATION_LEVEL = "-O"; DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";'} }; name = ${configuration};`);
    add(`target:${configuration}`, `isa = XCBuildConfiguration; buildSettings = { PRODUCT_NAME = "$(TARGET_NAME)"; PRODUCT_BUNDLE_IDENTIFIER = studio.nexus.video; INFOPLIST_FILE = App/Info.plist; GENERATE_INFOPLIST_FILE = NO; TARGETED_DEVICE_FAMILY = 1; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; SUPPORTS_MACCATALYST = NO; CODE_SIGN_STYLE = Manual; CODE_SIGNING_ALLOWED = NO; CODE_SIGNING_REQUIRED = NO; DEVELOPMENT_TEAM = ""; ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks"; SWIFT_EMIT_LOC_STRINGS = YES; }; name = ${configuration};`);
  }
  for (const scope of ['project', 'target']) add(`${scope}Configs`, `isa = XCConfigurationList; buildConfigurations = (${id(`${scope}:Debug`)},${id(`${scope}:Release`)},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;`);
  add('target', `isa = PBXNativeTarget; buildConfigurationList = ${id('targetConfigs')}; buildPhases = (${id('sources')},${id('frameworks')},${id('resources')},); buildRules = (); dependencies = (); name = NexusVideoStudio; packageProductDependencies = (${packages.map(([, n]) => id(`dependency:${n}`)).join(',')},); productName = NexusVideoStudio; productReference = ${id('product')}; productType = "com.apple.product-type.application";`);
  add('project', `isa = PBXProject; attributes = { BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 2700; }; buildConfigurationList = ${id('projectConfigs')}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base,); mainGroup = ${id('mainGroup')}; packageReferences = (${packages.map(([, n]) => id(`package:${n}`)).join(',')},); productRefGroup = ${id('products')}; projectDirPath = ""; projectRoot = ""; targets = (${id('target')},);`);
  const pbx = `// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n${objects.join('\n')}\n\t};\n\trootObject = ${id('project')};\n}\n`;
  const ref = `<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="${id('target')}" BuildableName="NexusVideoStudio.app" BlueprintName="NexusVideoStudio" ReferencedContainer="container:NexusVideoStudio.xcodeproj"/>`;
  const scheme = `<?xml version="1.0" encoding="UTF-8"?>\n<Scheme LastUpgradeVersion="2700" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">${ref}</BuildActionEntry></BuildActionEntries></BuildAction><TestAction buildConfiguration="Debug" shouldUseLaunchSchemeArgsEnv="YES"/><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">${ref}</BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES"/><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>\n`;
  return {pbx, scheme};
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const {pbx, scheme} = generate();
  const project = path.join(root, 'NexusVideoStudio.xcodeproj');
  fs.mkdirSync(path.join(project, 'xcshareddata', 'xcschemes'), {recursive: true});
  fs.writeFileSync(path.join(project, 'project.pbxproj'), pbx);
  fs.writeFileSync(path.join(project, 'xcshareddata', 'xcschemes', 'NexusVideoStudio.xcscheme'), scheme);
  console.log('Generated deterministic Xcode project and shared scheme.');
}
