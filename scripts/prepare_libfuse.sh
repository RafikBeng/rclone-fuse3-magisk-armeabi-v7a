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

echo "[*] Applying Android patches..."

patch -p1 < ../patches/android_no_pthread_cancel.patch
patch -p1 < ../patches/android_disable_cleanup_cancel.patch

cd ..

echo "[*] libfuse ready."