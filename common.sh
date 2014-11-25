#!/bin/bash

# Generic build and init script for yocto projects
CONFIG_DIR="./build-conf"
FETCH_URI_FILE="$CONFIG_DIR/fetch-uri"
COPY_LIST_FILE="$CONFIG_DIR/copy-list"

#Root paths
ROOT_DIR="../"
BUILD_DIR="build"
TMP_IMAGE_DIR="$ROOT_DIR/poky/build/tmp/deploy/images/ze7000-zynq7"
IMAGE_DIR="$ROOT_DIR/images"
TARGET_IMAGE="ze7000-image"

BUILD_SCRIPT="./build.sh"
IMAGE_NAME="$TARGET_IMAGE-ze7000-zynq7.tar.bz2"

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

source $CONFIG_DIR/set-env
