#!/bin/bash

. common.sh

removeWorkDir()
{
	if [ -d $WORK_DIR ]; then
		rm -fr $WORK_DIR
	fi
	return $?
}

createImageDir()
{
	if [ ! -d $IMAGE_DIR ]; then
		mkdir $IMAGE_DIR
	fi
	return $?
}

nightly-linux()
{
	$BUILD_SCRIPT build
	if [ $? -eq 0 ]; then
		cp $TMP_IMAGE_DIR/$IMAGE_NAME $IMAGE_DIR/$IMAGE_NAME_RAW"_nightly-"$BUILD_NUMBER"."$IMAGE_NAME_EXT
	else
		echo "Build failed!"
		exit -1
	fi
}

nightly-uboot()
{
	$BUILD_SCRIPT build-u-boot
	if [ $? -eq 0 ]; then
		cp $TMP_IMAGE_DIR/u-boot.elf $IMAGE_DIR/"ze7000_u-boot_nightly-"$BUILD_NUMBER".elf"
	else
		echo "Build failed!"
		exit -1
	fi
}

nightly()
{
	removeWorkDir
	createImageDir
	$BUILD_SCRIPT init nightly
	if [ $? -eq 0 ]; then
    nightly-uboot
    nightly-linux
	else
		echo "Init failed"
		exit -1
	fi
}

release()
{
	removeWorkDir
	createImageDir
	$BUILD_SCRIPT init release
	if [ $? -eq 0 ]; then
		$BUILD_SCRIPT build
		if [ $? -eq 0 ]; then
			cp $TMP_IMAGE_DIR/$IMAGE_NAME $IMAGE_DIR/$IMAGE_NAME_RAW"_release-"$(date +%Y.%m)"-"$BUILD_NUMBER"."$IMAGE_NAME_EXT
		else
			echo "Build failed!"
			exit -1
		fi
	else
		echo "Init failed"
		exit -1
	fi
}

release-uboot()
{
	removeWorkDir
	createImageDir
	$BUILD_SCRIPT init release
	if [ $? -eq 0 ]; then
		$BUILD_SCRIPT build-u-boot
		if [ $? -eq 0 ]; then
			cp $TMP_IMAGE_DIR/u-boot.elf $IMAGE_DIR/"ze7000_u-boot_release-"$(date +%Y.%m)"-"$BUILD_NUMBER".elf"
		else
			echo "Build failed!"
			exit -1
		fi
	else
		echo "Init failed"
		exit -1
	fi
}

case $1 in
nightly)
	nightly
	;;

release)
	release
	;;

release-uboot)
	release-uboot
	;;
esac
