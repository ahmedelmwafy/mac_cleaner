#!/bin/bash

# Exit on error
set -e

echo "=== Building MacCleaner Native App ==="

# Clean existing build if any
if [ -d "MacCleaner.app" ]; then
    echo "Cleaning old MacCleaner.app..."
    rm -rf MacCleaner.app
fi

# Create directory structure
echo "Creating application bundle directory structure..."
mkdir -p MacCleaner.app/Contents/MacOS
mkdir -p MacCleaner.app/Contents/Resources

# Compile Swift sources
echo "Compiling Swift source files..."
SDK_PATH=$(xcrun --show-sdk-path)
swiftc -sdk "$SDK_PATH" \
       -parse-as-library \
       -O \
       -o MacCleaner.app/Contents/MacOS/MacCleaner \
       main.swift Scanner.swift AppModel.swift Views.swift

# Copy Info.plist
echo "Copying Info.plist..."
cp Info.plist MacCleaner.app/Contents/Info.plist

# Make binary executable
chmod +x MacCleaner.app/Contents/MacOS/MacCleaner

echo "=== Build Complete: MacCleaner.app created successfully! ==="
echo "You can launch the app using: open MacCleaner.app"
