#!/bin/bash

# Generic build and init script for yocto projects
CONFIG_DIR="./build-conf"
FETCH_URI_FILE="$CONFIG_DIR/fetch-uri"

#Root paths
ROOT_DIR="../"
BUILD_DIR="build"
TMP_IMAGE_DIR="$ROOT_DIR/poky/build/tmp/deploy/images/ze7000-zynq7"
IMAGE_DIR="$ROOT_DIR/images"
TARGET_IMAGE="ze7000-image"

BUILD_SCRIPT="./build.sh"
IMAGE_NAME_RAW="$TARGET_IMAGE-ze7000-zynq7"
IMAGE_NAME_EXT="tar.bz2"
IMAGE_NAME="$IMAGE_NAME_RAW.$IMAGE_NAME_EXT"

# Default build
BUILD_DEFAULT_LIST="ze7000-image virtual/kernel u-boot-zx3"

#Change to script directory
scriptDir=$( dirname "${BASH_SOURCE[0]}")
echo "Change to $scriptDir"
cd $scriptDir
execName="./${0##*/}"

#Get absolute dirs
EXEC_DIR=$(pwd)
cd $ROOT_DIR
ROOT_DIR=$(pwd)
cd - > /dev/null

cd $CONFIG_DIR
CONFIG_DIR=$(pwd)
cd - > /dev/null

firstRepo=$(head -n1 $FETCH_URI_FILE)
repo=${firstRepo%%#*}
dirName=${repo##*/}
WORK_DIR="$ROOT_DIR/$dirName"

# Get additional environment variables
source $CONFIG_DIR/set-env
source $CONFIG_DIR/copy-list
