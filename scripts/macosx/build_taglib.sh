#!/bin/bash

# Echo commands
set -x

# Quit on errors
set -e

# Get the path to our scripts folder.
pushd `dirname $0` > /dev/null
PROGDIR=`pwd -P`
popd > /dev/null

export VERSION_NUMBER=1.11.1
export VERSION=taglib-${VERSION_NUMBER}
export ARCHIVE=$VERSION.tar.gz

echo "Building $VERSION for $MIXXX_ENVIRONMENT_NAME for architectures: ${MIXXX_ARCHS[@]}"

# You may need to change these from version to version.
export DYLIB=taglib/libtag.1.17.0.dylib
export STATICLIB=taglib/libtag.a

for ARCH in ${MIXXX_ARCHS[@]}
do
  mkdir -p $VERSION-$ARCH
  tar -zxf $DEPENDENCIES/$ARCHIVE -C $VERSION-$ARCH --strip-components 1
  cd $VERSION-$ARCH
  source $PROGDIR/environment.sh $ARCH
  # To build static, use -DENABLE_STATIC=ON but this turns off building a shared library.
  cmake . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$MIXXX_PREFIX" -DCMAKE_OSX_DEPLOYMENT_TARGET="$MIXXX_MACOSX_TARGET" -DCMAKE_OSX_SYSROOT="$SDKROOT" -DCMAKE_VERBOSE_MAKEFILE=TRUE -DBUILD_SHARED_LIBS=TRUE
  make
  cd ..
done

# Install the host version in case there are binaries we want to run.
export ARCH=$HOST_ARCH
cd $VERSION-$ARCH
source $PROGDIR/environment.sh $ARCH

# Taglib's build system only builds either a shared library or a dynamic one. We use the dynamic one for now.
OTHER_DYLIBS=()
for OTHER_ARCH in ${MIXXX_ARCHS[@]}
do
  if [ $OTHER_ARCH != $ARCH ]; then
    OTHER_DYLIBS+=(../$VERSION-$OTHER_ARCH/$DYLIB)
  fi
done
lipo -create ./$DYLIB ${OTHER_DYLIBS[@]} -output ./$DYLIB
make install
cd ..
