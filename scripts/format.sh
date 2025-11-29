#!/bin/bash
# Easydict SwiftFormat Script

set -e

#Docs https://github.com/nicklockwood/SwiftFormat#using-swift-package-manager

if [ "${ENABLE_PREVIEWS}" = "YES" ]; then
  echo "SwiftFormat skipped for Xcode Previews."
  exit 0;
fi
# "${PODS_ROOT}/SwiftFormat/CommandLineTool/swiftformat" "$SRCROOT"

cd BuildTools
SDKROOT=(xcrun --sdk macosx --show-sdk-path)
#swift package update #Uncomment this line temporarily to update the version used to the latest matching your BuildTools/Package.swift file
swift run -c release swiftformat "$SRCROOT"
