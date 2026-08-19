#!/bin/bash

# Script to generate app icons and splash screens
# Run this after adding your app_icon.png to assets/icon/

set -e

echo "════════════════════════════════════════════════════════════════"
echo "  CreditBook App Asset Generator"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check if icon exists
if [ ! -f "assets/icon/app_icon.png" ]; then
    echo "❌ Error: assets/icon/app_icon.png not found!"
    echo ""
    echo "Please add your wallet icon (1024x1024 PNG) to:"
    echo "  assets/icon/app_icon.png"
    echo ""
    echo "See assets/icon/README.md for requirements"
    exit 1
fi

echo "✓ Found app_icon.png"
echo ""

# Get dependencies
echo "📦 Installing dependencies..."
fvm flutter pub get
echo ""

# Generate launcher icons
echo "🎨 Generating launcher icons..."
fvm dart run flutter_launcher_icons
echo ""

# Generate splash screen
echo "🌅 Generating splash screens..."
fvm dart run flutter_native_splash:create
echo ""

# Clean build
echo "🧹 Cleaning build..."
fvm flutter clean
echo ""

echo "════════════════════════════════════════════════════════════════"
echo "  ✅ Success! App assets generated successfully"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Run: fvm flutter run"
echo "  2. Your custom icon and splash screen will appear"
echo "  3. For production build: fvm flutter build apk --release"
echo ""
echo "Note: You may need to uninstall the old app first to see changes"
echo ""
