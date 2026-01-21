#!/bin/bash

# Build script for OrderShieldSDK Framework
# Usage: ./build_framework.sh [debug|release] [device|simulator]

set -e

PROJECT_NAME="OrderShieldSDK"
SCHEME="OrderShieldSDK"
CONFIGURATION="${1:-Release}"
SDK_TYPE="${2:-device}"

if [ "$SDK_TYPE" == "device" ]; then
    SDK="iphoneos"
    ARCH="arm64"
else
    SDK="iphonesimulator"
    ARCH="x86_64"
fi

echo "Building $PROJECT_NAME for $SDK_TYPE ($CONFIGURATION)..."
echo "SDK: $SDK, Architecture: $ARCH"

# Clean previous builds
echo "Cleaning..."
xcodebuild clean -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -quiet

# Build framework
echo "Building..."
xcodebuild build -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk "$SDK" \
    -arch "$ARCH" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    -quiet

# Find the built framework
BUILD_DIR=$(xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk "$SDK" \
    -showBuildSettings | grep -m 1 "BUILT_PRODUCTS_DIR" | grep -oEi "\/.*" | xargs)

FRAMEWORK_PATH="${BUILD_DIR}/${PROJECT_NAME}.framework"

if [ -d "$FRAMEWORK_PATH" ]; then
    echo "✅ Framework built successfully!"
    echo "📍 Location: $FRAMEWORK_PATH"
    echo ""
    echo "To use in your app:"
    echo "1. Drag $FRAMEWORK_PATH into your Xcode project"
    echo "2. In your app target, go to General → Frameworks, Libraries, and Embedded Content"
    echo "3. Add OrderShieldSDK.framework and set to 'Embed & Sign'"
else
    echo "❌ Framework not found at expected location"
    exit 1
fi

