#!/bin/bash -x

set +e

# If OVA_CACHE_BUILD is not used, cache_image directory does not exist
if [ -d  $WORKSPACE/cache_image/RackHD/packer/ ] ; then
    echo "Copy Cache images from PACKER_CACHE_BUILD job archiving"
    mv $WORKSPACE/cache_image/RackHD/packer/* $WORKSPACE/build/packer/
    ls $WORKSPACE/build/packer/*
fi

vmware -v

echo using artifactory : $ARTIFACTORY_URL

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/../../shareMethod.sh
# check variable readiness
if   ! check_empty_variable "STAGE_REPO_NAME" ||  ! check_empty_variable "DEB_DISTRIBUTION"   || ! check_empty_variable "DEB_COMPONENT"  ; then
    echo "[Error] Parameter Missing , refer error message as above.."
    exit 2
fi



echo "kill previous running packer instances"

set +e
pkill packer
pkill vmware
set -e

pushd $WORKSPACE/build/packer 
echo "Start to packer build .."

export PACKER_CACHE_DIR=$HOME/.packer_cache
#export vars to build ova

export ANSIBLE_PLAYBOOK=rackhd_package #build image from deb package
# Using Artifactory as the debian repository instead of Bintray
export DEBIAN_REPOSITORY="deb ${ARTIFACTORY_URL}/${STAGE_REPO_NAME} ${DEB_DISTRIBUTION} ${DEB_COMPONENT}"

if [ "$BUILD_TYPE" == "vmware" ] &&  [ -f output-vmware-iso/*.vmx ]; then
     echo "Build from template cache"
     export BUILD_STAGE=BUILD_FINAL
else
     echo "Build from begining"
     export BUILD_STAGE=BUILD_ALL
fi

export RACKHD_VERSION=$RACKHD_VERSION

#export end

./HWIMO-BUILD

mv rackhd-${OS_VER}.ova rackhd-${OS_VER}-${RACKHD_VERSION}.ova

popd

