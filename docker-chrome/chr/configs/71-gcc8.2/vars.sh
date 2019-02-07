# Tag/branch/hash to buld chromium from
CHROMIUM_REVISION="71.0.3578.80"

# Path to cross compilation toolchain (inside container)
# By default, cross toolchain gcc 5.4 is used as installed in docker
TOOLCHAIN_NAME="mips32r5el--glibc--bleeding-edge-2018.11-1"

# Path to target sysroot (inside container)
PATH_TO_SYSROOT_DIR="/chr/sysroots/baikal-rootfs-chromedeps-buster/"

