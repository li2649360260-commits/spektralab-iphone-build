#!/bin/bash
# Build the public RA4 iOS port without changing its rendering engine.
# Signing is a separate, user-controlled installation step.
set -euo pipefail

readonly SOURCE_COMMIT=51e1e15fcbd0f192b9fbd651d71c73912c1cafbb
readonly SOURCE_URL=https://github.com/lyolomeister/RA4
tools_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if [[ "$(uname -s)" != Darwin ]]; then
  echo 'This build requires macOS with Xcode. On Windows, run the GitHub Actions workflow.' >&2
  exit 2
fi

source_dir=${1:-"$tools_root/upstream"}
output_dir=${2:-"$tools_root/output/ios"}
bundle_id=${APP_BUNDLE_ID:-org.spektrafork.iphone}
if [[ ! "$bundle_id" =~ ^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z][A-Za-z0-9-]*){2,}$ ]]; then
  echo 'APP_BUNDLE_ID must be a reverse-domain identifier, for example org.spektrafork.iphone.' >&2
  exit 2
fi

source_dir=$(CDPATH= cd -- "$source_dir" && pwd)
mkdir -p "$output_dir"
output_dir=$(CDPATH= cd -- "$output_dir" && pwd)
exec > >(tee "$output_dir/build.log") 2>&1

actual_commit=$(git -C "$source_dir" rev-parse HEAD)
if [[ "$actual_commit" != "$SOURCE_COMMIT" ]]; then
  echo "Unexpected source commit: $actual_commit; expected $SOURCE_COMMIT" >&2
  exit 1
fi
if [[ -n "$(git -C "$source_dir" status --porcelain --untracked-files=no)" ]]; then
  echo 'Source has tracked changes. Use a clean checkout of the pinned commit.' >&2
  exit 1
fi
for path in \
  engine/build-ios.sh \
  engine/resources/spektrafilm_constants.bin \
  SpektraProbe/SpektraProbe.xcodeproj/project.pbxproj \
  license/LICENSE \
  license/SPEKTRAFILM_LICENSE.txt \
  modern_UI/Spektrafilm/Spektrafilm/Resources/Licenses/Profiles-and-LUTs-CHANGELOG.txt; do
  if [[ ! -f "$source_dir/$path" ]]; then
    echo "Missing build input: $path" >&2
    exit 1
  fi
done

# A fresh directory prevents an old .ipa or result bundle from appearing successful.
for path in RA4.xcarchive Build.xcresult RA4-iPhone-unsigned.ipa; do
  if [[ -e "$output_dir/$path" ]]; then
    echo "Output already exists: $output_dir/$path. Choose a new output directory." >&2
    exit 1
  fi
done

xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
if ! xcrun --sdk iphoneos metal --version; then
  xcodebuild -downloadComponent MetalToolchain
  xcrun --sdk iphoneos metal --version
fi

# Preserve the upstream safe-math shader flags and resource bundling verbatim.
bash "$source_dir/engine/build-ios.sh"
xcodebuild \
  -project "$source_dir/SpektraProbe/SpektraProbe.xcodeproj" \
  -scheme SpektraProbe \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$output_dir/DerivedData" \
  -archivePath "$output_dir/RA4.xcarchive" \
  -resultBundlePath "$output_dir/Build.xcresult" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY= \
  DEVELOPMENT_TEAM= \
  PRODUCT_BUNDLE_IDENTIFIER="$bundle_id" \
  archive

app="$output_dir/RA4.xcarchive/Products/Applications/SpektraProbe.app"
plist="$app/Info.plist"
platform=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleSupportedPlatforms:0' "$plist")
identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist")
executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist")
minimum_os=$(/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$plist")
if [[ "$platform" != iPhoneOS || "$identifier" != "$bundle_id" ]]; then
  echo 'The archive is not the requested iPhone application.' >&2
  exit 1
fi
xcrun lipo -verify_arch arm64 "$app/$executable"
file "$app/$executable"
for resource in \
  engine/spektrafilm.metallib \
  engine/spektrafilm_constants.bin \
  engine/profiles/kodak_portra_400.json \
  Licenses/GPL-3.0.txt \
  Licenses/Profiles-and-LUTs-CC-BY-SA-4.0.txt \
  Licenses/Profiles-and-LUTs-CHANGELOG.txt \
  Licenses/metal-cpp-Apache-2.0.txt; do
  if [[ ! -s "$app/$resource" ]]; then
    echo "Incomplete application bundle: $resource" >&2
    exit 1
  fi
done

# IPA is a ZIP containing Payload/<name>.app. This is a compiled device binary;
# it is deliberately unsigned, so it still needs personal signing before installation.
package_dir=$(mktemp -d "$output_dir/.ipa-package.XXXXXX")
mkdir "$package_dir/Payload"
ditto "$app" "$package_dir/Payload/SpektraProbe.app"
ditto -c -k --keepParent "$package_dir/Payload" "$output_dir/RA4-iPhone-unsigned.ipa"
unzip -tq "$output_dir/RA4-iPhone-unsigned.ipa"
cp "$source_dir/SpektraProbe/SpektraProbe/SpektraProbe.entitlements" "$output_dir/"
cp "$tools_root/docs/INSTALL-iPhone.zh-CN.md" "$output_dir/"
{
  printf 'Source: %s\nCommit: %s\n' "$SOURCE_URL" "$actual_commit"
  printf 'Builder commit: %s\n' "$(git -C "$tools_root" rev-parse HEAD 2>/dev/null || echo uncommitted)"
  printf 'Bundle identifier: %s\nMinimum iOS: %s\n' "$identifier" "$minimum_os"
  printf 'Built at UTC: %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  xcodebuild -version
  printf 'SDK: '; xcrun --sdk iphoneos --show-sdk-version
  printf 'Signing: unsigned; personal signing required before device installation\n'
  printf 'Verification: archive, arm64 architecture, resources and ZIP integrity checked\n'
  printf 'Device testing: not performed by this cloud build\n'
} > "$output_dir/BUILD-INFO.txt"
(
  cd "$output_dir"
  shasum -a 256 RA4-iPhone-unsigned.ipa BUILD-INFO.txt SpektraProbe.entitlements INSTALL-iPhone.zh-CN.md > SHA256SUMS.txt
)
echo "Compiled IPA: $output_dir/RA4-iPhone-unsigned.ipa"
