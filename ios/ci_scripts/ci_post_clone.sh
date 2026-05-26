#!/bin/sh

# Fail this script if any subcommand fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
cd .. # Navigate to the ios directory.
cd .. # Navigate to the project root directory.

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
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods

# Install CocoaPods dependencies.
cd ios
pod install
