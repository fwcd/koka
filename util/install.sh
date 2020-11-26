#!/bin/sh -e
VERSION="v2.0.8"
MODE="install"          # or uninstall
PREFIX="/usr/local"
QUIET=""
FORCE=""
KOKA_TEMP_DIR=""        # empty creates one dynamically
KOKA_DIST_BASE_URL="https://github.com/koka-lang/koka/releases/download"
KOKA_DIST_URL=""        # $KOKA_DIST_BASE_URL/$VERSION
KOKA_DIST_SOURCE=""     # $KOKA_DIST_URL/<os>-<arch>.tar.gz

# KOKA_DIST_URL="."

# ---------------------------------------------------------
# helper functions
# ---------------------------------------------------------

make_temp_dir() {
  if [ -z "$KOKA_TEMP_DIR" ] ; then
    KOKA_TEMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t koka)"
  fi
}

cleanup_temp_dir() {
  if [ -n "$KOKA_TEMP_DIR" ] ; then
    rm -rf "$KOKA_TEMP_DIR"
    KOKA_TEMP_DIR=
  fi
}

die() {
  echo "$@" >&2
  exit 1
}

info() {
  if [ -z "$QUIET" ] ; then
    echo "$@"
  fi
}

has_cmd() {
  command -v "$1" > /dev/null 2>&1
}

on_path() {
  echo ":$PATH:" | grep -q :"$1":
}

# ---------------------------------------------------------
# sudo
# ---------------------------------------------------------
USE_SUDO=""    # so only the first sudo forces a prompt.

sudocmd() {
  if [ -z "$USE_SUDO" ] ; then
    # echo "sudo cmd: not set: $USE_SUDO: $@"
    if command -v sudo >/dev/null; then
      echo
      echo "Need to use 'sudo' for further $MODE at $PREFIX"
      echo
      USE_SUDO="always"
      sudo -k  # -k: Disable cached credentials (force prompt for password).
    else
      USE_SUDO="never"
    fi
  fi
  if [ "$USE_SUDO" = "never" ] ; then
    #echo "sudo cmd: never: $USE_SUDO: $@"
    "$@"
  else
    #echo "sudo cmd: always: $USE_SUDO: $@"
    sudo "$@"
  fi
}


# ---------------------------------------------------------
# arguments
# ---------------------------------------------------------

while : ; do
  flag="$1"
  case "$flag" in
  *=*)  flag_arg="${flag#*=}";;
  *)    flag_arg="yes" ;;
  esac
  # echo "option: $flag, arg: $flag_arg"
  case "$flag" in
    "") break;;
    -q|--quiet)
        QUIET="yes";;
    -p) shift
        PREFIX="$1";;
    -p=*|--prefix=*)
        PREFIX="$flag_arg";;
    -u=*|--url=*)
        KOKA_DIST_URL="$flag_arg";;
    -s) shift
        KOKA_DIST_SOURCE="$1";;
    -s=*|--source=*)
        KOKA_DIST_SOURCE="$flag_arg";;
    -v) shift
        VERSION="$1";;
    -v=*|--version=*)
        VERSION="$flag_arg";;
    -u)
        MODE="uninstall";;
    --uninstall)
        FORCE="yes"
        MODE="uninstall";;
    -h|--help|-\?|help|\?)
        echo "./install.sh [options]"
        echo ""
        echo "  -q, --quiet           suppress output"
        echo "  -u, --uninstall       uninstall koka ($VERSION)"
        echo "  -p, --prefix=<dir>    prefix directory ($PREFIX)"
        echo "  -s, --source=<url>    full source url ($KOKA_DIST_BASE_URL/$VERSION/<os>-<arch>.tar.gz)"
        echo "      --url=<url>       download url ($KOKA_DIST_BASE_URL/$VERSION)"
        echo "      --version=<ver>   version tag ($VERSION)"
        echo ""
        exit 0;;
    *) echo "warning: unknown option \"$1\"." 1>&2
  esac
  shift
done

# defaults
KOKA_SHARE_DIR="$PREFIX/share/koka"
KOKA_LIB_DIR="$PREFIX/lib/koka"
KOKA_BIN_DIR="$PREFIX/bin"
KOKA_EXE="$KOKA_BIN_DIR/koka-$VERSION"
KOKA_SYMLINK="$KOKA_BIN_DIR/koka"

if [ -z "$KOKA_DIST_URL" ] ; then
  KOKA_DIST_URL="$KOKA_DIST_BASE_URL/$VERSION"
fi


# ---------------------------------------------------------
# detect OS arch for download bundle
# ---------------------------------------------------------

# determines the the CPU's instruction set
ARCHBITS="64"
ARCH=""
OSARCH=""

