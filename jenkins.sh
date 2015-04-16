#!/bin/bash

. common.sh

removeWorkDir()
{
  if [ -d $WORK_DIR ]; then
    rm -fr $WORK_DIR
  fi
  return $?
}

removeImageDir()
{
  if [ -d $IMAGE_DIR ]; then
    rm -fr  $IMAGE_DIR
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

# Init the env, start a nightly build and copy the files to the default folder
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

release()
{
  removeWorkDir
  removeImageDir
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
  removeImageDir
  createImageDir
  $BUILD_SCRIPT init release
  if [ $? -eq 0 ]; then
    $BUILD_SCRIPT build-u-boot-zx3
    if [ $? -eq 0 ]; then
      cp $TMP_IMAGE_DIR/u-boot.elf $IMAGE_DIR/"u-boot_ze7000_release-"$(date +%Y.%m)"-"$BUILD_NUMBER".elf"
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
