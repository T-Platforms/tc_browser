Build notes
===========

```
Download the build system: git@gitlab.tpl:common/tc_browser.git, branch master.

Sources
-------

The Chromium sources are pulled from git by the build process, with the version
tag provided in config/vars.sh. For archival purposes, the source tarball
chromium-browser_71.0.3578.80.source.tar.xz is available, but it is not used for
building.   

NOTE FOR INCREMENTAL BUILDS:
After the initial fetch of Chromium source, 
gn will not track changes made in some third-party libs' sources. 
Always check the output of `git status` and consider editing paths inside patches.


Rootfs
------

The rootfs was assembled in the following way. We take the current Debian buster
from http://update.t-platforms.ru/dists/debian/buster-new, with the SIMD-enabled
ffmpeg, libjpeg-turbo, libpng and other libraries. It is based on libc 2.27.
Then we add the *-dev deb packages that we present in the Debian 8.6 rootfs used
in the past to build Chromium 57. The packages and the versions changed somewhat
between Debian 8.6 and Debian buster, but most of newer versions of the older
packages were found without problem.  Maybe we do not need all of them, but
having all of the does not hurt.  It is better than discovering build
dependencies one-by-one after each chromium build failure.  The name of the
rootfs tar ball is baikal-rootfs-chromedeps-buster.tar.gz
Untar rootfs to chr/sysroots.

Toolchain
---------

The GCC cross toolchain is taken from FreeElectrons site, the target
was MIPS 32r5, the bleeding edge version, as of January 2019:

mips32r5el--glibc--bleeding-edge-2018.11-1.tar.bz2

Untar toolchains to chr/toolchains. Make symbolic links, so that
mipsel-linux-gnu-gcc and other tools can be found by the Chromium build process.

ln -s  mipsel-buildroot-linux-gnu-addr2line mipsel-linux-gnu-addr2line
ln -s  mipsel-buildroot-linux-gnu-ar mipsel-linux-gnu-ar
ln -s  mipsel-buildroot-linux-gnu-as mipsel-linux-gnu-as
ln -s  toolchain-wrapper mipsel-linux-gnu-c++
ln -s  mipsel-buildroot-linux-gnu-c++.br_real mipsel-linux-gnu-c++.br_real
ln -s  mipsel-buildroot-linux-gnu-c++filt mipsel-linux-gnu-c++filt
ln -s  toolchain-wrapper mipsel-linux-gnu-cc
ln -s  mipsel-buildroot-linux-gnu-cc.br_real mipsel-linux-gnu-cc.br_real
ln -s  toolchain-wrapper mipsel-linux-gnu-cpp
ln -s  mipsel-buildroot-linux-gnu-cpp.br_real mipsel-linux-gnu-cpp.br_real
ln -s  mipsel-buildroot-linux-gnu-elfedit mipsel-linux-gnu-elfedit
ln -s  toolchain-wrapper mipsel-linux-gnu-g++
ln -s  mipsel-buildroot-linux-gnu-g++.br_real mipsel-linux-gnu-g++.br_real
ln -s  toolchain-wrapper mipsel-linux-gnu-gcc
ln -s  toolchain-wrapper mipsel-linux-gnu-gcc-8.2.0
ln -s  mipsel-buildroot-linux-gnu-gcc-8.2.0.br_real mipsel-linux-gnu-gcc-8.2.0.br_real
ln -s  mipsel-buildroot-linux-gnu-gcc-ar mipsel-linux-gnu-gcc-ar
ln -s  mipsel-buildroot-linux-gnu-gcc-nm mipsel-linux-gnu-gcc-nm
ln -s  mipsel-buildroot-linux-gnu-gcc-ranlib mipsel-linux-gnu-gcc-ranlib
ln -s  mipsel-buildroot-linux-gnu-gcc.br_real mipsel-linux-gnu-gcc.br_real
ln -s  mipsel-buildroot-linux-gnu-gcov mipsel-linux-gnu-gcov
ln -s  mipsel-buildroot-linux-gnu-gcov-dump mipsel-linux-gnu-gcov-dump
ln -s  mipsel-buildroot-linux-gnu-gcov-tool mipsel-linux-gnu-gcov-tool
ln -s  mipsel-buildroot-linux-gnu-gdb mipsel-linux-gnu-gdb
ln -s  mipsel-buildroot-linux-gnu-gprof mipsel-linux-gnu-gprof
ln -s  mipsel-buildroot-linux-gnu-ld mipsel-linux-gnu-ld
ln -s  mipsel-buildroot-linux-gnu-ld.bfd mipsel-linux-gnu-ld.bfd
ln -s  mipsel-buildroot-linux-gnu-nm mipsel-linux-gnu-nm
ln -s  mipsel-buildroot-linux-gnu-objcopy mipsel-linux-gnu-objcopy
ln -s  mipsel-buildroot-linux-gnu-objdump mipsel-linux-gnu-objdump
ln -s  mipsel-buildroot-linux-gnu-ranlib mipsel-linux-gnu-ranlib
ln -s  mipsel-buildroot-linux-gnu-readelf mipsel-linux-gnu-readelf
ln -s  mipsel-buildroot-linux-gnu-size mipsel-linux-gnu-size
ln -s  mipsel-buildroot-linux-gnu-strings mipsel-linux-gnu-strings
ln -s  mipsel-buildroot-linux-gnu-strip mipsel-linux-gnu-strip

How to build
------------

It should be noted that the build process always checks out the vanilla version
of the browser sources, then applies the patches from configs/71-gcc8.2, and
finally does the actual build. So, if you want to change something, make a patch
first and put it in the config/71-gcc8.2 dir. There is also an option to do a
"jumbo" build, where a bunch of objects are merged into a single binary. It
saves compilation/linkage time but eats a lot of memory during the build
process.

$ cd docker-chrome
$ ./build.sh 71-gcc8.2 2>&1 | tee /tmp/build.log

If you want to build from inside the docker container, connect to the container
and run buildchrome.sh.  To do incremental builds, you can skip certain stages,
like applying patches or installing additional host packages, if they are
already installed.

For example, to connect to an existing container do:
$ docker ps
$ docker exec -it sad_heisenberg /bin/bash
$ /chr/buildchrome.sh 71-gcc8.2 2>&1 | tee /tmp/build.log

Tar the chromium result:

cd chromium/src/out/71-gcc8.2

tar -I pigz -cf ../chromium-71.0.3578.80-16k-purer5-MIPSr2-gcc8.2.tar.gz  \
--exclude='./obj' --exclude='./gen' --exclude='./clang_x86_v8_mipsel' \
--exclude='./x64'  --exclude='./clang_x86' ./

Installation and usage
----------------------

Untar the tarball to local dir in /home/user.  Set the SUID permissions on the
chrome-sandbox file:

sudo chown root:root chrome-sandbox
sudo chmod 4755 chrome-sandbox

If you do not set the SUID bit, chromium can only be run with --no-sandbox
command option. To make sure the built chromium uses its own environment, use
the option --user-data-dir:

./chrome-wrapper --user-data-dir=~/.ch71

The proxy can only be specifed on the command line:

./chrome-wrapper --proxy-server=IP_ADDRESS:3128

SIMD accelerations
------------------

Chromium has two options for enabling MSA (SIMD) accelerations of mips32r5,
mips_use_msa and libyuv_use_msa.  When any of them is enabled in args.gn,
we get build compilation failures. This is TBD. It shall be possible to use
SIMD within Chromium. It also probably links against its own version of
ffmpeg. Since we know stand-alone ffmpeg can be accelerated, this is
another venue to consider.

Description of modifications to the stock Chromium 71
-----------------------------------------------------

The build process assumes that a set of patches is applied to the vanilla
Chromium sources, downloaded from git.

- buildchrome.patch changes

-- Add libraries that are required for the build process. Pigz is added for
parallel tarball compression. Patchelf utility is added because the build
process burns a different loader into the two resulting binaries, chrome and
chrome-sandbox. The build process uses the one from the cross toolchains by
default, and it has a different name, too. In any case it is better to use
the same loader as the rest of the applications use in the target rootfs.

-- PATH_TO_CHROMIUM_SRC does not changes, no need for the define.

-- Newer chromium versions build against Debian sid, not wheezy. It is just the
name in the Chromium sources. We will use our own Debian buster under that name.

-- Use patchelf to set the loader from our rootfs instead of the one from the
cross toolchain's sysroot (ld-linux-mipsn8.so.1). It would be better to request
this via the linker-time options.

- patch-16K.patch

 This patch is taken from previous Chromium builds

- patch-compiler.patch

 Add build configuration target r5.

- patch-google-util.patch

Some language structures are only recognized by Clang, not by GCC. Since Clang
is the default choice, the community has developed a set of patches that makes
the code compilable by modern GCC versions, too. This is one of the patches,
that is required for our build. Here is the meta bug report that accumulates
such GCC/Clang issues:
https://bugs.chromium.org/p/chromium/issues/detail?id=819294

- patch-icu.patch

Assume double conversion is handled correctly in r5 as well.

- patch-keyring.patch

For some reason, gnome-keyring inclusion leads to build failure. Remove support
for now, we can live without it.

- patch-posix.patch

Need to explicitly specify where to take the crt*.o binaries from, within
rootfs. Just as with ld.so it is better to take them from the actual rootfs,
for conformity.

- patch-v8.patch

Add support structure for r5 targets, but link it to the old MIPS32r2 V8
configuration settings for now.  Otherwise, we get problem either during the
build or while running the browser, do not remember which one.

- patch-webrtc.patch

For now use MIPS32_R2_LE for r5. It leads to some inline assembler optimizations
that work as is for r5. Maybe they could be improved in the future to take
advantage of the r5 features, maybe not.

- args.gn

Instruct to build in the FPXX compatibility mode. Otherwise, the browser will
conflict with the installed SIMD-enabled libraries (libjpeg-turbo and friends).
They use -mfp64 with -mmsa, that triggers FPU emulation for some operations, as
evident from "cat /sys/kernel/debug/mips/fpuemustats/*". This slows down the
browser tremendously. Note that it is not sufficient to build just the browser
with FPXX. ld.so also has to have this mode. Check that LC_ALL=C readelf -a
ld-2.27.so | grep "FP ABI" produces: "FP ABI: Hard float (32-bit CPU, Any FPU)"
target_sysroot and system_libdir definitions are added. These are vars available
in 'gn args --list'.

Chromium tests
--------------

The following JS test sites can be used:
browserbench.org, dromaeo.org (Choose Full Test option), Octane 2 (now retired).

Chromium 71 on MITX-AMD

Chromium can potentially take advantage of the GPU acceleration, if present in
the system. The settings for GPU related features can be viewed and set here:

chrome://gpu
chrome://settings (Advanced/System/Use hardware accel when detected)
chrome://flags (override hardware detection)
Try 2D & 3D accelarations in web applications:
https://developer.mozilla.org/en-US/docs/Web/Demos_of_open_web_technologies
"Demos of open web technologies"

browserbench.org has the test for graphics, motionmark, that gives 6.8 mark
for AMD and 1.3 for SM750.

So far we have not succeeded in using GPU for playing youtube in Chromium.
This is TBD.

Useful external links
---------------------

https://chromium.googlesource.com/chromium/src/+/master/docs/linux_build_instructions.md
https://www.mips.com/products/architectures/mips32-2/
```
