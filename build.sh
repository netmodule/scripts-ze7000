#!/bin/bash

# Provide a abstraction for the common init, build and copy tasks
# executed on daily base by developpers.
# This script is usually called some developper or a "one-click"
# continous integration script

# NetModule AG, 2015

# Include common stuff and project specific environment
. common.sh

# Exit the script with the specified return value
# and jump back to the scripts folder
exitScript()
{
    cd $EXEC_DIR
    exit $1
}


# Load the open-embedded shell environment and jump in the
# build directory
initOpenEmbedded()
{
    echo "Init open embedded"
    cd $WORK_DIR
    echo "Current path: $(pwd)"
    source oe-init-build-env $BUILD_DIR > /dev/null
    return $?
}

# Copy the files list specified in the configuration
# to a destination passed by parameter
copyImages()
{
  # Get files to copy from the configuration
  FILES=$COPY_LIST
  SRC=$(getBuildOutputDir)
  DEST=$1

  # Copy the files
  for file in $FILES
  do
    cp $SRC/$file $DEST
  done
}

# Copy the manifest of image specified in the configuration
# to a destination passed by parameter
copyImagesManifest()
{
    # Get revelvant images listfrom the configuration
    FILES=$COPY_MANIFEST_LIST
    IMG_PATH=$(getBuildOutputDir)
    DEST=$1

    # Copy the files
    for file in $FILES
    do
        img="$IMG_PATH/$file"
        timestamp=$(readlink $img | cut -d '.' -f 1 | awk -F "-" '{print $NF}')
        name=$(echo $file | cut -d'.' -f1)
        manifest="$WORK_DIR/$BUILD_DIR/tmp/deploy/licenses/$name-$timestamp/license.manifest"
        echo "Copy $manifest to $DEST/$name.manifest ..."
        cp "$manifest" "$DEST/$name.manifest"
    done
}

# Fetch all repositories listed in conf/fetch-uri
# The first repo, usually poky, will be the containing
# directory for the other one.
fetchRepositories()
{
    # Nightly or release build
    buildType=$1

    echo "Fetch repositories..."
    currDir=$(pwd)
    i=0
    while read repo; do
        if [ $i -eq 0 ]; then
            cd $ROOT_DIR
        fi

        repoUri=$(echo $repo | cut -d '#' -f 1)
        if [ "$repoUri" != "" ]; then
            echo "Clone $repoUri"
            git clone $repoUri
            dirName=${repoUri##*/}
            dirName=${dirName%%.git}
            if [ "$buildType" == "release" ]; then
                branchName=$(echo $repo | cut -d '#' -f 3)
            else
                branchName=$(echo $repo | cut -d '#' -f 2)
            fi
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
    done < "$FETCH_URI_FILE"
    cd $currDir
}

# Update the existing repository list
updateRepositories()
{   
    currDir=$(pwd)
    i=0
    while read repo; do
        if [ $i -eq 0 ]; then
            cd $ROOT_DIR
        fi
        repoUri=${repo%%#*}
        branchName=${repo##*#}
        dirName=${repoUri##*/}
        dirName=${dirName%%.git}
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
    done < "$FETCH_URI_FILE"
    cd $currDir
}

# Print out meta-layers name, URI and commit hash
getLayerVersions()
{    
    currDir=$(pwd)
    i=0
    while read repo; do
        if [ $i -eq 0 ]; then
            cd $ROOT_DIR
        fi
        repoUri=${repo%%#*}
        branchName=${repo##*#}
        dirName=${repoUri##*/}
        dirName=${dirName%%.git}
        if [ "$repoUri" != "" ]; then
            cd $dirName
            #Update the repository
            fetchURL=$(git remote show origin |grep "Fetch URL:")
            fetchURL=${fetchURL##*Fetch URL: }
            revision=$(git rev-parse HEAD)
            echo "$dirName: $fetchURL $revision"
            # The first directory is the work directory
            if [ $i -gt 0 ]; then
                cd - > /dev/null
            fi
        fi

        let i=i+1
    done < "$FETCH_URI_FILE"
    cd $currDir
}

# Delete Yocto build output, but keep the configuration
cleanTmp()
{
    currDir=$(pwd)
    echo "Clean up old builds"
    cd $WORK_DIR/$BUILD_DIR
    rm -rf ./cache ./sstate-cache ./tmp ./bitbake.lock
    cd $currDir
}

# Get all AUTO_REV version in all layers
getSrcrevs()
{
    # Just return all AUTO_REVs if called without args
    buildhistory-collect-srcrevs
}

# Save the Yocto configuration to the images / artifact folder
backupYoctoConfiguration()
{
    OUTPUT_LOCAL_CONF="$IMAGE_DIR/local.conf"
    cp $WORK_DIR/$BUILD_DIR/conf/local.conf $OUTPUT_LOCAL_CONF

    # Freeze the versions
    getSrcrevs >> $OUTPUT_LOCAL_CONF
}

case "$1" in
    init)

        # Work dir will be created by the first checkout
        checkWorkDir
        if [ $? -eq 0 ]; then
            echo "Work dir $WORK_DIR already exists!"
            echo "Please do a clean up before a new init."
            exitScript -1
        fi

        # Create the default image destination
        createImageDir

        # Fetch repos and initialize Poky
        fetchRepositories $2
        initOpenEmbedded
        if [ $? -ne 0 ]; then
            echo "Could not initialize open embedded"
            exitScript -1
        fi
        cd $EXEC_DIR
        ;;
    update)
        updateRepositories
        ;;
    build)
        args=${@:2:$#}
        if [ -z "$args" ]; then
            args=$BUILD_DEFAULT_LIST
        fi

        checkWorkDir
        if [ $? -ne 0 ]; then
            echo "Work dir $WORK_DIR does not exist!"
            echo "Please first do an init"
            exitScript -1
        fi

        initOpenEmbedded
        if [ $? -ne 0 ]; then
            echo "Could not initialize open embedded"
            exitScript -1
        fi
        
        bitbake $(eval echo $args)
        if [ $? -ne 0 ]; then
            echo "Bitbake failed"
            exitScript -1
        fi

        backupYoctoConfiguration
        cd $EXEC_DIR
        ;;
    copy-images)
        args=${@:2:$#}
        if [ -z "$args" ]; then
            args=$IMAGE_DIR
        fi
        copyImages $args
        copyImagesManifest $args
        ;;
    version-layer)
        getLayerVersions
        ;;
    clean-tmp)
        cleanTmp
        ;;
    get-autorevs)
        initOpenEmbedded &>/dev/null
        if [ $? -ne 0 ]; then
            echo "Could not initialize open embedded"
            exitScript -1
        fi

        getSrcrevs
        ;;

*)
        echo "usage: $0 {init|sync|build|toolchain}"
        echo "Example:"
        echo "  $0 init [release|master]        - clone and setup environment for the specified version"
        echo "  $0 update                       - pull changes from git"
        echo "  $0 build <recipe>               - build the default image(s) or the specified receipe"
        echo "  $0 copy-images <destination>    - copy the image(s) to the default images folders or the specified one"
        echo "  $0 version-layer                - print layers list and corresponding commit hash"
        echo "  $0 clean-tmp                    - delete Yocto build output, but keep the configuration"
        echo "  $0 get-autorevs                 - print the list of all packages with AUTO_REVS version"
    esac
    
exitScript 0
