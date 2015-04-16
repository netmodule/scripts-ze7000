#!/bin/bash

# Generic bits for init and build scripts on Yocto projects
# NetModule AG, 2015

# Relative path to the configuration files
CONFIG_DIR="./conf"

# Relative path to the main script
BUILD_SCRIPT="./build.sh"

# Root path. Images and Poky will be sub-folders
ROOT_DIR="../"

# Name of the yocto build directory
BUILD_DIR="build"

# Change to script directory
scriptDir=$( dirname "${BASH_SOURCE[0]}")
echo "Change to $scriptDir"
cd $scriptDir

# Get absolute dirs paths
EXEC_DIR=$(pwd)
ROOT_DIR=$(readlink -f $ROOT_DIR)
CONFIG_DIR=$(readlink -f $CONFIG_DIR)

# Default destination for the target images
IMAGE_DIR="$ROOT_DIR/images"

# Absolute path to the list of repo to clone
FETCH_URI_FILE="$CONFIG_DIR/fetch-uri"

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

# Return the build output image directory of Yocto
getBuildOutputDir()
{
    echo "$WORK_DIR/$BUILD_DIR/tmp/deploy/images/$MACHINE"
}


# Get additional environment variables
source $CONFIG_DIR/init.conf
source $CONFIG_DIR/build.conf
source $CONFIG_DIR/copy.conf
