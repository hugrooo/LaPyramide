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

# Pre-download Development Binaries.
flutter precache --ios

# Install dependencies.
flutter pub get

# Install CocoaPods dependencies.
cd ios
pod install
