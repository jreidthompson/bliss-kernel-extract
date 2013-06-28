#!/bin/bash

# Copyright (C) 2013 Jonathan Vasquez <jvasquez1011@gmail.com>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

. libraries/common.sh

if [ -z "${1}" ]; then
	die "You need to pass the kernel you want"
fi

if [ ! -d "${F}" ]; then
	die "The directory where the files are doesn't exist! Exiting."
fi

mkdir ${FO} && cd ${F}

einfo "Packing Kernel and Modules..."
tar -cf ${FO}/kernel-${KLV}.tar kernel modules
pbzip2 -v ${FO}/kernel-${KLV}.tar

echo "Packing Kernel Headers..."
tar -cf ${FO}/headers-${KLV}.tar headers
pbzip2 -v ${FO}/headers-${KLV}.tar

echo "Packing Kernel Firmware..."
tar -cf ${FO}/firmware-${KLV}.tar firmware
pbzip2 -v ${FO}/firmware-${KLV}.tar
