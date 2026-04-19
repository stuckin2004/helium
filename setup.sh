#!/usr/bin/env bash

#
# This is the one true setup script, this will also setup an env for builds.
#

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Colours & helpers
# ─────────────────────────────────────────────────────────────────────────────

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYN='\033[0;36m'
BOLD='\033[1m'
RST='\033[0m'

info()  { echo -e "${CYN}${BOLD}[INFO]${RST}  $*"; }
ok()    { echo -e "${GRN}${BOLD}[ OK ]${RST}  $*"; }
warn()  { echo -e "${YEL}${BOLD}[WARN]${RST}  $*"; }
fail()  { echo -e "${RED}${BOLD}[FAIL]${RST}  $*"; }

# ─────────────────────────────────────────────────────────────────────────────
# Dependency tracking  (collect-all, then exit)
# ─────────────────────────────────────────────────────────────────────────────

VITAL_FAILURES=()

# Vital deps must exist, fails are collected and displayed before hard crash
check_dep_vital() {
    local name="$1"
    if ! command -v "$name" &>/dev/null; then
        fail "Vital dependency missing: ${BOLD}${name}${RST}"
        VITAL_FAILURES+=("$name")
    else
        ok "Found vital dep: ${name}"
    fi
}

# Optional dependencies.
check_dep_optional() {
    local name="$1"
    if ! command -v "$name" &>/dev/null; then
        warn "Optional dependency not found: ${name} (skipping)"
    else
        ok "Found optional dep: ${name}"
    fi
}

# Call this after all check_dep_vital calls.
assert_vitals() {
    if [ ${#VITAL_FAILURES[@]} -gt 0 ]; then
        echo
        fail "The following vital dependencies are missing:"
        for dep in "${VITAL_FAILURES[@]}"; do
            echo -e "  ${RED}•${RST} ${dep}"
        done
        echo
        fail "Cannot continue. Install the missing tools and re-run."
        exit 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Step 0 – Distro detection
# ─────────────────────────────────────────────────────────────────────────────

detect_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_ID_LIKE="${ID_LIKE:-}"
    else
        DISTRO_ID="unknown"
        DISTRO_ID_LIKE=""
    fi

    case "$DISTRO_ID" in
        arch|manjaro|endeavouros|artix)
            PKG_MANAGER="pacman"
            PKG_UPDATE="sudo pacman -Syu --noconfirm"
            PKG_INSTALL="sudo pacman -S --needed --noconfirm"
            ;;
        ubuntu|debian|linuxmint|pop)
            PKG_MANAGER="apt"
            PKG_UPDATE="sudo apt-get update -y && sudo apt-get upgrade -y"
            PKG_INSTALL="sudo apt-get install -y"
            ;;
        *)
            # Fall back to ID_LIKE (e.g. "arch" inside Manjaro derivatives)
            case "$DISTRO_ID_LIKE" in
                *arch*)
                    PKG_MANAGER="pacman"
                    PKG_UPDATE="sudo pacman -Syu --noconfirm"
                    PKG_INSTALL="sudo pacman -S --needed --noconfirm"
                    ;;
                *debian*|*ubuntu*)
                    PKG_MANAGER="apt"
                    PKG_UPDATE="sudo apt-get update -y && sudo apt-get upgrade -y"
                    PKG_INSTALL="sudo apt-get install -y"
                    ;;
                *)
                    fail "Unsupported distro: ${DISTRO_ID}. Only Arch and Debian/Ubuntu families are supported."
                    exit 1
                    ;;
            esac
            ;;
    esac

    info "Detected distro: ${BOLD}${DISTRO_ID}${RST} (package manager: ${PKG_MANAGER})"
}

# ─────────────────────────────────────────────────────────────────────────────
# Step 0 – System update
# ─────────────────────────────────────────────────────────────────────────────

update_system() {
    info "Updating system packages…"
    eval "$PKG_UPDATE"
    ok "System updated."
}

# ─────────────────────────────────────────────────────────────────────────────
# Step 0.5 – Tool checks
# ─────────────────────────────────────────────────────────────────────────────

check_tools() {
    info "Checking vital dependencies…"
    check_dep_vital "make"
    check_dep_vital "git"
    check_dep_vital "pkg-config"
    check_dep_vital "python3"

    info "Checking optional dependencies…"
    check_dep_optional "ccache"
    checK_dep_optional "bear"
    check_dep_optional "gdb"
    check_dep_optional "doxygen"

    # Bail out if anything vital is missing!
    assert_vitals
}

# ─────────────────────────────────────────────────────────────────────────────
# Step 1 – Package installation
# ─────────────────────────────────────────────────────────────────────────────

