# libtorrent-ndk-toolchain
A Shell script for build [libtorrent](https://github.com/arvidn/libtorrent) with Android NDK
supporting arch `armv7a` & `x86`

## How to build

```shell
git clone https://github.com/george5613/libtorrent-ndk-toolchain.git
cd libtorrent-ndk-toolchain
./build_libtorrent.sh armv7a|x86

```

After downing source and building the target will find in 

`libtorrent-ndk-toolchain/toolchain-$arch_type/build/`

## Thanks for

* [arvidn/libtorrent](https://github.com/arvidn/libtorrent)
* [frostwire/frostwire-jlibtorrent](https://github.com/frostwire/frostwire-jlibtorrent)

### TODO

* Add support for `arm-64`  ` x86-64`