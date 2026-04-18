#!/bin/bash

source $(dirname ${0})/lib.sh

SBCL_HOST_VERSION=${1}; shift
if [[ -z "${SBCL_HOST_VERSION}" ]]; then
    die "Argument SBCL_HOST_VERSION is empty, expecting a valid version"
fi

case $(uname -m) in
    x86_64) ARCH="x86-64" ;;
    arm64|aarch64) ARCH="arm64";;
    *) ARCH=$(uname -m) ;;
esac

SRCDIR=sbcl-${SBCL_HOST_VERSION}-${ARCH}-$(uname -s | tr '[:upper:]' '[:lower:]')
TARBALL=${SRCDIR}-binary.tar.bz2

SBCL_HOST_URL="https://github.com/roswell/sbcl_bin/releases/download/${SBCL_HOST_VERSION}/${TARBALL}"

wget ${SBCL_HOST_URL}
tar x -f ${TARBALL}

ln -sfv ${SRCDIR} sbcl-host
echo "Unpacked SBCL host to ${PWD}/sbcl-host"
echo SBCL_HOST="${GITHUB_WORKSPACE}/sbcl-host/run-sbcl.sh" >> ${GITHUB_ENV}
