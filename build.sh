#!/bin/bash

# Generic build and init script for yocto projects
CONFIG_DIR="./build-conf"
FETCH_URI_FILE="$CONFIG_DIR/fetch-uri"
COPY_LIST_FILE="$CONFIG_DIR/copy-list"
ROOT_DIR="../"
BUILD_DIR="build"
TARGET_IMAGE="example-image"

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

checkWorkDir()
{
    echo "Check if $WORK_DIR exists"
    return $(test -d $WORK_DIR)
}

fetchRepositories()
{
    echo "Fetch repositories..."
    currDir=$(pwd)
    i=0
    while read repo; do
        if [ $i -eq 0 ]; then
            cd $ROOT_DIR
        fi
        
        repoUri=${repo%%#*}
        branchName=${repo##*#}
        if [ "$repoUri" != "" ]; then
            echo "Clone $repoUri"
            git clone $repoUri
            dirName=${repoUri##*/}
            if [ "$branchName" != "" ]; then
                cd $dirName
                git checkout $branchName
                # We have to be in the workdir after the first checkout
                if [ $i -gt 0 ]; then
                    cd ..
                fi
            fi
        fi
        let i=i+1
    done < "$EXEC_DIR/$FETCH_URI_FILE"
    cd $currDir
}

initOpenEmbedded()
{
    echo "Init open embedded"
    cd $WORK_DIR
    echo "Current path: $(pwd)"
    source oe-init-build-env $BUILD_DIR > /dev/null
    return $?
}

copyConfig()
{
    while read copyFile; do
        copyInst=($copyFile)
        src=${copyInst[0]}
        dst=$ROOT_DIR/${copyInst[1]}
        echo "Copy $src to $dst"
        cd $CONFIG_DIR
        cp $src $dst
        if [ $? -ne 0 ]; then
            echo "Can not copy $src to $dst"
            exit -1
        fi
        cd - > /dev/null
    done < "$EXEC_DIR/$COPY_LIST_FILE"
}

updateRepositories()
{   
    i=0
    while read repo; do
        if [ $i -eq 0 ]; then
            cd $ROOT_DIR
        fi
        repoUri=${repo%%#*}
        branchName=${repo##*#}
        dirName=${repoUri##*/}
        if [ "$repoUri" != "" ]; then
            echo "Update $dirName from $repoUri"
            cd $dirName
            #Update the repository
            git pull
            # The first directory is the work directory
            if [ $i -gt 0 ]; then
                cd -
            fi
        fi
                
        let i=i+1
    done < "$EXEC_DIR/$FETCH_URI_FILE"
    cd $currDir
}

case "$1" in
    init)
        checkWorkDir
        if [ $? -eq 0 ]; then
            echo "Work dir $WORK_DIR already exists!"
            echo "Pleas do a clean up before a new init."
            exit -1
        fi
        fetchRepositories
        initOpenEmbedded
        cd $EXEC_DIR
        copyConfig
        ;;
    update)
        updateRepositories
        ;;
    build)
        $0 build-example-image
        ;;
    build-*)
        target=${1#build-}
        checkWorkDir
        if [ $? -ne 0 ]; then
            echo "Work dir $WORK_DIR does not exist!"
            echo "Pleas first do an init"
            exit -1
        fi
        initOpenEmbedded
        if [ $? -ne 0 ]; then
            echo "Could not initialize open embedded"
            exit -1
        fi
        
        bitbake $target
        if [ $? -ne 0]; then
            echo "Bitbake failed"
            exit -1
        fi
        ;;
    *)
        echo "usage: $0 {init|sync|build|toolchain}"
        echo "Example:"
        echo "  $0 init                         - clone and setup environment"
        echo "  $0 update                       - pull changes from git"
        echo "  $0 build                        - build the default image"
        echo "  $0 build-<target-name>          - build the image"
esac
