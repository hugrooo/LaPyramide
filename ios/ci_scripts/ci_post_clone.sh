#!/bin/sh

# Fail this script if any subcommand fails.
set -e

# Navigate to the root of the repository
cd $CI_PRIMARY_REPOSITORY_PATH

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter

# Add Flutter to the path.
export PATH="$PATH:$HOME/flutter/bin"

# Disable Swift Package Manager globally in Xcode Cloud's Flutter to use CocoaPods for all plugins.
flutter config --no-enable-swift-package-manager

# Pre-download Development Binaries.
flutter precache --ios

# Install dependencies.
flutter pub get

# Generate Flutter iOS files (Generated.xcconfig, etc) BEFORE pod install so Flutter doesn't overwrite CocoaPods scripts later.
flutter build ios --config-only

# Install/Update CocoaPods via Homebrew to prevent outdated version bugs on Xcode Cloud.
echo "Installing/Updating CocoaPods..."
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true

# Install CocoaPods dependencies.
cd ios
pod install

# Disable User Script Sandboxing & fix readlink -f in CocoaPods scripts (MUST be the final step after pod install and flutter build).
echo "ENABLE_USER_SCRIPT_SANDBOXING = NO" >> "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
echo "ENABLE_USER_SCRIPT_SANDBOXING = NO" >> "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
echo "ENABLE_USER_SCRIPT_SANDBOXING = NO" >> "Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"
echo "COCOAPODS_PARALLEL_CODE_SIGN = false" >> "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
find "Pods/Target Support Files" -type f -name "*.xcconfig" -exec sh -c '
  echo "CODE_SIGNING_ALLOWED = NO" >> "$1"
  echo "CODE_SIGNING_REQUIRED = NO" >> "$1"
  echo "DEVELOPMENT_TEAM = 8YCPB87Z72" >> "$1"
find "Pods/Target Support Files" -type f -name "*.sh" -exec sed -i '' 's/readlink -f/readlink/g' {} +
find "Pods/Target Support Files" -type f -name "Pods-Runner-resources.sh" -exec sed -i '' 's/exit 1/true/g' {} +
find "Pods/Target Support Files" -type f -name "Pods-Runner-frameworks.sh" -exec sed -i '' 's/if \[ -L "${source}" \]; then/if [ -z "${source:-}" ]; then return 0; fi\n  if [ -L "${source}" ]; then/g' {} +





