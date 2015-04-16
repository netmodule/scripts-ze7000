#!/bin/bash

# Automate a full project init, build and images storage
# This script is usually called by the Continous Integration server
# NetModule AG, 2015

# Include common stuff and project specific environment
. common.sh


# Init the env, start a nightly build and copy
# the files to the default folder
nightly()
{
  removeWorkDir
  removeImageDir
  createImageDir
  $BUILD_SCRIPT init nightly
  if [ $? -eq 0 ]; then
    $BUILD_SCRIPT build
    if [ $? -eq 0 ]; then
      $BUILD_SCRIPT copy-images
      if [ $? -ne 0 ]; then
        echo "Image(s) copy failed"
        exit -1
      fi
    else
      echo "Build failed!"
      exit -1
    fi
  else
    echo "Init failed"
    exit -1
  fi
}

# Init the env, start a release build and copy
# the files to the default folder
release()
{
  removeWorkDir
  removeImageDir
  createImageDir
  $BUILD_SCRIPT init release
  if [ $? -eq 0 ]; then
    $BUILD_SCRIPT build
    if [ $? -eq 0 ]; then
      $BUILD_SCRIPT copy-images
      if [ $? -ne 0 ]; then
        echo "Image(s) copy failed"
        exit -1
      fi
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

  *)
    echo "usage: $0 {nightly|release}"
    echo $WORK_DIR
    ;;
esac
