function init_boost(){
    version=$1
    echo "Init boost $version..."
    dir_name=boost_$(sed 's#\.#_#g' <<< $version)
    archive=${dir_name}.tar.gz
    if [ ! -f "$archive" ]; then
        wget -O $archive "https://dl.bintray.com/boostorg/release/$version/source/$archive"
    else
        echo "Archive $archive already downloaded"
    fi

    echo "Extracting..."
    if [ ! -d "$dir_name" ]; then
        # rm -rf $dir_name
        tar xf $archive
    else
        echo "Archive $archive already unpacked into $dir_name"
    fi
    export BOOST_DIR=$dir_name
}

function init_libtorrent(){
    libtorrent_branch=$1
    libtorrent_version=$2
    echo "Init libtorrent $libtorrent_version..."
    dir_name=libtorrent-rasterbar-$libtorrent_version
    archive=${dir_name}.tar.gz
    if [ ! -f "$archive" ]; then
        wget -O $archive "https://github.com/arvidn/libtorrent/releases/download/$libtorrent_branch/$archive"
    else
        echo "Archive $archive already downloaded"
    fi

    echo "Extracting..."
    if [ ! -d "$dir_name" ]; then
        # rm -rf $dir_name
        tar xf $archive
        echo "applying patch..."
        patch $LIBTORRENT_DIR/src/file.cpp < patch/remove_posix_fadvise.patch
    else
        echo "Archive $archive already unpacked into $dir_name"
    fi
    export LIBTORRENT_DIR=$dir_name
}
