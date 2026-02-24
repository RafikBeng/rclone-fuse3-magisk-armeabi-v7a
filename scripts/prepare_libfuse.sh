#!/bin/bash
set -e

LIBFUSE_DIR=libfuse
LIBFUSE_COMMIT=f99b7eba4fba7d1a7a8350aab898691acc60ab6f

if [ -d "$LIBFUSE_DIR" ]; then
    echo "[*] libfuse already prepared"
    exit 0
fi

echo "[*] Cloning libfuse..."
git clone https://github.com/libfuse/libfuse.git $LIBFUSE_DIR

cd $LIBFUSE_DIR

echo "[*] Checking out commit $LIBFUSE_COMMIT..."
git checkout $LIBFUSE_COMMIT

echo "[*] Applying Android pthread patches..."

# 1️⃣ Disable pthread_cancel + pthread_setcancelstate
patch -p1 < ../patch-libfuse3/lib-fuse_loop_mt.c.patch


# 2️⃣ Disable cleanup thread cancellation (Android safe)
patch -p1 < ../patch-libfuse3/lib-fuse.c.patch

# Remove librt dependency (Android does not have it)
patch -p1 < ../patch-libfuse3/lib-meson.build.patch
cd ..

echo "[*] libfuse ready."