pacman --noconfirm -S unzip

echo "Setting up AMD AMF SDK..."
AMF_VERSION="master"
AMF_URL="https://github.com/GPUOpen-LibrariesAndSDKs/AMF/archive/refs/heads/master.zip"

if [ ! -d "AMF-master" ]; then
    wget $AMF_URL -O amf.zip
    unzip amf.zip
fi

export AMF_ROOT="$(pwd)/AMF-master"

GENERIC_BUILD_ARGS="--enable-pic --enable-shared --disable-static --disable-all --enable-avcodec --enable-avformat --enable-swscale --enable-decoder=h264 --enable-decoder=hevc --enable-decoder=av1 --enable-hwaccel=h264_dxva2 --enable-hwaccel=hevc_dxva2 --enable-hwaccel=av1_dxva2 --enable-hwaccel=h264_d3d11va --enable-hwaccel=hevc_d3d11va --enable-hwaccel=av1_d3d11va --enable-hwaccel=h264_d3d11va2 --enable-hwaccel=hevc_d3d11va2 --enable-hwaccel=av1_d3d11va2 --enable-libdav1d --enable-decoder=libdav1d --extra-cflags=-I$VULKAN_SDK\Include --enable-hwaccel=h264_vulkan --enable-hwaccel=hevc_vulkan --enable-hwaccel=av1_vulkan --enable-amf --enable-encoder=h264_amf --enable-encoder=hevc_amf --extra-cflags=\"-I$AMF_ROOT/amf/public/include\""

# Our MSYS command drops us in a random folder. Reorient ourselves based on this script directory.
SCRIPT=$(readlink -f $0)
SCRIPTPATH=`dirname $SCRIPT`
OUTDIR="$SCRIPTPATH/build/FFmpeg/build_$1"
cd $SCRIPTPATH/FFmpeg

# Apply our FFmpeg patches
git apply ../patches/ffmpeg_dxva_hevc_rext.patch

if [ "$1" = "x64" ]; then
    # x64 uses yasm for assembly
    pacman --noconfirm -S yasm

    TARGET_BUILD_ARGS="--arch=x86_64 --toolchain=msvc"
elif [ "$1" = "arm64" ]; then
    # ARM64 uses gas-preprocessor.pl for assembly
    mkdir /tmp/gas
    wget https://raw.githubusercontent.com/FFmpeg/gas-preprocessor/master/gas-preprocessor.pl -O /tmp/gas/gas-preprocessor.pl

    TARGET_BUILD_ARGS="--arch=arm64 --toolchain=msvc --enable-cross-compile"
    export PATH=/tmp/gas:$PATH
fi

mkdir $OUTDIR
PKG_CONFIG_PATH="$OUTDIR/../../dav1d/install_$1/lib/pkgconfig" ./configure --prefix=$OUTDIR $TARGET_BUILD_ARGS $GENERIC_BUILD_ARGS
make V=1 -j$(nproc)
make install

# Grab the PDBs too (not installed by 'make install')
cp libavcodec/*.pdb $OUTDIR/bin
cp libavutil/*.pdb $OUTDIR/bin
cp libswscale/*.pdb $OUTDIR/bin

# This build was in-tree, so clean it up
git reset --hard
git clean -f -d -x
