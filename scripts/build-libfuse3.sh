#!/bin/bash
set -e
# Define supported architectures
declare -A platforms=(
  ["arm64-v8a"]="aarch64-linux-android"
  ["armeabi-v7a"]="armv7a-linux-androideabi"
  ["x86"]="i686-linux-android"
  ["x86_64"]="x86_64-linux-android"
)

# Get the input parameters
abi=$1
API=${2:-28} # If the second argument is not provided, default to 28 (Android 9)

# Check if the provided $abi is valid
if [[ -z "${platforms[$abi]}" ]]; then
  echo "Error: Unsupported ABI '$abi'. Supported ABIs are: ${!platforms[@]}"
  exit 1
fi

# Set the common toolchain path
export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64
export PATH=$TOOLCHAIN/bin:$PATH
export SYSROOT=$TOOLCHAIN/sysroot

# Build libfuse
echo "==============Start $abi (API $API) =============="
echo "Building libfuse for $abi with API level $API..."


# Set architecture-related variables
export TARGET_HOST=${platforms[$abi]}
export CC=$TARGET_HOST$API-clang
export CXX=$TARGET_HOST$API-clang++
export AR=$TOOLCHAIN/bin/llvm-ar
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip

cd libfuse

# Clean up old build directory
rm -rf build
mkdir -p build

# First generate the android_cross_file.txt
cat > android_cross_file.txt << EOF
[binaries]
c = '$CC'
cpp = '$CXX'
ar = '$AR'
strip = '$STRIP'
pkg-config = 'pkg-config'

[properties]
skip_sanity_check = true
sys_root = '$SYSROOT'

[host_machine]
system = 'linux'
cpu_family = '$(if [[ "$abi" == *"arm"* ]]; then echo "arm"; elif [[ "$abi" == *"x86"* ]]; then echo "x86"; fi)'
cpu = '$(if [[ "$abi" == "arm64-v8a" ]]; then echo "aarch64"; elif [[ "$abi" == "armeabi-v7a" ]]; then echo "armv7a"; elif [[ "$abi" == "x86" ]]; then echo "i686"; else echo "x86_64"; fi)'
endian = 'little'

[target_machine]
system = 'android'
cpu_family = '$(if [[ "$abi" == *"arm"* ]]; then echo "arm"; elif [[ "$abi" == *"x86"* ]]; then echo "x86"; fi)'
cpu = '$(if [[ "$abi" == "arm64-v8a" ]]; then echo "aarch64"; elif [[ "$abi" == "armeabi-v7a" ]]; then echo "armv7a"; elif [[ "$abi" == "x86" ]]; then echo "i686"; else echo "x86_64"; fi)'
endian = 'little'
EOF

# Then use meson to configure the build
meson setup build\
  --cross-file=android_cross_file.txt \
  -Dutils=true \
  -Dexamples=false \
  -Dtests=false \
  -Ddisable-mtab=true \
  -Dbuildtype=release \
  --default-library=static

# Compile and install using ninja
ninja -C build

cd ..
echo "==============Finished $abi (API $API) =============="
