#!/bin/bash
set -e

ABI=$1
RCLONE_VERSION=$2
SAVE_PATH=$3

case "$ABI" in
arm64-v8a)
    ARCH_URL_PART="armv8a"
    ;;
armeabi-v7a)
    ARCH_URL_PART="armv7a"
    ;;
x86)
    ARCH_URL_PART="x86"
    ;;
x86_64)
    ARCH_URL_PART="x64"
    ;;
*)
    echo "! Unsupported architecture: $ABI"
    exit 1
    ;;
esac

# If you know the fixed version, you can hard-code it directly

FILENAME="rclone-android-21-${ARCH_URL_PART}.gz"
RCLONE_URL="https://beta.rclone.org/${RCLONE_VERSION}/testbuilds/${FILENAME}"

echo "- Downloading rclone: $RCLONE_URL"
TMP_GZ="/tmp/rclone.gz"
curl -L "$RCLONE_URL" -o "$TMP_GZ" || abort "! Download failed"

gunzip -c "$TMP_GZ" > $SAVE_PATH
rm -f "$TMP_GZ"

echo "Download complete 🎉"
