# Launcher Icons

This directory should contain your launcher icon files.

## How to create the icons:

1. **Convert your SVG to PNG:**
   - Go to https://convertio.co/svg-png/ or https://cloudconvert.com/svg-to-png
   - Upload your `assets/svgs/nexton.svg` file
   - Convert to 1024x1024 PNG
   - Download and save as `assets/icon/nexton.png`

2. **Alternative - Using an online icon generator:**
   - Go to https://appicon.co/
   - Upload your PNG
   - Generate for iOS and Android
   - Download and extract the files
   - Copy the generated icons to the appropriate platform directories

3. **Once you have `nexton.png`:**
   ```bash
   # Generate launcher icons
   dart run flutter_launcher_icons
   ```

## Color Information:
- Background color: #08123A (the app's primary color)