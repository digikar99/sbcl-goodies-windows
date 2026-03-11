#!/bin/bash

source $(dirname ${0})/lib.sh

SBCL_HOST=${1}
SBCL_VERSION=${2}
ASDF_VERSION=${3}
REVISION=${4}
export CUSTOM_LIBDIR=${5}
if [[ ! -d "${CUSTOM_LIBDIR}" ]]; then
    die "Directory does not exist: CUSTOM_LIBDIR=${CUSTOM_LIBDIR}"
fi

cd sbcl

UNAME=$(uname)
if [ "$UNAME" == "Linux" ] ; then
    export SYS_LIBDIR="/usr/lib/x86_64-linux-gnu"
    SBCL_HOST="${SBCL_HOST}/run-sbcl.sh --noinform --no-userinit"
    SBCL_BUILD_OPTIONS="--with-sb-core-compression \
    --with-sb-linkable-runtime \
    --without-gencgc --with-mark-region-gc \
    --without-sb-eval \
    --with-sb-fasteval"
    LIBCRYPTO=${SYS_LIBDIR}/libcrypto.a
elif [[ "$UNAME" == CYGWIN* || "$UNAME" == MINGW* ]] ; then
    export SYS_LIBDIR="/mingw64/lib"
    SBCL_HOST="/mingw64/bin/sbcl --noinform --no-userinit"
    SBCL_BUILD_OPTIONS="--fancy --with-sb-linkable-runtime"
    LIBCRYPTO="${SYS_LIBDIR}/libcrypto.a ${SYS_LIBDIR}/libcrypt32.a"
fi


export LIBZSTD="$SYS_LIBDIR/libzstd.a"
# Replace all instances of -lzstd in sbcl source with $LIBZSTD
find ./ -type f -exec sed -i -e "s|-lzstd|$LIBZSTD|g" {} \;

# Download zstd license; may be we should fetch from the system files? But which file?
mkdir zstd-bsd
curl -o zstd-bsd/LICENSE "https://raw.githubusercontent.com/facebook/zstd/refs/heads/dev/LICENSE"

# Prevent SBCL build from generating a version string from git
rm -rf .git
# Override SBCL lisp-implementation-version
echo "\"${SBCL_VERSION}+r${REVISION}\"" > version.lisp-expr

# Update ASDF
pushd contrib/asdf
./pull-asdf.sh "${ASDF_VERSION}"
popd

./make.sh --xc-host="$SBCL_HOST" $SBCL_BUILD_OPTIONS

# Link runtime with goodies and overwrite the original
LIBFIXPOSIX=${CUSTOM_LIBDIR}/libfixposix.a
LIBSSL=${SYS_LIBDIR}/libssl.a
LIBTLS=${SYS_LIBDIR}/libtls.a

if [ "$UNAME" == "Linux" ] ; then
    export STATIC_ARCHIVES="$LIBFIXPOSIX $LIBCRYPTO $LIBSSL $LIBTLS"
elif [[ "$UNAME" == CYGWIN* || "$UNAME" == MINGW* ]] ; then
    export STATIC_ARCHIVES="$LIBCRYPTO $LIBSSL"
fi



make -C src/runtime -f binaries.mk sbcl.extras
mv -vf src/runtime/sbcl.extras src/runtime/sbcl

mkdir -vp third_party/include
if [ "$UNAME" == "Linux" ] ; then
    # Include libfixposix headers
    cp -av ../destdir/usr/local/include/* third_party/include/
else
    touch third_party/include/empty
fi

cd ..

# Build source distribution
SRCDIST=sbcl-${SBCL_VERSION}+r${REVISION}
mv -v sbcl "${SRCDIST}"
"${SRCDIST}"/source-distribution.sh "${SRCDIST}"
bzip2 "${SRCDIST}"-source.tar

# Build binary x86_64 distribution
if [ "$UNAME" == "Linux" ] ; then
    BINDIST="${SRCDIST}"-x86-64-linux
elif [[ "$UNAME" == CYGWIN* || "$UNAME" == MINGW* ]] ; then
    BINDIST="${SRCDIST}"-x86-64-windows
fi

mv -v "${SRCDIST}" "${BINDIST}"
"${BINDIST}"/binary-distribution.sh "${BINDIST}"
bzip2 "${BINDIST}"-binary.tar

echo "###################################################"
echo "Created ${SRCDIST}-source.tar.bz2"
echo "Created ${BINDIST}-binary.tar.bz2"
echo "###################################################"
echo "SRCDIST=${SRCDIST}-source.tar.bz2" >> ${GITHUB_ENV}
echo "BINDIST=${BINDIST}-binary.tar.bz2" >> ${GITHUB_ENV}
