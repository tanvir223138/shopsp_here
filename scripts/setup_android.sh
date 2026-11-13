#!/usr/bin/env bash
# One-time setup: generates android/ios folders and adds the INTERNET permission
# (without it the release APK cannot reach the API).
set -e
cd "$(dirname "$0")/.."

if [ ! -d android ]; then
  flutter create . --project-name shopsphere --org com.example
fi

MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  sed -i 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$MANIFEST"
  echo "Added INTERNET permission."
fi
sed -i 's#android:label="[^"]*"#android:label="ShopSphere"#' "$MANIFEST"

flutter pub get
echo "Done. Run: flutter run   |   flutter build apk --release"
