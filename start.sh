#!/bin/bash

# Copyright 2013-2015 Jonathan Vasquez <jvasquez1011@gmail.com>
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
einfo "Kernel Directory = ${KP}"
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
mkdir ${HEADERS} ${KERNEL} ${MODULES}

# Copy the System.map before cleaning since after you run a 'make clean'
# the System.map file will be deleted.
einfo "Copying System.map ..."

mkdir ${HEADERS}/${K} && cd ${HEADERS}/${K}
mkdir ${HEADERS}/${K}/arch

cp ${KP}/System.map ${HEADERS}/${K}

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

# Clean the kernel sources directory so that we will have a smaller
# headers package.
einfo "Cleaning kernel sources ..."
make clean > /dev/null 2>&1

# Copying blacklist file
einfo "Copying blacklist file ..."
cp ${FILES}/${BL} ${MODULES}

# Copy all the requires files for the headers
einfo "Creating headers ..."

cp -r ${KP}/{.config,Makefile,Kconfig,Module.symvers,include,scripts} ${HEADERS}/${K}
cp -r ${KP}/arch/x86 ${HEADERS}/${K}/arch/

# Copy all the gathered data back to a safe location so that if you run
# the script again, you won't lose the data.
einfo "Saving files to ${F} ..."

mkdir ${F}
mv ${T}/* ${F}

# Remove the temporary directory.
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

einfo "Packing Kernel..."
tar -cf ${FO}/kernel-${KLV}.tar kernel modules headers
pxz ${FO}/kernel-${KLV}.tar

einfo "Complete!"
