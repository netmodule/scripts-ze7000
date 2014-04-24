#!/bin/bash

# Generic build and init script for yocto projects
CONFIG_DIR="./build-conf"
FETCH_URI_FILE="$CONFIG_DIR/fetch-uri"
COPY_LIST_FILE="$CONFIG_DIR/copy-list"
ROOT_DIR="../"
BUILD_DIR="build"
TMP_IMAGE_DIR="$ROOT_DIR/poky/build/tmp/deploy/images/zynq-ze7000"
IMAGE_DIR="$ROOT_DIR/images"
TARGET_IMAGE="example-image"

#Change to script directory
execDir=$(pwd)

scriptDir=$( dirname "${BASH_SOURCE[0]}")
echo "Change to $scriptDir"
cd $scriptDir

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

exitScript()
{
    cd $execDir
    exit $1
}

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

replaceVariables()
{
    file=$1
    echo "Replace variables in file $file"
    # Make workdir sed usable remove / with \/
    workDir="${WORK_DIR//\//\\/}"
    echo $file
    sed -i "s/\\!{WORK_DIR}\\!/$workDir/g" $file
}

copyConfig()
{
    while read copyFile; do
        if [ "$copyFile" == "" ]; then
            continue
        fi
             
        copyInst=($copyFile)
        src=${copyInst[0]}
        dst=$ROOT_DIR/${copyInst[1]}
        echo "Copy $src to $dst"
        cd $CONFIG_DIR
        cp $src $dst
        if [ $? -ne 0 ]; then
            echo "Can not copy $src to $dst"
            exitScript -1
        fi
        replaceVariables $dst
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

cleanTmp()
{
    echo "Clean up old builds"
    currentDir=$(pwd)
    cd $WORK_DIR/$BUILD_DIR
    rm -rf ./cache ./sstate-cache ./tmp ./bitbake.lock
    cd $currentDir
}


case "$1" in
    init)
        checkWorkDir
        if [ $? -eq 0 ]; then
            echo "Work dir $WORK_DIR already exists!"
            echo "Pleas do a clean up before a new init."
            exitScript -1
        fi
        fetchRepositories
        initOpenEmbedded
        if [ $? -ne 0 ]; then
            echo "Could not initialize open embedded"
            exitScript -1
        fi
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
            exitScript -1
        fi
        initOpenEmbedded
        if [ $? -ne 0 ]; then
            echo "Could not initialize open embedded"
            exitScript -1
        fi
        
        bitbake $target
        if [ $? -ne 0 ]; then
            echo "Bitbake failed"
            exitScript -1
        fi
        ;;
    jenkins-nightly)
        checkWorkDir
        if [ $? -ne 0 ]; then
            $0 init
            if [ $? -ne 0 ]; then
                echo "Could not initialize the build system!"
                exitScript -1
            fi
        else
            $0 update
            cleanTmp
        fi
        
        $0 build
        if [ $? -ne 0 ]; then
            echo "Jenkins build failed!"
            exitScript -1
        fi
        
        if [ ! -e $IMAGE_DIR ]; then
            mkdir -p $IMAGE_DIR
        fi
        cp $TMP_IMAGE_DIR/* $IMAGE_DIR
        
        ;;
    *)
        echo "usage: $0 {init|sync|build|toolchain}"
        echo "Example:"
        echo "  $0 init                         - clone and setup environment"
        echo "  $0 update                       - pull changes from git"
        echo "  $0 build                        - build the default image"
        echo "  $0 build-<target-name>          - build the image"
    esac
    
exitScript 0
