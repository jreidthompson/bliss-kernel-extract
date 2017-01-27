#!/bin/bash

# Copyright 2013-2017 Jonathan Vasquez <jon@xyinn.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
