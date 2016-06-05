#!/bin/bash

# Copyright 2013-2016 Jonathan Vasquez <jvasquez1011@gmail.com>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

#### Variables ####

# KP = Kernel Path
# KV = Kernel Version
# KLV = Kernel Version + Local Version (Revision)
# K = Kernel (Linux Prefix (linux-) + Kernel Version + Local Version (Revision)
#
# H = Home
# LV = Local Version (Revision)
#
# T = Temporary Directory
#
# F = Final Directory where kernel files will be placed
# FO = Files where tarballs will be placed
#
# HEADERS = Headers Directory in the Temporary Directory
# KERNEL = Kernel Directory in the Temporary Directory
# MODULES = Modules Directory in the Temporary Directory

# Utility Functions

# Used for displaying information
einfo()
{
        echo -e "\e[1;32m>>>\e[0;m ${@}"
}

# Used for input (questions)
eqst()
{
        echo -en "\e[1;37m>>>\e[0;m ${@}"
}

# Used for warnings
ewarn()
{
        echo -e "\e[1;33m>>>\e[0;m ${@}"
}

# Used for flags
eflag()
{
        echo -e "\e[1;34m>>>\e[0;m ${@}"
}

# Used for options
eopt()
{
        echo -e "\e[1;36m>>\e[0;m ${@}"
}

# Prints empty line
eline()
{
    echo ""
}

# Used for errors
die()
{
        echo -e "\e[1;31m>>>\e[0;m ${@}" && clean_temp_dir && exit
}

# Cleans the temporary directory
clean_temp_dir()
{
    rm -rf "${T}"

    if [[ -d "${T}" ]]; then
        ewarn "Couldn't clean up after ourselves. Please delete the ${T} directory." && exit
    fi
}

# Check to see if a kernel directory was passed as a parameter
check_param()
{
    if [[ -z "${KP}" ]]; then
        die "No kernel directory was passed."
    fi
}

# Check to see if the kernel exists
check_kernel()
{
    # Check to see if the kernel exists
    if [[ ! -d "${KP}" ]]; then
        die "Kernel not found! Exiting!"
    fi
}

create_categories()
{
	mkdir -p ${KERNEL_HEADERS_PERM}/arch ${KERNEL} ${MODULES}
}

do_headers()
{
	einfo "Creating headers ..."

	cp -r ${KP}/{.config,Makefile,Kconfig,Module.symvers,System.map,include,scripts,tools} ${KERNEL_HEADERS_PERM}
	cp -r ${KP}/arch/x86 ${KERNEL_HEADERS_PERM}/arch

	einfo "Cleaning headers ..."
	# Clean the kernel headers manually (We aren't using 'make clean' anymore because
	# then we would need to recompile the sources if we wanted to run this command again.
	# and it also takes a long time to copy the entire kernel source if we wanted to 'make clean'
	# a temporary copy.

	# If we extracted the required directories after a 'make clean', it would yield a headers
	# directory of about 61 MB. This manualy clean yields a headers directory of about 67 MB.
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
}

check_param
check_kernel

# Set 'Home'
H="$(pwd)"

# Kernel Version Individuals
VERSION=$(cat ${KP}/Makefile | grep -E "^VERSION" | cut -d " " -f 3)
PATCHLEVEL=$(cat ${KP}/Makefile | grep -E "^PATCHLEVEL" | cut -d " " -f 3)
SUBLEVEL=$(cat ${KP}/Makefile | grep -E "^SUBLEVEL" | cut -d " " -f 3)
EXTRAVERSION=$(cat ${KP}/Makefile | grep -E "^EXTRAVERSION" | cut -d " " -f 3)

# Kernel Revision (LOCALVERSION)
LV=$(cat ${KP}/.config | grep "CONFIG_LOCALVERSION=" | cut -d '"' -f 2)

# Kernel Version
KV="${VERSION}.${PATCHLEVEL}.${SUBLEVEL}${EXTRAVERSION}"

# Kernel Version + Revision
KLV="${KV}${LV}"

# Kernel Version + Revision + 'linux' prefix
K="linux-${KLV}"

# Temporary Directory
T=`mktemp -d`

# Target Directories
HEADERS="${T}/headers"
KERNEL="${T}/kernel"
MODULES="${T}/modules"

KERNEL_HEADERS_PERM="${HEADERS}/${K}"

# Final Directory (Where the kernel should be saved)
F="${H}/kernels/${K}"

# Directory where tarballs will be placed
FO="${F}/out"
