#!/bin/bash
set -exu

CONFIG_NAME="$1"
CONFIG_DIR="/chr/configs/$CONFIG_NAME"
BUILD_NAME="${2:-$CONFIG_NAME}"
SKIP_APT=

if [ -z "$SKIP_APT" ]; then
	sudo apt update
	sudo apt install -y libatspi2.0-dev
	sudo apt install -y libuuid1:i386
	sudo apt install -y pigz
	sudo apt install -y patchelf
fi

if [ ! -d $CONFIG_DIR ]; then
	echo "Directory \"$CONFIG_DIR\" does not exists!";
	exit 1;
fi

source $CONFIG_DIR/vars.sh
cd /chr/chromium/src

# Checkout necessary revision
git checkout "$CHROMIUM_REVISION" -f
git clean -dff

gclient sync  --with_branch_heads -RDf

# Apply patches
for patchfile in $CONFIG_DIR/*.patch
do
	echo "applying patch $patchfile";
	patch -p1 < "$patchfile";
done

# Make symlink to sysroot
#ln -s $PATH_TO_SYSROOT_DIR build/linux/debian_wheezy_mips-sysroot
ln -s $PATH_TO_SYSROOT_DIR build/linux/debian_sid_mips-sysroot

# Prepare build configuration
OUT_DIR="out/$BUILD_NAME"

if [ -d $OUT_DIR ]; then
	echo "Output directory \"$OUT_DIR\" already exsists. Remove it or rename the build";
	exit 1;
fi

mkdir $OUT_DIR
cp "$CONFIG_DIR/args.gn" $OUT_DIR/args.gn
gn gen "$OUT_DIR"

# Execute config related prebuild actions
if [ -f $CONFIG_DIR/prebuild_hooks.sh ]; then
    source  $CONFIG_DIR/prebuild_hooks.sh
fi

if [ -n "${TOOLCHAIN_NAME}" ]; then
	TOOLCHAIN_PATH=/chr/toolchains/${TOOLCHAIN_NAME}
	if [ -z `ls ${TOOLCHAIN_PATH}/bin/mipsel-linux-gnu-gcc` ]; then
		echo "Toolchain not found in ${TOOLCHAIN_PATH}";
		exit 1;
	fi
# TBD Link for now, otherwise python fails to find some m4 file.
	sudo ln -sf ${TOOLCHAIN_PATH} /opt/${TOOLCHAIN_NAME}
	export PATH="${TOOLCHAIN_PATH}/bin:${PATH}";
fi

# Start build, verbose mode!
ninja -v -C $OUT_DIR chrome chrome_sandbox

# Execute config related postbuild actions
if [ -f $CONFIG_DIR/postbuild_hooks.sh ]; then
    source  $CONFIG_DIR/postbuild_hooks.sh
fi

# Rename chrome_sandbox file
mv $OUT_DIR/chrome_sandbox $OUT_DIR/chrome-sandbox
# TBD There must be a better way to bind binaries to the right loader
# For now, use patchelf
patchelf --set-interpreter /lib/ld.so.1 $OUT_DIR/chrome
patchelf --set-interpreter /lib/ld.so.1 $OUT_DIR/chrome-sandbox
# TBD Consider stripping, maybe
# ${TOOLCHAIN_PATH}/bin/mipsel-linux-gnu-strip $OUT_DIR/chrome
# ${TOOLCHAIN_PATH}/bin/mipsel-linux-gnu-strip $OUT_DIR/chrome-sandbox
