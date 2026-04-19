#!/bin/bash
# =================================================================
# pack_nvidia.sh
# NVIDIA GPU Driver Offline Packager
# Target: ARM64 Ubuntu 24.04 (64k Page Size / Grace Blackwell)
# Driver: nvidia-open-580
#
# Usage: Run on an INTERNET-CONNECTED ARM64 Ubuntu 24.04 machine.
# Output: Three .zip files ready for transfer to the offline target.
# =================================================================
set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()     { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Configuration ─────────────────────────────────────────────────
DRIVER_VERSION="580"
KERNEL_VERSION="6.8.0-1025-nvidia"
WORKDIR="$HOME/nvidia-offline-pack"

# ── Pre-flight checks ─────────────────────────────────────────────
info "Checking internet connectivity..."
ping -c 1 archive.ubuntu.com &>/dev/null || die "No internet access. This script must run on an online machine."

info "Installing prerequisite tools (apt-rdepends, zip)..."
sudo apt-get update -qq
sudo apt-get install -y apt-rdepends zip

# ── Prepare workspace ─────────────────────────────────────────────
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"/{nvidia-headers,nvidia-deps,nvidia-all-packages}
info "Workspace: $WORKDIR"

# ── 1. Kernel Headers ─────────────────────────────────────────────
echo -e "\n${BOLD}[1/3] Packaging Kernel Headers (nvidia-headers.zip)${NC}"
cd "$WORKDIR/nvidia-headers"
info "Downloading: linux-headers-${KERNEL_VERSION} (standard + 64k)"
sudo apt-get download \
    "linux-headers-${KERNEL_VERSION}" \
    "linux-headers-${KERNEL_VERSION}-64k" \
    2>/dev/null || warn "One or more header variants not found – check kernel name."
DEB_COUNT=$(ls ./*.deb 2>/dev/null | wc -l)
success "Downloaded $DEB_COUNT header package(s)."

# ── 2. Graphics / System Dependencies ─────────────────────────────
echo -e "\n${BOLD}[2/3] Packaging System Dependencies (nvidia-deps.zip)${NC}"
cd "$WORKDIR/nvidia-deps"
info "Resolving recursive dependencies (this may take a minute)..."
DEP_LIST=$(apt-rdepends libegl-dev libgles-dev libglx-dev libx11-dev libgl-dev \
    | grep -v "^ " | grep -Ev "^debconf$|^$")
for pkg in $DEP_LIST; do
    sudo apt-get download "$pkg" 2>/dev/null || true
done
DEB_COUNT=$(ls ./*.deb 2>/dev/null | wc -l)
success "Downloaded $DEB_COUNT dependency package(s)."

# ── 3. Build Tools & Driver Utilities ─────────────────────────────
echo -e "\n${BOLD}[3/3] Packaging Build Tools & Driver Utils (nvidia-all-packages.zip)${NC}"
cd "$WORKDIR/nvidia-all-packages"
info "Downloading build toolchain..."
sudo apt-get download \
    dkms gcc make libc6-dev patch libglvnd-dev pkg-config libelf-dev \
    2>/dev/null || warn "Some build tools skipped."

info "Downloading NVIDIA open-driver utilities (v${DRIVER_VERSION})..."
sudo apt-get download \
    "nvidia-open-${DRIVER_VERSION}" \
    "nvidia-utils-${DRIVER_VERSION}" \
    "libnvidia-decode-${DRIVER_VERSION}" \
    "libnvidia-encode-${DRIVER_VERSION}" \
    2>/dev/null || warn "Some nvidia packages skipped – they may ship in the local .deb repo."
DEB_COUNT=$(ls ./*.deb 2>/dev/null | wc -l)
success "Downloaded $DEB_COUNT build/driver package(s)."

# ── Compress ──────────────────────────────────────────────────────
echo -e "\n${BOLD}Compressing bundles...${NC}"
cd "$WORKDIR"
zip -r "$HOME/nvidia-headers.zip"      nvidia-headers/
zip -r "$HOME/nvidia-deps.zip"         nvidia-deps/
zip -r "$HOME/nvidia-all-packages.zip" nvidia-all-packages/

# ── Summary ───────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Packaging Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "  ${BOLD}Transfer these 3 files + your driver .deb to the offline machine:${NC}"
ls -lh "$HOME"/nvidia-headers.zip "$HOME"/nvidia-deps.zip "$HOME"/nvidia-all-packages.zip
echo ""
echo -e "${YELLOW}⚠  Remember: also copy the NVIDIA Local Repo .deb from NVIDIA's website.${NC}"
echo -e "${YELLOW}   (e.g. nvidia-driver-local-repo-ubuntu2404-580.105.08_1.0-1_arm64.deb)${NC}"