detect_arch_bits() {
  if has_cmd getconf ; then
    if getconf LONG_BIT | grep -q 64 ; then
      ARCHBITS=64
    else
      ARCHBITS=32
    fi
  else
    case "$(uname -m)" in
      *64) ARCHBITS=64;;
      *)   ARCHBITS=32;;
    esac
  fi
}

detect_arch() {
  if arch | grep -Eq 'armv[78]l?' ; then
    ARCH="arm32"
  elif arch | grep -q aarch64 ; then
    ARCH="aarch64"
  else
    detect_arch_bits
    ARCH="x86_$ARCHBITS"
  fi
}

detect_osarch() {
  detect_arch
  case "$(uname)" in
    [Ll]inux)
      OSARCH="linux-$ARCH";;
    [Dd]arwin)
      OSARCH="osx-$ARCH";;
    *)
      info "warning: unable to detect os, assuming linux"
      OSARCH="linux-$ARCH";;
  esac
}

if [ -z "$KOKA_DIST_SOURCE" ] ; then
  detect_osarch
  KOKA_DIST_SOURCE="$KOKA_DIST_URL/koka-$VERSION-$OSARCH.tar.gz"
fi


# ---------------------------------------------------------
# various package managers
# ---------------------------------------------------------

apt_get_install() {
  missing=
  for pkg in $*; do
    if ! dpkg -s $pkg 2>/dev/null |grep '^Status:.*installed' >/dev/null; then
      missing="$missing $pkg"
    fi
  done
  if [ "$missing" = "" ]; then
    info "packages already installed"
  elif ! sudocmd apt-get install -y ${QUIET:+-qq}$missing; then
    die "\ninstalling apt packages failed ($@).  Please run 'apt-get update' and try again."
  fi
}

# Install packages using dnf
dnf_install() {
  if ! sudocmd dnf install -y ${QUIET:+-q} "$@"; then
    die "\ninstalling dnf packages failed ($@).  Please run 'dnf check-update' and try again."
  fi
}

# Install packages using yum
yum_install() {
  if ! sudocmd yum install -y ${QUIET:+-q} "$@"; then
    die "\ninstalling yum packages failed ($@).  Please run 'yum check-update' and try again."
  fi
}

# Install packages using apk
apk_install() {
  if ! sudocmd apk add --update ${QUIET:+-q} "$@"; then
    die "\ninstalling apk packages failed ($@).  Please run 'apk update' and try again."
  fi
}

# Install packages using pkg
pkg_install() {
  if ! sudocmd pkg install -y "$@"; then
    die "\ninstalling pkg packages failed ($@).  Please run 'pkg update' and try again."
  fi
}

# Install packages using an available package manager
install_packages() {
  if has_cmd apt-get ; then
    apt_get_install "$@"
  elif has_cmd dnf ; then
    dnf_install "$@"
  elif has_cmd yum ; then
    yum_install "$@"
  elif has_cmd apk ; then
    apk_install "$@"
  else
    info "unable to install packages ($@); continuing.."
  fi
}

install_dependencies() {
  info "installing dependencies.."
  if has_cmd apt-get ; then
    apt_get_install build-essential gcc make cmake tar wget
  elif has_cmd dnf ; then
    dnf_install gcc make cmake tar wget
  elif has_cmd yum ; then
    yum_install gcc make cmake tar wget
  elif has_cmd apk ; then
    apk_install gcc make cmake tar wget
  else
    info "unable to install dependencies; continuing.."
  fi
}


# ---------------------------------------------------------
# actual install
# ---------------------------------------------------------

download_file() {
  case "$1" in
    ftp://*|http://*|https://*)
      if has_cmd wget ; then
        if ! wget ${QUIET:+-q} "-O$2" "$1"; then
          die "wget download failed: $1"
        fi
      elif has_cmd curl ; then
        if ! curl ${QUIET:+-sS} -L -o "$2" "$1"; then
          die "curl download failed: $1"
        fi
      else
        die "Neither curl nor wget is available; install one to continue."
      fi;;
    *)
      # echo "cp $1 to $2"
      if ! cp $1 $2 ; then
        die "Unable to copy from $1"
      fi;;
  esac
}

