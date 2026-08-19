# App Icon Instructions

## Required Icon

Place your wallet app icon in this directory as `app_icon.png`

### Icon Requirements:

**For Best Results:**
- **Size**: 1024x1024 pixels (minimum)
- **Format**: PNG with transparent background (recommended) or solid background
- **Design**: Simple, clear design that works well at small sizes
- **Safe Area**: Keep important elements within the center 80% of the image

### Icon Specifications by Platform:

#### Android:
- Adaptive icon support (icon appears on various shapes: circle, square, rounded square)
- Minimum size: 512x512 pixels
- Recommended: 1024x1024 pixels
- Format: PNG

#### iOS:
- Rounded corners applied automatically by iOS
- Minimum size: 1024x1024 pixels (App Store requirement)
- Format: PNG without transparency (transparency will be removed)

## After Adding Your Icon:

1. Place your icon file as `app_icon.png` in this directory
2. Run the following commands from the mobile directory:

```bash
# Install dependencies
fvm flutter pub get

# Generate launcher icons
fvm dart run flutter_launcher_icons

# Generate splash screen
fvm dart run flutter_native_splash:create

# Rebuild the app
fvm flutter clean
fvm flutter run
```

## Current Setup:

- **App Icon**: `assets/icon/app_icon.png`
- **Background Color**: White (#FFFFFF)
- **Splash Screen**: Shows your app icon on white background

## Customization:

To change colors, edit the configuration in `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#FFFFFF"  # Change this color

flutter_native_splash:
  color: "#FFFFFF"  # Change this color
  image: assets/icon/app_icon.png
```

## Tips:

1. **Design Guidelines**:
   - Use a wallet or financial icon that represents your brand
   - Keep it simple - complex designs don't scale well to small sizes
   - Ensure good contrast between icon and background
   - Test on both light and dark device backgrounds

2. **Testing**:
   - Test your icon on multiple devices
   - Check how it looks on both Android (different launcher shapes) and iOS
   - View it in different contexts: home screen, app drawer, settings

3. **Tools for Creating Icons**:
   - Figma (with export at 1024x1024)
   - Adobe Illustrator
   - Canva
   - Online icon generators
   - Icon font libraries (Material Icons, Font Awesome)

## Need Help?

If you don't have an icon designer, you can:
1. Use a free icon from flaticon.com or icons8.com
2. Hire a designer on Fiverr or Upwork
3. Use an AI tool like DALL-E or Midjourney
4. Create one using Canva templates
