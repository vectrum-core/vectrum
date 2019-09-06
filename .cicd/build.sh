#!/bin/bash
set -eo pipefail
. ./.cicd/helpers/general.sh
mkdir -p $BUILD_DIR
CMAKE_EXTRAS="-DBUILD_MONGO_DB_PLUGIN=true -DCMAKE_BUILD_TYPE='Release'"
if [[ $(uname) == 'Darwin' ]]; then # macOS
    cd $BUILD_DIR
    [[ $TRAVIS == true ]] && ccache -s
    export BOOST_ROOT=$HOME/opt/boost
    export LLVM_DIR=$HOME/opt/llvm/lib/cmake/llvm
    export PATH=$HOME/bin:${PATH}:$HOME/opt/mongodb/bin
    cmake $CMAKE_EXTRAS ..
    make -j$JOBS
else # linux
    ARGS=${ARGS:-"--rm --init -v $(pwd):$MOUNTED_DIR"}
    . $HELPERS_DIR/file-hash.sh $CICD_DIR/platforms/$IMAGE_TAG.dockerfile
    PRE_COMMANDS="cd $MOUNTED_DIR/build"
    # PRE_COMMANDS: Executed pre-cmake
    # CMAKE_EXTRAS: Executed within and right before the cmake path (cmake CMAKE_EXTRAS ..)
    if [[ $IMAGE_TAG == 'ubuntu-18.04' ]]; then
        PRE_COMMANDS="$PRE_COMMANDS && export PATH=/usr/lib/ccache:\\\$PATH"
        CMAKE_EXTRAS="$CMAKE_EXTRAS"
    elif [[ $IMAGE_TAG == 'ubuntu-16.04' ]]; then
        PRE_COMMANDS="$PRE_COMMANDS && export PATH=/usr/lib/ccache:\\\$PATH"
        CMAKE_EXTRAS="$CMAKE_EXTRAS  -DCMAKE_CXX_COMPILER='clang++' -DCMAKE_C_COMPILER='clang'"
    elif [[ $IMAGE_TAG == 'centos-7.6' ]]; then
        PRE_COMMANDS="$PRE_COMMANDS && source /opt/rh/devtoolset-7/enable && source /opt/rh/python33/enable && export PATH=/usr/lib64/ccache:\\\$PATH"
    elif [[ $IMAGE_TAG == 'amazon_linux' ]]; then
        PRE_COMMANDS="$PRE_COMMANDS && export PATH=/usr/lib64/ccache:\\\$PATH"
        CMAKE_EXTRAS="$CMAKE_EXTRAS"
    elif [[ $IMAGE_TAG == 'fedora-27' ]]; then
        PRE_COMMANDS="$PRE_COMMANDS && export CPATH=/usr/include/llvm4.0"
    fi
    BUILD_COMMANDS="cmake $CMAKE_EXTRAS .. && make -j$JOBS"
    # docker commands
    if [[ $BUILDKITE == true ]]; then
        # generate base images
        $CICD_DIR/generate-base-images.sh
        [[ $ENABLE_INSTALL == true ]] && COMMANDS="cp -r $MOUNTED_DIR /root/eosio && cd /root/eosio/build &&"
        COMMANDS="$COMMANDS $BUILD_COMMANDS"
        [[ $ENABLE_INSTALL == true ]] && COMMANDS="$COMMANDS && make install"
    elif [[ $TRAVIS == true ]]; then
        ARGS="$ARGS -v /usr/lib/ccache -v $HOME/.ccache:/opt/.ccache -e JOBS -e TRAVIS -e CCACHE_DIR=/opt/.ccache"
        COMMANDS="ccache -s && $BUILD_COMMANDS"
    fi
    COMMANDS="$PRE_COMMANDS && $COMMANDS"
    echo "docker run $ARGS $(buildkite-intrinsics) $FULL_TAG bash -c \"$COMMANDS\""
    eval docker run $ARGS $(buildkite-intrinsics) $FULL_TAG bash -c \"$COMMANDS\"
fi