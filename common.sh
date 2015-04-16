#!/bin/bash

# Generic bits for init and build scripts on Yocto projects
# NetModule AG, 2015

# Location of the scripts configuration
CONFIG_DIR="./build-conf"
FETCH_URI_FILE="$CONFIG_DIR/fetch-uri"

#Root paths
ROOT_DIR="../"
BUILD_DIR="build"
TMP_IMAGE_DIR="$ROOT_DIR/poky/build/tmp/deploy/images/ze7000-zynq7"
IMAGE_DIR="$ROOT_DIR/images"

BUILD_SCRIPT="./build.sh"

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

# Working dir is the first repository folder, in the RootDir
firstRepo=$(head -n1 $FETCH_URI_FILE)
repo=${firstRepo%%#*}
dirName=${repo##*/}
WORK_DIR="$ROOT_DIR/$dirName"

# Create Poky directory
removeWorkDir()
{
  if [ -d $WORK_DIR ]; then
    rm -fr $WORK_DIR
  fi
  return $?
}

# Check if Poky directory still exits or not
checkWorkDir()
{
    echo "Check if $WORK_DIR exists"
    return $(test -d $WORK_DIR)
}

# Delete the image destination folder
removeImageDir()
{
  if [ -d $IMAGE_DIR ]; then
    rm -fr  $IMAGE_DIR
  fi
  return $?
}

# Create the image destination folder
createImageDir()
{
  if [ ! -d $IMAGE_DIR ]; then
    mkdir $IMAGE_DIR
  fi
  return $?
}


# Get additional environment variables
source $CONFIG_DIR/init.conf
source $CONFIG_DIR/build.conf
source $CONFIG_DIR/copy.conf
