# 🎨 CreditBook App Icon & Splash Screen Setup Guide

## Overview

This guide will help you replace the default Flutter logo with your custom wallet icon for:

- ✅ **App Launcher Icon** (home screen icon)
- ✅ **Splash Screen** (launch screen when app opens)
- ✅ **Android Adaptive Icons** (various shapes)
- ✅ **iOS App Store Icon**

---

## 📋 Prerequisites

Before starting, you need:

1. Your wallet icon design as a **PNG file**
2. Recommended size: **1024x1024 pixels**
3. Transparent or solid background (your choice)

---

## 🚀 Quick Start (3 Steps)

### Step 1: Add Your Icon

1. Save your wallet icon as a PNG file (1024x1024 recommended)
2. Place it in: `mobile/assets/icon/app_icon.png`

### Step 2: Generate Assets

Run the automated script:

```bash
cd mobile
./generate_app_assets.sh
```

This will:

- Install required packages
- Generate all launcher icons for Android & iOS
- Generate splash screens
- Clean the build

### Step 3: Run Your App

```bash
fvm flutter run
```

**Important:** You may need to uninstall the old app first to see the new icon!

---

## 📱 Detailed Instructions

### For Android:

The script generates:

- All density icons (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- Adaptive icons for Android 8.0+
- Icons for different launcher shapes (circle, square, rounded)

### For iOS:

The script generates:

- AppIcon set for all required sizes
- App Store icon (1024x1024)
- Removes transparency (iOS requirement)

### For Splash Screen:

Generates:

- Launch screen for Android
- Launch screen for iOS
- Android 12+ splash screen
- Proper sizing and centering

---

## 🎨 Icon Design Tips

### What Makes a Good App Icon:

1. **Simple & Recognizable**
   - Clear even at 48x48 pixels
   - Works in both light and dark themes
   - Instantly recognizable as a wallet/finance app

2. **Color Scheme**
   - Use your brand colors
   - Good contrast with background
   - Avoid too many colors (2-3 colors max)

3. **Shape**
   - Centered design works best
   - Leave padding around edges (safe area)
   - Works well when cropped to circles (Android)

### Icon Specifications:

| Platform | Size        | Format | Notes                 |
| -------- | ----------- | ------ | --------------------- |
| Android  | 1024x1024   | PNG    | Adaptive icon support |
| iOS      | 1024x1024   | PNG    | No transparency       |
| Both     | 512x512 min | PNG    | Minimum acceptable    |

---

## ⚙️ Customization

### Change Background Color

Edit `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  adaptive_icon_background: "#YOUR_COLOR" # Hex color

flutter_native_splash:
  color: "#YOUR_COLOR" # Splash background color
```

Common choices:

- White: `#FFFFFF`
- Brand color: `#4CAF50` (example)
- Gradient (requires custom implementation)

### Change Icon Size on Splash

Edit `pubspec.yaml`:

```yaml
flutter_native_splash:
  android_gravity: center # or fill, center, clip_horizontal, etc.
  ios_content_mode: center # or scaleAspectFit, scaleAspectFill
```

---

## 🔧 Manual Commands

If you prefer to run commands individually:

```bash
# 1. Install dependencies
fvm flutter pub get

# 2. Generate launcher icons
fvm dart run flutter_launcher_icons

# 3. Generate splash screen
fvm dart run flutter_native_splash:create

# 4. Clean build
fvm flutter clean

# 5. Run app
fvm flutter run
```

---

## 🐛 Troubleshooting

### Icon Not Updating?

1. **Uninstall the app completely**:

   ```bash
   adb uninstall com.ktech.creditbook
   ```

2. **Clean Flutter build**:

   ```bash
   fvm flutter clean
   fvm flutter pub get
   ```

3. **Reinstall**:
   ```bash
   fvm flutter run
   ```

### Splash Screen Not Showing?

- Check that `assets/icon/app_icon.png` exists
- Verify pubspec.yaml has correct path
- Run `fvm flutter clean` and rebuild

### Icon Looks Blurry?

- Use a larger source image (1024x1024 minimum)
- Ensure PNG is high quality, not compressed
- Check that your design has sharp edges

### Android Adaptive Icon Issues?

- Ensure your icon design has padding (safe area)
- Test on different launchers (Samsung, Pixel, etc.)
- The outer 25% may be cropped in some shapes

---

## 📦 What Was Configured

### Added Packages:

- `flutter_launcher_icons: ^0.14.1` - Generates app icons
- `flutter_native_splash: ^2.4.1` - Generates splash screens

### Created Structure:

```
mobile/
├── assets/
│   └── icon/
│       ├── app_icon.png          (Your icon goes here)
│       └── README.md              (Icon requirements)
├── generate_app_assets.sh         (Automated script)
├── ICON_SETUP_GUIDE.md           (This guide)
└── pubspec.yaml                   (Updated with config)
```

### Configuration in pubspec.yaml:

- Launcher icon settings
- Splash screen settings
- Asset paths

---

## 🎯 Next Steps

After setting up your icon:

1. ✅ Test on real devices (Android & iOS)
2. ✅ Check different launcher shapes (Android)
3. ✅ Verify splash screen duration
4. ✅ Test on light and dark themes
5. ✅ Prepare for production build

---

## 🚢 Production Build

When ready to publish:

```bash
# Android APK
fvm flutter build apk --release

# Android App Bundle (for Play Store)
fvm flutter build appbundle --release

# iOS (on Mac)
fvm flutter build ios --release
```

---

## 📚 Resources

### Icon Design:

- [Material Design Icon Guidelines](https://m3.material.io/styles/icons)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)

### Free Icon Resources:

- [Flaticon](https://www.flaticon.com) - Free icons
- [Icons8](https://icons8.com) - Icon library
- [Material Icons](https://fonts.google.com/icons) - Google icons

### Tools:

- [Figma](https://figma.com) - Design tool
- [Canva](https://canva.com) - Template-based design
- [App Icon Generator](https://appicon.co) - Online generator

---

## 💡 Tips

1. **Keep it Simple**: Complex icons don't scale well to small sizes
2. **Test Early**: Check your icon on real devices, not just emulators
3. **Brand Consistency**: Match your app's color scheme and style
4. **Accessibility**: Ensure good contrast for visibility
5. **Iterate**: Don't be afraid to refine based on how it looks installed

---

## ✅ Checklist

Before launching:

- [ ] Icon is 1024x1024 PNG
- [ ] Icon placed in `assets/icon/app_icon.png`
- [ ] Ran `./generate_app_assets.sh`
- [ ] Tested on Android device
- [ ] Tested on iOS device (if applicable)
- [ ] Checked different launcher shapes (Android)
- [ ] Verified splash screen appears correctly
- [ ] Icon looks good at small sizes
- [ ] Colors match brand identity
- [ ] Ready for production build

---

## 🆘 Need Help?

If you encounter issues:

1. Check `assets/icon/README.md` for icon requirements
2. Review the troubleshooting section above
3. Ensure all commands ran without errors
4. Try manual command execution
5. Check Flutter/Dart SDK versions

---

**Good luck with your CreditBook app! 🎉**