install_dist() {
  info "Download $KOKA_DIST_SOURCE to $KOKA_TEMP_DIR"
  download_file "$KOKA_DIST_SOURCE" "$KOKA_TEMP_DIR/koka-dist.tar.gz"
  info "Unpacking.."
  if ! tar -xzf "$KOKA_TEMP_DIR/koka-dist.tar.gz" -C "$KOKA_TEMP_DIR"; then
    die "Extraction failed."
  fi

  info "Installing koka to $PREFIX"

  # install the exe and figure out whether to use sudo for the rest
  info "- install koka executable to $KOKA_EXE"
  if [ ! -d "$KOKA_BIN_DIR" ] ; then
    if ! mkdir -p "$KOKA_BIN_DIR" ; then
      if ! sudocmd mkdir -p "$KOKA_BIN_DIR" ; then
        die "Cannot create $KOKA_BIN_DIR installation directory"
      fi
    fi
  fi
  if ! install -c -m 0755 "$KOKA_TEMP_DIR/bin/koka" "$KOKA_EXE" 2>/dev/null; then
    if ! sudocmd install -c -o 0 -g 0 -m 0755 "$KOKA_TEMP_DIR/bin/koka" "$KOKA_EXE"; then
      die "Installation of koka to $KOKA_EXE has failed"
    fi
  else
    USE_SUDO="never"
  fi

  # install symlink
  info "- install koka executable symlink to $KOKA_SYMLINK"
  if [ -L "$KOKA_SYMLINK" ]; then
    if ! sudocmd rm -f "$KOKA_SYMLINK"; then
      info "unable to remove old koka executable; continuing.."
    fi
  fi
  if ! sudocmd ln -s "$KOKA_EXE" "$KOKA_SYMLINK"; then
    info "unable to create symbolic link to koka-$VERSION executable; continuing.."
  fi

  # copy libraries
  info "- install koka pre-compiled libraries to $KOKA_LIB_DIR/$VERSION"
  if ! sudocmd cp -p -r "$KOKA_TEMP_DIR/lib" "$PREFIX/" ; then
    die "Cannot copy pre-compiled libraries to $KOKA_TEMP_DIR/lib"
  fi
  info "- install koka source libraries to $KOKA_SHARE_DIR/$VERSION"
  if ! sudocmd cp -p -r "$KOKA_TEMP_DIR/share" "$PREFIX/" ; then
    die "Cannot copy pre-compiled libraries to $KOKA_TEMP_DIR/share"
  fi
}


# ---------------------------------------------------------
# uninstall
# ---------------------------------------------------------

uninstall() {
  # confirm uninstall (todo: add force option?)
  if [ -z "$FORCE" ] ; then
    read -r -p "Uninstalling koka version $VERSION. Are you sure? [yN] " input
    case $input in
      [yY][eE][sS]|[yY])
         info "uninstalling..";;
      *) echo "No"
         die "Uninstall canceled";;
    esac
  fi

  # uninstall share
  info "- uninstall $KOKA_SHARE_DIR/$VERSION"
  if [ -d "$KOKA_SHARE_DIR/$VERSION" ] ; then
    if ! rm -rf "$KOKA_SHARE_DIR/$VERSION" 2>/dev/null ; then
      if ! sudocmd rm -rf "$KOKA_SHARE_DIR/$VERSION" ; then
        info "unable to remove $KOKA_SHARE_DIR/$VERSION; continuing.."
      fi
    fi
    sudocmd rmdir "$KOKA_SHARE_DIR" 2>/dev/null # remove if empty
  fi

  # uninstall lib
  info "- uninstall $KOKA_LIB_DIR/$VERSION"
  if [ -d "$KOKA_LIB_DIR/$VERSION" ] ; then
    if ! rm -rf "$KOKA_LIB_DIR/$VERSION" 2>/dev/null ; then
      if ! sudocmd rm -rf "$KOKA_LIB_DIR/$VERSION" ; then
        info "unable to remove $KOKA_LIB_DIR/$VERSION; continuing.."
      fi
    fi
    sudocmd rmdir "$KOKA_LIB_DIR" 2>/dev/null # remove if empty
  fi


  # uninstall executable
  info "- uninstall executable $KOKA_EXE"
  if [ -f "$KOKA_EXE" ] ; then
    if ! rm -f "$KOKA_EXE" 2>/dev/null ; then
      if ! sudocmd rm -f "$KOKA_EXE" ; then
        info "unable to remove $KOKA_EXE; continuing.."
      fi
    fi
  fi

  if [ -L "$KOKA_SYMLINK" ] ; then
    symlink_target="`readlink $KOKA_SYMLINK`"
    # echo "links to: $symlink_target vs. $KOKA_EXE"
    if [ "$symlink_target" = "$KOKA_EXE" ] ; then
      info "- uninstall symbolic link $KOKA_SYMLINK"
      if ! rm -f "$KOKA_SYMLINK" 2>/dev/null ; then
        if ! sudocmd rm -f "$KOKA_SYMLINK" ; then
          info "unable to remove $KOKA_SYMLINK; continuing.."
        fi
      fi
    fi
  fi
}

# ---------------------------------------------------------
# main
# ---------------------------------------------------------

if [ "$MODE" = "uninstall" ] ; then
  uninstall
  info ""
  info "--------------------------------------------------"
  info "uninstall successful of $PREFIX/bin/koka-$VERSION"
else
  install_dependencies
  make_temp_dir
  trap cleanup_temp_dir EXIT
  install_dist

  info ""
  info "--------------------------------------------------"
  info "installation successful to $PREFIX/bin/koka"
  info ""
fi