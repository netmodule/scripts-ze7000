#!/bin/bash

# Create a image file with all partition initialized
# with respective boot.bin and rootfs image
# The output image can than be dumped to an SDCard
# using a dd command
# NetModule AG, 2015, da/se

# Default mount points
ROOTFS_MNT="/mnt/root"
BOOT_MNT="/mnt/boot"

# Default Linux RootFS image name
IMAGE_NAME="./rootfs.tar.bz2"

# Default output image name
SDIMAGE_NAME="linux.sdimg"

# Size in Gigabyte of the output image
DISK_SIZE_GB=2

# Loopback device to use
LOOPBACK_DEVICE="/dev/loop0"

#Change to script directory
execDir=$(pwd)

usage()
{
    programName=$(basename $0)
    echo "usage:  $programName <boot.bin> <image.tar.bz2> <linux.sdimg>"
    echo "  boot.bin:        first boot bin"
    echo "  image.tar.bz2:   Rootfs"
    echo "  linux.sdimg:     Output image name"
}

exitScript()
{
    cd $execDir
    exit $1
}

# Create the partition table for the specified device
# and size
partitionSD()
{
    # Erase the parition table
    dd if=/dev/zero of=$1 bs=1024 count=1
    sleep 1

    # Todo: Why is the cylinder size so important ?
    size=$2
    let newCylinders=size/8225280
    echo "New Cylinders: $newCylinders"

    # Set the geometry
    fdisk $1 <<CYLINDERS_END
x
h
255
s
63
c
$newCylinders
r
w
CYLINDERS_END

    # Create the partitions
    fdisk $1 <<"FDISK_END"
n
p
1

+200M
n
p
2


a
1
t
1
c
t
2
83
w
FDISK_END
}

# Format the partition to appropriate file system
formatPartitions()
{
    mkfs.vfat -s 4 -S 512 -F 32 -n boot "$1"p1
    mkfs.ext4 -F -L root "$1"p2
}

mountSD()
{
    mkdir -p $BOOT_MNT
    mkdir -p "$ROOTFS_MNT"
    mount "$1"p1 $BOOT_MNT
    mount "$1"p2 "$ROOTFS_MNT"
}

umountSD()
{
    umount $BOOT_MNT
    umount "$ROOTFS_MNT"
    rm -r $BOOT_MNT
    rm -r "$ROOTFS_MNT"
}

copyBootBin()
{
    cp $1 $BOOT_MNT/boot.bin
}

untarRoot()
{
    tar -xjf $1 -C "$ROOTFS_MNT"
}

unmountSDDevice()
{
    for device in $1*; do
        umount -l $device &>/dev/null
    done
}

if [ "$1" == "--help" -o "$1" == "-h" ]; then
    usage
    exitScript 0
fi

###
# Testing input arguments
###

bootBin="$execDir/boot.bin"
if [ "$1" != "" ]; then
    bootBin="$1"
fi

if [ ! -e $bootBin ]; then
    echo "Bootbin $bootBin does not exist!"
    exitScript -1
fi

rootfsImage=$IMAGE_NAME
if [ "$2" != "" ]; then
    rootfsImage="$2"
fi

if [ ! -e $rootfsImage ]; then
    echo "Rootfs $rootfsImage does not exist!"
    exitScript -1
fi

sdImage=$SDIMAGE_NAME
if [ "$3" != "" ]; then
    sdImage="$3"
fi

###
# Creating the image
###

#tempFile=$(mktemp)
tempFile="tmp.img"

# Create a temp file to hold the image
rm -fr $tempFile
truncate -s"$DISK_SIZE_GB"G $tempFile
echo "$tempFile created"

# Bind device with the file
losetup $LOOPBACK_DEVICE $tempFile
echo "Loopback device: $LOOPBACK_DEVICE"

# Ensure nothing is mounted
echo "Unmount SD Card"
unmountSDDevice $LOOPBACK_DEVICE

# Create the partition table
echo "Partition and format SD Card"
let size=$DISK_SIZE_GB*1024*1024*1024
partitionSD $LOOPBACK_DEVICE $size

# Detach the main image and export all partitions
# in the image to a device
sudo losetup -d $LOOPBACK_DEVICE
sudo losetup -f --show -P $tempFile

# Format them
formatPartitions $LOOPBACK_DEVICE

# Mount the loopback partitions
echo "Mount SD Card"
mountSD $LOOPBACK_DEVICE

# Copy all relevant files to respective partitions
echo "Copy Boot Bin"
copyBootBin $bootBin
echo "Untar rootfs"
untarRoot $rootfsImage

# Clean-up
echo "Unmount SD Card"
umountSD
losetup -d $LOOPBACK_DEVICE

# Move the tmp file to the successfully created image
mv $tempFile $sdImage

exitScript 0
