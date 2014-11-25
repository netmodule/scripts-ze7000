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

nightly()
{
	removeWorkDir
	createImageDir
	$BUILD_SCRIPT init nightly
	if [ $? -eq 0 ]; then
		$BUILD_SCRIPT build
		if [ $? -eq 0 ]; then
			cp $TMP_IMAGE_DIR/$IMAGE_NAME $IMAGE_DIR/$(date +%Y%m%d%H%M%S)_$IMAGE_NAME
		else
			echo "Build failed!"
			exit -1
		fi
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
			cp $TMP_IMAGE_DIR/$IMAGE_NAME $IMAGE_DIR/"RELEASE_"$(date +%Y%m%d%H%M%S)_$IMAGE_NAME
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
esac
