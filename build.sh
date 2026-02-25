#!/bin/bash
set -e
# 🔥 Prepare libfuse automatically
./scripts/prepare_libfuse.sh
# Get the input parameters
ABI=$1
TAG_NAME=${TAG_NAME:-$2}

# Read RCLONE_VERSION from magisk-rclone/module.prop
RCLONE_VERSION=$(grep -oP '^version=\Kv.*' magisk-rclone/module.prop)
VERSION_CODE=$(grep -oP '^versionCode=\K.*' magisk-rclone/module.prop)

# Copy directory and prepare environment
cp magisk-rclone magisk-rclone_$ABI -r

./scripts/download-rclone.sh $ABI $RCLONE_VERSION magisk-rclone_$ABI/system/vendor/bin/rclone

./scripts/build-libfuse3.sh $ABI
cp libfuse/build/util/fusermount3 magisk-rclone_$ABI/system/vendor/bin/
chmod +x magisk-rclone_$ABI/system/vendor/bin/*

# Update the updateJson field in module.prop
UPDATE_JSON_URL="https://github.com/RafikBeng/rclone-fuse3-magisk-armeabi-v7a/releases/latest/download/update-$ABI.json"
sed -i "s|^updateJson=.*|updateJson=$UPDATE_JSON_URL|" magisk-rclone_$ABI/module.prop

# Generate the corresponding update.json file
cat <<EOF > update-$ABI.json
{
  "version": "$RCLONE_VERSION",
  "versionCode": $VERSION_CODE,
  "zipUrl": "https://github.com/RafikBeng/rclone-fuse3-magisk-armeabi-v7a/releases/download/$TAG_NAME/magisk-rclone_$ABI.zip",
  "changelog": "https://github.com/RafikBeng/rclone-fuse3-magisk-armeabi-v7a/releases/tag/$TAG_NAME"
}
EOF

echo "Generated update.json file: update-$ABI.json"

# Package ZIP file
cd magisk-rclone_$ABI
mkdir -p META-INF/com/google/android
echo "#MAGISK" > META-INF/com/google/android/updater-script
wget https://raw.githubusercontent.com/topjohnwu/Magisk/refs/heads/master/scripts/module_installer.sh -O META-INF/com/google/android/update-binary
chmod +x META-INF/com/google/android/update-binary



ZIP_NAME="magisk-rclone_$ABI.zip"
zip -r9 ../$ZIP_NAME .
cd ..

echo "Packaging complete: $ZIP_NAME"
