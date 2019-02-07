
How to build Chromium56 for Linux/Baikal-T (16K page-size)


Build environment
-----------------
Chromium requires cross-compilation on x86 or x86-64 machine. 
At the moment only Ubuntu LTS is directly supported (this readme is applicable for Ubuntu 16.04 LTS). 
For other distros, please refer to Notes in the official Chromium build instruction:
https://chromium.googlesource.com/chromium/src/+/master/docs/linux_build_instructions.md#notes

GNU cross-toolchain is also required and can be installed from repo or from the provided Baikal-SDK as described below. Chromium is known to build with gcc-5.x.

Target system rootfs image is mandatory for successful build.


Setting up the build
--------------------
Create a directory to work with Google projects:

    mkdir <your_path_to>/google-src
    cd <your_path_to>/google-src

Install depot_tools and fetch the code as per the Linux Chromium build instruction (https://chromium.googlesource.com/chromium/src/+/master/docs/linux_build_instructions.md):

    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    export PATH="$PATH:/path/to/depot_tools"

    mkdir chromium && cd chromium
    fetch --nohooks chromium

This is a long process as you need to download about 15GB of sources. Do not use --no-history option, otherwise you will not be able to work with the specific build tags.

Checkout stable Chromium 56 tag (56.0.2924.88), install additional build dependencies and "sync" checkout:

    cd src
    git checkout 56.0.2924.88   
    build/install-build-deps.sh --no-syms --lib32 --no-arm
    apt install g++-5-multilib-mipsel-linux-gnu gcc-5-multilib-mipsel-linux-gnu libc6-dev-mipsel-cross linux-libc-dev-mipsel-cross g++-multilib-mipsel-linux-gnu gcc-multilib-mipsel-linux-gnu
    gclient sync --with_branch_heads

Make sure all previous comands are successfully completed and then apply chromium56-16k patch:

    patch -p1 < /path/to/patch/chromium56.patch

Note that if your build machine is behind the proxy server, you need to setup proxy manually in ~/.boto file, because gsutil from depot_tools cannot use system-wide proxy configuration.

Currently, Chromium56 (and 57) comes with its own Debian Wheezy sysroot image used by default. It is not compatible with Debian Jessie (mipsel) distro (installed on mitx and Tavolga-Terminal) and gives non-working build. Thus, actual Baikal-T/Tavolga rootfs has to be used and it is also provided with this readme. Note that the provided rootfs includes additional packets compared to the original rootfs from mitx/Tavolga-Terminal.
To install a custom sysroot, a bunch of GN config files need to be updated. Instead, we can just put custom rootfs in build/linux/debian_wheezy_mips-sysroot and GN will be fine with that:
    
    mkdir build/linux/debian_wheezy_mips-sysroot # remove dir if it already exists
    cd build/linux/debian_wheezy_mips-sysroot
    tar -xvf /path/to/baikal-rootfs-chromedeps1.tar.gz


Configure GN and run the build
------------------------------
Chromium uses Ninja as its main build tool along with a tool called GN to generate .ninja files. 
To create a build directory, run:

    cd <your_path_to>/google-src/chromium/src
    gn args out/chromium56-16k

And then, put the following GN arguments into your text editor:

    is_clang = false
    is_debug = false
    mips_arch_variant = "r2"
    target_os = "linux"
    target_cpu = "mipsel"
    enable_nacl=false
    is_component_build = false
    linux_use_bundled_binutils = false
    use_gold = false
    remove_webcore_debug_symbols=true
    v8_os_page_size = "16"
    proprietary_codecs = true
    ffmpeg_branding = "Chrome"

Finally, build Chromium (the “chrome” target) with Ninja using the command:

    ninja -C out/chromium56-16k chrome

Now you should have Chromium build in the out/chromium56-16k subdirectory.  If you want your build process to be more verbose, just pass -v flag to ninja.

Now you can delete build files in the directories out/chromium56-16k/obj, out/chromium56-16k/obj.host, out/chromium56-16k/gen, out/chromium56-16k/clang_x86_v8_mipsel, out/chromium56-16k/x64

Copy out/chromium56-16k to the target machine and run:

    <your_install_path>/chrome-wrapper --no-sandbox --user-data-dir=/home/user/chromium56-data


Using different toolchain
-----------------------

Chromium can be built with ordinary cross-compiling toolchain installed via apt-get:
    
    apt install g++-5-multilib-mipsel-linux-gnu gcc-5-multilib-mipsel-linux-gnu libc6-dev-mipsel-cross linux-libc-dev-mipsel-cross g++-multilib-mipsel-linux-gnu gcc-multilib-mipsel-linux-gnu

This command installs gcc 5.4 (make sure that _xenial-updates/universe_ enabled it `/etc/apt/sources.list`). You can verify it using `mipsel-linux-gnu-gcc --version` command.

You can also use your own toolchain.
In order to use your own toolchain (e.g SDK x-tools), make sure that all the cross-tools have prefix *mipsel-linux-gnu-* (e.g. *mipsel-linux-gnu-gcc*, *mipsel-linux-gnu-as*, etc.). If your toolchain have different prefix (e.g SDK *mipsel-unknown-linux-gnu-*) you can create symlinks to them with proper prefix:

    cd <your_toolchain_prefix>/bin
    ln -s ./mipsel-unknown-linux-gnu-gcc ./mipsel-linux-gnu-gcc
    ln -s ./mipsel-unknown-linux-gnu-g++ ./mipsel-linux-gnu-g++
    ln -s ./mipsel-unknown-linux-gnu-as ./mipsel-linux-gnu-as
    # ... repeat symlinking for all tools in your toolchain

add then add cross-tools to your $PATH:

    export PATH="<your_toolchain_prefix>/bin:$PATH"

check that every *mipsel-linux-gnu-* command resolves to your toolchain.

Note, that if your toolchain's linker (*mipsel-linux-gnu-ld*) version is less than `2.26.1` you may encounter a linking problem at the last step of building with errors like this:

    /usr/lib/gcc-cross/mipsel-linux-gnu/5/../../../../mipsel-linux-gnu/bin/ld: BFD (GNU Binutils for Ubuntu) 2.26 assertion fail ../../bfd/elf-strtab.c:199   
    /usr/lib/gcc-cross/mipsel-linux-gnu/5/../../../../mipsel-linux-gnu/bin/ld: BFD (GNU Binutils for Ubuntu) 2.26 assertion fail ../../bfd/elf-strtab.c:199
    /usr/lib/gcc-cross/mipsel-linux-gnu/5/../../../../mipsel-linux-gnu/bin/ld: BFD (GNU Binutils for Ubuntu) 2.26 assertion fail ../../bfd/elf-strtab.c:199

There is a workaround for this problem. Edit *chrome_initial.ninja* file and remove linker's `-Wl,--as-needed` flag:

    cd  <your_path_to>/google-src/chromium/src/out/<your_build_dir>/
    sed -i 's/-Wl,--as-needed//' obj/chrome/chrome_initial.ninja

then continue your build:

    ninja -C out/<your_build_dir> chrome


Building custom sysroot
--------------------------

This readme provided with sysroot (actually rootfs) archive that may be used to build chromium.
You can also make this sysroot manually using steps below:

1. Checkout to desired chromium version:
     
        git checkout 56.0.2924.88

2. Boot target Baikal-T/Tavolga host (where you are planing to launch chromium) and install additional packages
   necessary for building chromium.  You can get the list of all required packages
   in `chromium/src/build/linux/sysroot_scripts/sysroot-creator-jessie.sh` file (they are listed
   as the value of `DEBIAN_PACKAGES` variable).

        apt-get install -y comerr-dev krb5-multidev libasound2 libasound2-dev [and other packages ....]
       
3. Ensure that your rootfs does not contain absolute symlinks. You must replace all absolute symlinks to relative. 
    This can be done, for example, by symlinks tool:
       
        apt-get install symlinks
        symlinks -crv /usr /lib /etc

4. Copy whole rootfs into arbitrary directory on cross-compilation host.

5. Move pkgconfig files:
        
        cd path/to/rootfs
        mv usr/lib/mipsel-linux-gnu/pkgconfig/* usr/lib/pkgconfig/ usr/share/pkgconfig/

6. Some of cross-compile toolchains may not find c/c++ header files and dynamic libraries in directories 
    prefixed with *mipsel-linux-gnu*. You can solve it by moving files:
        
        cd  path/to/rootfs
        rsync -av usr/lib/mipsel-linux-gnu/ usr/lib/
        rsync -av usr/include/mipsel-linux-gnu/ usr/include/

7. Now you have ready sysroot in `<path_to_rootfs>` directory


Building binutils 2.28
--------------------------

If your toolchain have binutils of version less that 2.28 you may get this warnings after linking stage:

```
[1/1] LINK ./chrome
/usr/lib/gcc-cross/mipsel-linux-gnu/5/../../../../mipsel-linux-gnu/bin/ld: obj/v8/v8_base/parser.o: Can't find matching LO16 reloc against `_ZN2v88internal14AstNodeFactory19NewForEachStatementENS0_16ForEachStatement9VisitModeEPNS0_8ZoneListIPKNS0_12AstRawStringEEEi.isra.337' for R_MIPS_GOT16 at 0xab0 in section `.text._ZN2v88internal10ParserBaseINS0_6ParserEE17ParseForStatementEPNS0_8ZoneListIPKNS0_12AstRawStringEEEPb[_ZN2v88internal10ParserBaseINS0_6ParserEE17ParseForStatementEPNS0_8ZoneListIPKNS0_12AstRawStringEEEPb]
```

You can upgrade you binutils to version 2.28 in order to fix this warnings. Currently binutils 2.28 for mips (*binutils-mipsel-linux-gnu*) isn't abailable in official ubuntu 16.04 repositories, so we need to build it manually:

1. Make workdir and clone repo
    
        mkdir build_workdir
        cd build_workdir
    
        git clone git://sourceware.org/git/binutils-gdb.git
        cd binutils-gdb
        git checkout binutils-2_28

2. Configure, make and install

        cd /path/to/build_workdir
        export TARGET=mipsel-unknown-linux-gnu
        export PREFIX="$(pwd)/cross"
        mkdir configdir && cd configdir
        ../binutils-gdb/configure --target=$TARGET --prefix=$PREFIX
        make
        make install

3. Replace old binutils with newly built in `/path/to/build_workdir/cross`. 
   You can find location of current binutils using `mipsel-linux-gnu-gcc -print-search-dirs` command.

