#!/bin/bash

# Copyright 2013-2016 Jonathan Vasquez <jvasquez1011@gmail.com>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Set kernel path
KP=$1

. libraries/common.sh

#### Start of Script ####

# Let's first check to see if our final directory exists.
# If we don't do this here, then we will end up wiping the kernel
# directory stuff when we are cleaning it up, and at the end it will
# fail since we can't save any of it.
if [[ -d "${F}" ]]; then
    die "The final output directory already exists: \n${F} \nPlease remove it if you want to re-use this directory."
fi

einfo "Kernel = ${K}"
einfo "Kernel directory = ${KP}"
einfo "Creating layout ..."

# Check to see if the temporary directory exists
if [[ -d "${T}" ]]; then
    rm -rf ${T}

    if [[ ! -d "${T}" ]]; then
        mkdir ${T}
    fi
else
    mkdir ${T}
fi

# Let's start at the Temporary Directory
cd ${T}

# Create categories
KERNEL_HEADERS_PERM="${HEADERS}/${K}"
mkdir -p ${KERNEL_HEADERS_PERM}/arch ${KERNEL} ${MODULES}

# Install the kernel and the modules
einfo "Installing kernel and modules ..."

# Change into kernel path so that we can run the [modules_]install commands.
cd ${KP}

make modules_install INSTALL_MOD_PATH=${MODULES} > /dev/null 2>&1
make install INSTALL_PATH=${KERNEL} > /dev/null 2>&1

# Adjust the kernel directory to the root of the modules folder
mv ${MODULES}/lib/modules/${KLV} ${MODULES}

# Fix kernel modules symlinks
cd ${MODULES}/${KLV}

rm build source
ln -s /usr/src/${K} build
ln -s /usr/src/${K} source

# Delete the empty lib folder
rm -rf ${MODULES}/lib/

# Return back to kernel directory
cd ${KP}

# Copy all the requires files for the headers
einfo "Creating headers ..."

cp -r ${KP}/{.config,Makefile,Kconfig,Module.symvers,System.map,include,scripts} ${KERNEL_HEADERS_PERM}
cp -r ${KP}/arch/x86 ${KERNEL_HEADERS_PERM}/arch

einfo "Cleaning headers ..."
# Clean the kernel headers manually (We aren't using 'make clean' anymore because
# then we would need to recompile the sources if we wanted to run this command again.

# A 'make clean' would yield a headers directory of about 61 MB.
# This manualy clean yields a headers directory of about 67 MB.
# So we are getting about 90% of the garbage. Good enough.

# This saves about 54.7 MB
rm ${KERNEL_HEADERS_PERM}/arch/x86/boot/{setup.elf,bzImage,vmlinux.bin}
rm ${KERNEL_HEADERS_PERM}/arch/x86/boot/compressed/{piggy.o,vmlinux,vmlinux.bin*}

# This saves about 1.9 MB
rm ${KERNEL_HEADERS_PERM}/arch/x86/kernel/built-in.o

# This saves about 1.4 MB
rm -rf ${KERNEL_HEADERS_PERM}/include/dt-bindings

# Remove 'mconf' since it links to ncurses and it seems we don't actually need it
# for compiling out of tree kernel modules. This link becomes broken when we upgrade
# to a new ncurses version and causes Portage's 'emerge @preserved-rebuild' message
# to appear.
rm ${KERNEL_HEADERS_PERM}/scripts/kconfig/mconf

# Copy all the gathered data back to a safe location so that if you run
# the script again, you won't lose the data.
einfo "Saving files to ${F} ..."

mkdir ${F}
mv ${T}/* ${F}

# Remove the temporary directory.
einfo "Cleaning temporary directory ..."
clean_temp_dir

# Pack and Let's go home!
if [[ ! -d "${F}" ]]; then
    die "The directory where the files are doesn't exist! Exiting."
fi

# Make sure we get a fresh output directory
if [[ ! -d "${FO}" ]]; then
    mkdir ${FO}
else
    rm -rf ${FO}/*
fi

cd ${F}

einfo "Packing kernel..."
tar -cf ${FO}/kernel-${KLV}.tar kernel modules headers
pxz ${FO}/kernel-${KLV}.tar

einfo "Complete!"
