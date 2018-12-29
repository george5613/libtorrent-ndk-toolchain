#!/bin/bash
set -eu

ROOT_DIR=$PWD
ARCH_TYPE="arm"
TORRENT_ARCHS_32="armv7a x86"
TORRENT_ARCHS_64="armv7a arm64 x86 x86_64"
ANDROID_NDK=/Users/lingjie/Library/Android/android-ndk-r16b

BOOST_VERSION=1.69.0
LIBTORRENT_VERSION=1.1.11
LIBTORRENT_BRANCH=libtorrent_1_1_11
echo "start building libtorent_$LIBTORRENT_VERSION with boost_$BOOST_VERSION"

source lib_archive.sh

init_boost $BOOST_VERSION
init_libtorrent $LIBTORRENT_BRANCH $LIBTORRENT_VERSION

if [ -z "$ANDROID_NDK" -o -z "$ANDROID_NDK" ]; then
    echo "You must define ANDROID_NDK, ANDROID_SDK before starting."
    echo "They must point to your NDK and SDK directories.\n"
    exit 1
fi

TOOLCHAIN=$PWD/toolchain
export ANDROID_TOOLCHAIN=$TOOLCHAIN
BOOST_PREFIX=${TOOLCHAIN}/build

if [ ! -d "$TOOLCHAIN" ]; then
  echo "Creating toolchain..."
  $ANDROID_NDK/build/tools/make-standalone-toolchain.sh \
      --platform=android-15 \
      --install-dir="$TOOLCHAIN" \
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
    toolset=clang-android \
    architecture=arm \
    variant=release \
    target-os=android \
    threading=multi \
    threadapi=pthread \
    link=static \
    runtime-link=static \

echo "Running ranlib on libraries..."
libs=$(find "bin.v2/libs/" -name '*.a')
for lib in $libs; do
  "$TOOLCHAIN/bin/arm-linux-androideabi-ranlib" "$lib"
done

echo "Build boost_$BOOST_VERSION success"

cd ..
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


