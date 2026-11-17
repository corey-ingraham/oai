#!/usr/bin/env bash
# bootstrap.sh - one-line entry point for a fresh Ubuntu machine:
#
#   curl -fsSL https://raw.githubusercontent.com/corey-ingraham/oai/main/bootstrap.sh | bash
#   curl -fsSL .../bootstrap.sh | bash -s -- --print-commands     # pass options to install.sh
#
# Installs git if missing (asks first), clones or fast-forwards this repo into
# $OAI_INSTALLER_DIR (default ~/src/oai-installer), then runs ./install.sh, which lists every
# change and asks before making it.
set -euo pipefail

REPO_URL="${OAI_INSTALLER_REPO:-https://github.com/corey-ingraham/oai.git}"
DIR="${OAI_INSTALLER_DIR:-$HOME/src/oai-installer}"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
[ "$(id -u)" -ne 0 ] || die "run as your normal user, not root (steps that need root use sudo)"

# Under `curl | bash` stdin is the script itself, so prompts read from the terminal instead.
if [ -t 0 ]; then TTY=/dev/stdin
elif [ -r /dev/tty ] && { : </dev/tty; } 2>/dev/null; then TTY=/dev/tty
else TTY=""; fi

if ! command -v git >/dev/null; then
    echo "git is needed to fetch the installer:  sudo apt-get install -y git"
    if [ -n "$TTY" ]; then
        read -r -p "Install git now? [Y/n] " a <"$TTY"
        case "$a" in ""|y|Y|yes|YES) ;; *) die "git not installed - nothing changed" ;; esac
    else
        case " $* " in *" --yes "*|*" -y "*) ;; *) die "no terminal to ask on - install git first, or pass --yes" ;; esac
    fi
    sudo apt-get update -q && sudo apt-get install -y git
fi

if [ -d "$DIR/.git" ]; then
    echo "Updating $DIR"
    git -C "$DIR" pull --ff-only -q || die "could not fast-forward $DIR - resolve it by hand"
elif [ -e "$DIR" ]; then
    die "$DIR exists but is not a git checkout - move it aside or set OAI_INSTALLER_DIR"
else
    echo "Cloning $REPO_URL -> $DIR"
    mkdir -p "$(dirname "$DIR")"
    git clone -q "$REPO_URL" "$DIR"
fi

cd "$DIR"
if [ -n "$TTY" ]; then exec ./install.sh "$@" <"$TTY"; else exec ./install.sh "$@"; fi
