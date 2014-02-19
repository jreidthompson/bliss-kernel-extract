#!/bin/bash

# Copyright (C) 2013-2014 Jonathan Vasquez <fearedbliss@funtoo.org>
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

# Make sure we get a fresh output directory
if [ ! -d "${FO}" ]; then
	mkdir ${FO} 
else
	rm -rf ${FO}/*
fi

einfo "[ Starting ]"

cd ${F}

einfo "Packing Kernel..."
tar -cf ${FO}/kernel-${KLV}.tar kernel
pxz ${FO}/kernel-${KLV}.tar

einfo "Packing Modules..."
tar -cf ${FO}/modules-${KLV}.tar modules
pxz ${FO}/modules-${KLV}.tar

einfo "Packing Headers..."
tar -cf ${FO}/headers-${KLV}.tar headers
pxz ${FO}/headers-${KLV}.tar

einfo "[ Complete ]"
