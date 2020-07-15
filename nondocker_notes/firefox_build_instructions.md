# Building firefox for MIPS

## On host:

Ensure that current user's uid(and gid) equals to 1000

    id 

Make a workdir 

    mkdir firefox_workdir
    cd firefox_workdir

Extract firefox-boundle.tar.gz

    tar -xvf /path/to/firefox-boundle.tar.gz

After that you will have "firefox", "sysroots" and "toolchains" in your firefox_workdir. Launch docker container from firefox_workdir:

    docker run -it -v "`pwd`":/ff comsgn/firefox bash

Now you must get into container's shell


## Inside the container:


cd to repo dir

    cd /ff/firefox

take a look at the current config

    cat mozconfig

take a look at the current revison

    hg id

take a look at applied patches (for details got to https://sources.debian.net/patches/firefox/52.0.2-1/ )

    hg diff

run build

    ./mach build --verbose

after the build finishes create a package:

    PATH="/ff/toolchains/mipsel-gcc4.9-crosstool-ng/mipsel-unknown-linux-gnu/bin/:$PATH" ./mach package

then exit from the container.

    exit

## Finish

Your build is ready. You can find resulting archive in:

    firefox_workdir/firefox/obj-firefox/dist/firefox-52.0a1.en-US.linux-mipsel.tar.bz2

## Some notes:

There ara gcc/g++ wrappers in toolchain. Take a loook at files:

    toolchains/mipsel-gcc4.9-crosstool-ng/bin/gcc-wrapper.sh
    toolchains/mipsel-gcc4.9-crosstool-ng/bin/g++-wrapper.sh

This files are targets for *mipsel-linux-gnu-gcc* and *mipsel-linux-gnu-g++* symlinks
