#!/bin/bash

if [ -z "${1}" ]; then
	echo "You need to pass the kernel you want" && exit
fi

HOME="$(pwd)"
KERNEL="${1}"
KERNEL_PATH="/usr/src/${KERNEL}"
TMPDIR="/tmp/some"
KV="${1#*-}"

# Kernel Version Individuals
VERSION=$(cat ${KERNEL_PATH}/Makefile | grep -E "^VERSION" | cut -d " " -f 3)
PATCHLEVEL=$(cat ${KERNEL_PATH}/Makefile | grep -E "^PATCHLEVEL" | cut -d " " -f 3)
SUBLEVEL=$(cat ${KERNEL_PATH}/Makefile | grep -E "^SUBLEVEL" | cut -d " " -f 3)

# Kernel Revision (LOCALVERSION)
REV=$(cat ${KERNEL_PATH}/.config | grep "CONFIG_LOCALVERSION=" | cut -d '"' -f 2)

# Kernel Version
KV="${VERSION}.${PATCHLEVEL}.${SUBLEVEL}"

# Kernel Version + Revision
KF="${KV}${REV}"

# Kernel Version + Revision + 'linux' prefix
KC="linux-${KF}"

echo "Kernel full is: ${KF}"

echo "Kernel: ${KERNEL}"

echo "Creating Layout..."

# Check to see if the temporary directory exists
if [ -d "${TMPDIR}" ]; then
	rm -rf ${TMPDIR}

	if [ ! -d "${TMPDIR}" ]; then
		mkdir ${TMPDIR}
	fi
else
	mkdir ${TMPDIR}
fi

cd ${TMPDIR}

# Create categories
mkdir kernel modules headers firmware

# Copy the System.map before cleaning since after you run a 'make clean'
# the System.map file will be deleted.
echo "Copying System.map into headers before cleaning..."
cd ${TMPDIR}/headers
mkdir ${KC} && cd ${KC}
mkdir arch

cp ${KERNEL_PATH}/System.map .

# Install the kernel and the modules
echo "Installing Kernel and Modules..."
cd ${KERNEL_PATH}
make modules_install INSTALL_MOD_PATH=${TMPDIR}/modules > /dev/null 2>&1
make install INSTALL_PATH=${TMPDIR}/kernel > /dev/null 2>&1

# Adjust the kernel directory to the root of the modules folder
mv ${TMPDIR}/modules/lib/modules/${KF} ${TMPDIR}/modules/

# Fix kernel modules symlinks
cd ${TMPDIR}/modules/${KF}
rm -v build source
ln -s /usr/src/${KC} build
ln -s /usr/src/${KC} source

echo "Moving firmware to the firmware directory"
mkdir -p ${TMPDIR}/firmware/
mv ${TMPDIR}/modules/lib/firmware/* ${TMPDIR}/firmware/

# Delete the empty lib folder
rm -rf ${TMPDIR}/modules/lib/

# Return back to kernel directory
cd ${KERNEL_PATH}

# Clean the kernel sources directory so that we will have a smaller
# headers package.
echo "Cleaning Kernel Sources"
make clean > /dev/null 2>&1

# Copy all the requires files for the headers
echo "Creating Headers..."
cd ${TMPDIR}/headers/${KC}

cp ${KERNEL_PATH}/.config .
cp -r ${KERNEL_PATH}/Makefile .
cp -r ${KERNEL_PATH}/Module.symvers .
cp -r ${KERNEL_PATH}/arch/x86 arch/
cp -r ${KERNEL_PATH}/include .
cp -r ${KERNEL_PATH}/scripts .

# Copy all the gathered data back to a safe location so that if you run
# the script again, you won't lose the data.
echo "Moving headers back HOME..."

mkdir ${HOME}/${KERNEL}
mv ${TMPDIR}/* ${HOME}/${KERNEL}

# Remove the temporary directory.
echo "Cleaning up..."
rm -rf ${TMPDIR}

if [ -d "${TMPDIR}" ]; then
	echo "Couldn't clean up after ourselves. Please delete the ${TMPDIR} directory."
fi
