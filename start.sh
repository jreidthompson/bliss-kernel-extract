#!/bin/bash

# Copyright 2013-2017 Jonathan Vasquez <jon@xyinn.org>
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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

# Create categories (base layout)
create_categories

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

# Copy and Clean Headers
do_headers

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
