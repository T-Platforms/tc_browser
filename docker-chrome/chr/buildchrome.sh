#!/bin/bash
set -exu

CONFIG_NAME="$1"
CONFIG_DIR="/chr/configs/$CONFIG_NAME"
BUILD_NAME="${2:-$CONFIG_NAME}"

if [ ! -d $CONFIG_DIR ]; then
	echo "Directory \"$CONFIG_DIR\" does not exists!";
	exit 1;
fi

source $CONFIG_DIR/vars.sh
cd $PATH_TO_CHROMIUM_SRC_DIR

if [ -n "$PATH_TO_TOOCHAIN_BIN_DIR" ]; then
	if [ -z `ls $PATH_TO_TOOCHAIN_BIN_DIR/mipsel-linux-gnu-gcc` ]; then
		echo "Toolchain not found in $PATH_TO_TOOCHAIN_BIN_DIR";
		exit 1;
	fi
	export PATH="$PATH_TO_TOOCHAIN_BIN_DIR:${PATH}";
fi

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
ln -s $PATH_TO_SYSROOT_DIR build/linux/debian_wheezy_mips-sysroot

# Prepare build configuration
OUT_DIR="out/$BUILD_NAME"

if [ -d $OUT_DIR ]; then
	echo "Output directory \"$OUT_DIR\" already exsists. Remove it or rename the build";
	exit 1;
fi

mkdir $OUT_DIR
cp "$CONFIG_DIR/args.gn" $OUT_DIR/args.gn
gn gen "$OUT_DIR"

if [ -f $CONFIG_DIR/prebuild_hooks.sh ]; then
    source  $CONFIG_DIR/prebuild_hooks.sh
fi

# Start build
ninja -C $OUT_DIR chrome chrome_sandbox
