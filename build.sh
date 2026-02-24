#!/bin/bash
set -e
# 🔥 Prepare libfuse automatically
./scripts/prepare_libfuse.sh
# 获取传入的参数
ABI=$1
TAG_NAME=${TAG_NAME:-$2}

# 从 magisk-rclone/module.prop 文件中读取 RCLONE_VERSION
RCLONE_VERSION=$(grep -oP '^version=\Kv.*' magisk-rclone/module.prop)
VERSION_CODE=$(grep -oP '^versionCode=\K.*' magisk-rclone/module.prop)

# 复制目录并准备环境
cp magisk-rclone magisk-rclone_$ABI -r

./scripts/download-rclone.sh $ABI $RCLONE_VERSION magisk-rclone_$ABI/system/vendor/bin/rclone

./scripts/build-libfuse3.sh $ABI
cp libfuse/build/util/fusermount3 magisk-rclone_$ABI/system/vendor/bin/
chmod +x magisk-rclone_$ABI/system/vendor/bin/*

# 修改 module.prop 中的 updateJson 字段
UPDATE_JSON_URL="https://github.com/NewFuture/rclone-fuse3-magisk/releases/latest/download/update-$ABI.json"
sed -i "s|^updateJson=.*|updateJson=$UPDATE_JSON_URL|" magisk-rclone_$ABI/module.prop

# 生成对应的 update.json 文件
cat <<EOF > update-$ABI.json
{
  "version": "$RCLONE_VERSION",
  "versionCode": $VERSION_CODE,
  "zipUrl": "https://github.com/NewFuture/rclone-fuse3-magisk/releases/download/$TAG_NAME/magisk-rclone_$ABI.zip",
  "changelog": "https://github.com/NewFuture/rclone-fuse3-magisk/releases/tag/$TAG_NAME"
}
EOF

echo "生成的 update.json 文件: update-$ABI.json"

# 打包 ZIP 文件
cd magisk-rclone_$ABI
mkdir -p META-INF/com/google/android
echo "#MAGISK" > META-INF/com/google/android/updater-script
wget https://raw.githubusercontent.com/topjohnwu/Magisk/refs/heads/master/scripts/module_installer.sh -O META-INF/com/google/android/update-binary
chmod +x META-INF/com/google/android/update-binary



ZIP_NAME="magisk-rclone_$ABI.zip"
zip -r9 ../$ZIP_NAME .
cd ..

echo "打包完成: $ZIP_NAME"
