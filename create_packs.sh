#!/bin/bash

if [ -z "${1}" ]; then
	echo "You need to pass the kernel you want" && exit
fi

# K = Kernel
# KP = Kernel Path
# KV = Kernel Version
# H = Home
# TMP = Temporary Directory
H="$(pwd)"
K="${1}"
KP="/usr/src/${K}"

# Kernel Version Individuals
VERSION=$(cat ${KP}/Makefile | grep -E "^VERSION" | cut -d " " -f 3)
PATCHLEVEL=$(cat ${KP}/Makefile | grep -E "^PATCHLEVEL" | cut -d " " -f 3)
SUBLEVEL=$(cat ${KP}/Makefile | grep -E "^SUBLEVEL" | cut -d " " -f 3)

# Kernel Revision (LOCALVERSION)
REV=$(cat ${KP}/.config | grep "CONFIG_LOCALVERSION=" | cut -d '"' -f 2)

# Kernel Version
KV="${VERSION}.${PATCHLEVEL}.${SUBLEVEL}"

# Kernel Version + Revision
KF="${KV}${REV}"

# Kernel Version + Revision + 'linux' prefix
KC="linux-${KF}"

echo "Kernel: ${K}"

cd ${H}/${K}

echo "Packing the kernel and modules together"
tar -cf kernel-${KF}.tar kernel modules
pbzip2 -v kernel-${KF}.tar

echo "Packing the kernel headers"
tar -cf headers-${KF}.tar headers
pbzip2 -v headers-${KF}.tar

echo "Packing the kernel firmware"
tar -cf firmware-${KF}.tar firmware
pbzip2 -v firmware-${KF}.tar
