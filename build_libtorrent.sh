#!/bin/bash
set -eu

DEST_ARCH=$1
echo "DEST_ARCH=$DEST_ARCH"
if [ -z "$DEST_ARCH" ]; then
    echo "You must specific an architecture 'armv7a, x86, ...'."
    echo ""
    exit 1
fi

ROOT_DIR=$PWD
ARCHS_32="armv7a x86"
ARCHS_64="armv7a arm64 x86 x86_64"

ARCH_TYPE=
RANLIB_NAME=
HOST_NAME=

if [[ "$DEST_ARCH" = "armv7a" ]]; then
    ARCH_TYPE="arm"
    RANLIB_NAME="arm-linux-androideabi-ranlib"  
    HOST_NAME="arm-linux-androideabi"
elif [[ "$DEST_ARCH" = "x86" ]]; then
    ARCH_TYPE="x86"  
    RANLIB_NAME="i686-linux-android-gcc-ranlib"
    HOST_NAME="i686-linux-android-gcc"
fi

BOOST_VERSION=1.69.0
LIBTORRENT_VERSION=1.2.0
LIBTORRENT_BRANCH=libtorrent_1_2_0
echo "start building libtorent_$LIBTORRENT_VERSION with boost_$BOOST_VERSION"

source lib_archive.sh

init_boost $BOOST_VERSION
init_libtorrent $LIBTORRENT_BRANCH $LIBTORRENT_VERSION

if [ -z "$ANDROID_NDK" -o -z "$ANDROID_NDK" ]; then
    echo "You must define ANDROID_NDK, ANDROID_SDK before starting."
    echo "They must point to your NDK and SDK directories.\n"
    exit 1
fi

TOOLCHAIN=$PWD/toolchain-$ARCH_TYPE
export ANDROID_TOOLCHAIN=$TOOLCHAIN
BOOST_PREFIX=${TOOLCHAIN}/build

if [ ! -d "$TOOLCHAIN" ]; then
  echo "Creating toolchain..."
  $ANDROID_NDK/build/tools/make-standalone-toolchain.sh \
      --platform=android-15 \
      --install-dir="$TOOLCHAIN" \
      --arch="$ARCH_TYPE" \
      --use-llvm \
      --stl=libc++
else
  echo "Toolchain already created"
fi

echo "Building boost_$BOOST_VERSION"

cd $BOOST_DIR
echo "Copy user-config.jam"
USER_CONFIG=$ROOT_DIR/$BOOST_DIR/tools/build/src/user-config.jam
rm -f $USER_CONFIG
cp $ROOT_DIR/config/android-$ARCH_TYPE-config.jam $USER_CONFIG

echo "Bootstrapping..."
./bootstrap.sh --prefix=${BOOST_PREFIX}

echo "Building..."
./b2 install \
    -j8 \
    --with-atomic \
    --with-chrono \
    --with-filesystem \
    --with-random \
    --with-system \
    toolset=clang-$ARCH_TYPE \
    architecture=$ARCH_TYPE \
    variant=release \
    target-os=android \
    threading=multi \
    threadapi=pthread \
    link=static \
    runtime-link=static \

cd ..
echo "Running ranlib on libraries..."
libs=$(find "$TOOLCHAIN/build/lib/" -name '*.a')
for lib in $libs; do
  "$TOOLCHAIN/bin/$RANLIB_NAME" "$lib"
done

echo "Build boost_$BOOST_VERSION success"

cd $LIBTORRENT_DIR

echo "Building libtorrent_$LIBTORRENT_VERSION"

export PATH=$TOOLCHAIN/bin:$PATH
export CC=clang
export CXX=clang++

TORRENT_HOST=arm-linux-androideabi
TORRENT_PREFIX=${TOOLCHAIN}/build

./configure --host=$TORRENT_HOST \
            --prefix=$TORRENT_PREFIX \
            --with-boost=$BOOST_PREFIX \
            --with-boost-libdir=$BOOST_PREFIX/lib \
			      --enable-examples=no \
			      --disable-encryption \
			      --enable-tests=no \
		        --enable-shared=no \
            --enable-static=yes \
            --enable-debug=no \
            --enable-loggin-yes

make -j8
make install


