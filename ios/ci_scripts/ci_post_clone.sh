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

# Install/Update CocoaPods via Homebrew to prevent outdated version bugs on Xcode Cloud.
echo "Installing/Updating CocoaPods..."
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true

# Install CocoaPods dependencies.
cd ios
pod install

# Fix readlink -f in CocoaPods framework scripts for Xcode Cloud
find "Pods/Target Support Files" -type f -name "*.sh" -exec sed -i '' 's/readlink -f/readlink/g' {} +

# Generate Flutter iOS files (Generated.xcconfig, etc) so Xcode can build.
cd ..
flutter build ios --config-only

