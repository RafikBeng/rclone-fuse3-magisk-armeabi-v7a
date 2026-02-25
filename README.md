
# Rclone Magisk Module (FUSE 3.17.x Android Build)

This Magisk module integrates **Rclone with FUSE 3.17.x** into Android, allowing remote storage to be mounted as local directories.

Originally based on upstream libfuse, this project includes Android-specific patches required to build and run libfuse successfully using Android NDK.

---

## Overview

This module provides:

- Rclone binary
- Patched libfuse3 for Android
- Boot-time auto mounting
- Web GUI support
- Sync automation
- Magisk integration

It enables seamless mounting of cloud storage on Android devices.

---

# What Was Modified for Android

Android uses **Bionic libc**, which differs from glibc.  
Upstream libfuse depends on features not fully supported on Android.

We used this exact libfuse commit:

f99b7eba4fba7d1a7a8350aab898691acc60ab6f

The following patches were applied:

---

## 1️⃣ Removed librt Dependency

Original (lib/meson.build):

    deps += cc.find_library('rt')

Android does not provide librt.

Patched to:

    #deps += cc.find_library('rt')

Applied automatically in:

    scripts/prepare_libfuse.sh

---

## 2️⃣ Disabled pthread Cancellation (Android Incompatible)

Android does not safely support:

- pthread_cancel
- pthread_setcancelstate

### fuse_loop_mt.c Patch

Injected at top of file:

    #ifdef __ANDROID__
    #define pthread_setcancelstate(a,b) ((void)0)
    #define pthread_cancel(a) ((void)0)
    #endif

---

### fuse.c Patch

Original:

    void fuse_stop_cleanup_thread(struct fuse *f)
    {
        if (lru_enabled(f)) {
            pthread_mutex_lock(&f->lock);
            pthread_cancel(f->prune_thread);
            pthread_mutex_unlock(&f->lock);
            pthread_join(f->prune_thread, NULL);
        }
    }

Patched:

    void fuse_stop_cleanup_thread(struct fuse *f)
    {
    #ifdef __ANDROID__
        (void)f;
        return;
    #else
        if (lru_enabled(f)) {
            pthread_mutex_lock(&f->lock);
            pthread_cancel(f->prune_thread);
            pthread_mutex_unlock(&f->lock);
            pthread_join(f->prune_thread, NULL);
        }
    #endif
    }

This prevents crashes caused by unsupported thread cancellation.

---

# Build Requirements

- Linux or WSL
- Android NDK (r26+ recommended)
- Meson
- Ninja
- Git
- Clang (from NDK)

---

# Build Process

Clean build:

    rm -rf libfuse
    ./build.sh armeabi-v7a v1.73.1

The build script:

1. Clones libfuse
2. Checks out required commit
3. Applies Android patches
4. Cross-compiles using NDK
5. Packages Magisk module

---

# Configuration Paths

    /data/adb/modules/rclone/conf/rclone.conf
    /data/adb/modules/rclone/conf/env
    /data/adb/modules/rclone/conf/htpasswd
    /data/adb/modules/rclone/conf/sync

---

# Included Scripts

### rclone-config

Launch rclone configuration:

    rclone-config

---

### rclone-web

Start Web GUI:

    rclone-web --rc-addr :8080

---

### rclone-sync

Run sync jobs:

    rclone-sync remote:/path /local/path [options]

---

### rclone-kill-all

Unmount and stop all rclone processes:

    rclone-kill-all

---

# Sync Configuration Format

File:

    /data/adb/modules/rclone/conf/sync

Format:

    <remote>:<remote_path> <local_path> [options]

Example:

    gdrive:/Documents "/sdcard/My Documents"
    onedrive:/Photos "/sdcard/Photos" --delete-excluded
    mybox:/Backup "/data/backup" --dry-run

Notes:

- Use quotes for paths containing spaces
- Lines starting with # are ignored
- Logs stored at /data/local/tmp/rclone_sync.log

---

# Current Architecture Support

- armeabi-v7a

---

# License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

# Author

patch by RafikBeng for armeabi-v7a from the original project https://github.com/NewFuture/rclone-fuse3-magisk.