install_packages() {
    info "Installing required packages…"

    case "$PKG_MANAGER" in
        pacman)
            # multilib must be enabled for 32-bit cross-compilation support
            if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
                warn "multilib repo not enabled in /etc/pacman.conf."
                warn "i686 cross-compiler packages may not install correctly."
                warn "Enable [multilib] and re-run if cross-compilation fails."
            fi
            eval "$PKG_INSTALL" \
                base-devel \
                bc m4 \
                lib32-gcc-libs \
                mingw-w64-gcc  # AUR – installs i686-w64-mingw32-g++ etc.
                # For native i686 Linux target, use the AUR package:
                # multilib-devel  +  gcc-multilib
            ;;
        apt)
            eval "$PKG_INSTALL" \
                build-essential \
                bc m4 \
                gcc-multilib g++-multilib \
                gcc-i686-linux-gnu g++-i686-linux-gnu
            ;;
    esac

    ok "Packages installed."
}

# ─────────────────────────────────────────────────────────────────────────────
# Step 2 – Cross-compiler setup  (i686-linux-gnu / i686-linux-g++)
# ─────────────────────────────────────────────────────────────────────────────

setup_compiler() {
    info "Checking for i686 cross-compiler…"

    # Preferred canonical name on most distros; also accept the GNU-triplet variant.
    local CC32 CXX32
    if command -v i686-linux-gnu-gcc &>/dev/null; then
        CC32="i686-linux-gnu-gcc"
        CXX32="i686-linux-gnu-g++"
        ok "Found i686 cross-compiler: ${CC32}"
    elif command -v i686-linux-g++ &>/dev/null; then
        CC32="i686-linux-gcc"
        CXX32="i686-linux-g++"
        ok "Found i686 cross-compiler: ${CC32}"
    else
        warn "i686 cross-compiler not found after package install."
        warn "Attempting to install now…"

        case "$PKG_MANAGER" in
            pacman)
                # gcc-multilib provides 32-bit support on Arch.
                eval "$PKG_INSTALL" gcc-multilib lib32-glibc
                ;;
            apt)
                eval "$PKG_INSTALL" gcc-i686-linux-gnu g++-i686-linux-gnu
                ;;
        esac

        # Re-check after attempted install.
        if command -v i686-linux-gnu-gcc &>/dev/null; then
            CC32="i686-linux-gnu-gcc"
            CXX32="i686-linux-gnu-g++"
            ok "i686 cross-compiler installed successfully."
        else
            fail "i686 cross-compiler could not be installed automatically."
            fail "On Arch, enable [multilib] and install gcc-multilib."
            fail "On Debian/Ubuntu: sudo apt install gcc-i686-linux-gnu g++-i686-linux-gnu"
            exit 1
        fi
    fi

    # Export so child processes (make, cmake, etc.) pick them up.
    export CC32 CXX32
}

# ─────────────────────────────────────────────────────────────────────────────
# Step 3 – Environment setup
# ─────────────────────────────────────────────────────────────────────────────

setup_env() {
    info "Configuring build environment…"

    # Cross-compiler shorthands (already set in setup_compiler).
    export CC32="${CC32:-i686-linux-gnu-gcc}"
    export CXX32="${CXX32:-i686-linux-gnu-g++}"

    # Honour existing MAKEFLAGS or default to parallel build.
    export MAKEFLAGS="${MAKEFLAGS:--j$(nproc)}"

    # Optional ccache acceleration.
    if command -v ccache &>/dev/null; then
        export CC="ccache gcc"
        export CXX="ccache g++"
        info "ccache detected – wrapping CC/CXX."
    fi

    # Extend PATH with any local tool dirs that may exist.
    for dir in "$HOME/.local/bin" "$HOME/bin"; do
        if [ -d "$dir" ] && [[ ":$PATH:" != *":$dir:"* ]]; then
            export PATH="$dir:$PATH"
        fi
    done

    ok "Environment configured."
    echo
    echo -e "  ${BOLD}CC32${RST}       = ${CC32}"
    echo -e "  ${BOLD}CXX32${RST}      = ${CXX32}"
    echo -e "  ${BOLD}MAKEFLAGS${RST}  = ${MAKEFLAGS}"
    [ -n "${CC:-}" ]  && echo -e "  ${BOLD}CC${RST}         = ${CC}"
    [ -n "${CXX:-}" ] && echo -e "  ${BOLD}CXX${RST}        = ${CXX}"
    echo
}

# ─────────────────────────────────────────────────────────────────────────────
# Step 4 – Profit(?)
# ─────────────────────────────────────────────────────────────────────────────

main() {
    echo
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
    echo -e "${BOLD}         Build Environment Setup         ${RST}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
    echo

    detect_distro    # Step 0   – figure out what we're on
    update_system    # Step 0   – bring the system current
    check_tools      # Step 0.5 – verify required tools (collect + exit on failure)
    install_packages # Step 1   – pull in any missing packages
    setup_compiler   # Step 2   – ensure i686 cross-compiler exists
    setup_env        # Step 3   – export build env vars

    echo -e "${GRN}${BOLD}All done. Your build environment is ready.${RST}"
    echo
}

main "$@"
