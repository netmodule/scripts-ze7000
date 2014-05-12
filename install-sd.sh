#!/bin/bash

ROOTFS_MNT="/mnt/root"
BOOT_MNT="/mnt/boot"

#Change to script directory
execDir=$(pwd)
scriptDir=$( dirname "${BASH_SOURCE[0]}")
cd $scriptDir
execName="./${0##*/}"

#Get absolute dirs
SCRIPT_DIR=$(pwd)
cd ..
ROOT_DIR=$(pwd)
cd -

#Set absolute image name
IMAGE_NAME="$ROOT_DIR/poky/build/tmp/deploy/images/ze7000-zynq7/ze7000-image-ze7000-zynq7.tar.bz2"

usage()
{
    programName=$(basename $0)
    echo "usage:  $programName <dev> <boot.bin> <image.tar.bz2>"
    echo "  dev:             SD device"
    echo "  boot.bin:        first boot bin"
    echo "  image.tar.bz2:   Rootfs"
}

exitScript()
{
    cd $execDir
    exit $1
}

formatSD()
{
    dd if=/dev/zero of=$1 bs=1024 count=1
    sleep 1
    size=$(fdisk -l |grep "Disk $1:")
    size=${size##*, }
    size=${size%% bytes}
    let newCylinders=size/8225280
    
    echo "New Cylinders: $newCylinders"
    
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
    
    mkfs.vfat -F 32 -n boot "$1"1
    mkfs.ext2 -L root "$1"2
}

mountSD()
{
    mkdir -p $BOOT_MNT
    mkdir -p $ROOTFS_MNT
    mount "$1"1 $BOOT_MNT
    mount "$1"2 $ROOTFS_MNT
}

umountSD()
{
    umount $BOOT_MNT
    umount $ROOTFS_MNT
    rm -r $BOOT_MNT
    rm -r $ROOTFS_MNT
}

copyBootBin()
{
    cp $1 $BOOT_MNT/boot.bin
}

untarRoot()
{
    tar -xjf $1 -C $ROOTFS_MNT
}

if [ "$1" == "--help" -o "$1" == "-h" ]; then
    usage
    exitScript 0
fi

if [ "$1" == "" ]; then
    echo "Please specify a SD device"
    exitScript -1
fi

if [ ! -e $1 ]; then
    echo "Please specify a valid SD device"
    exitScript -1
fi

sdDevice="$1"

bootBin="$execDir/boot.bin"
if [ "$2" != "" ]; then
    bootBin="$2"
fi

if [ ! -e $bootBin ]; then
    echo "Bootbin $bootBin does not exist!"
    exitScript -1
fi

rootfsImage=$IMAGE_NAME
if [ "$3" != "" ]; then
    rootfsImage="$3"    
fi

if [ ! -e $rootfsImage ]; then
    echo "Rootfs $rootfsImage does not exist!"
    exitScript -1
fi

echo "Format SD Card"
formatSD $sdDevice
echo "Mount SD Card"
mountSD $sdDevice
echo "Copy Boot Bin"
copyBootBin $bootBin
echo "Untar rootfs"
untarRoot $rootfsImage
echo "Unmount SD Card"
umountSD

exitScript 0
