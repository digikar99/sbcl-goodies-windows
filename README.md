# SBCL Goodies

The [windows branch of this repository](https://github.com/digikar99/sbcl-goodies/tree/windows) contains Github Actions workflows and build scripts that build each SBCL release with OpenSSL. It is a derivative of [sionescu/sbcl-goodies](https://github.com/sionescu/sbcl-goodies).

In contrast to the Linux (or Posix?) variant built at sionescu/sbcl-goodies, we have the following modifications:

- libfixposix and libtls is skipped; only `libssl libcrypto` are linked
- build.env is largely ignored; we rely on the libraries available through msys2 pacman
- sbcl available from msys2 pacman is used as the host
- `--fancy --with-sb-linkable-runtime` build options are used
