#!/usr/bin/env bash
set -euo pipefail

#=============================================================================
# INTMAX Builder Monitoring Agent - Remote Setup Script
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Taiyou/intmax-node-monitoring-en/main/agent/setup.sh | sudo bash
#
# Or use git clone:
#   git clone https://github.com/Taiyou/intmax-node-monitoring-en.git /tmp/intmax-monitoring
#   cd /tmp/intmax-monitoring/agent && sudo ./install.sh
#=============================================================================

# GitHub repository settings (change when forking)
GITHUB_USER="${GITHUB_USER:-Taiyou}"
GITHUB_REPO="${GITHUB_REPO:-intmax-node-monitoring-en}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

# Installation directory
INSTALL_DIR="${INSTALL_DIR:-/opt/intmax-monitoring}"

# Colored output
info()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
ok()    { echo -e "\033[1;32m[OK]\033[0m $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; exit 1; }

# Root check
[[ $EUID -eq 0 ]] || error "Please run with root privileges: curl ... | sudo bash"

# Check required commands
check_requirements() {
    local missing=()
    for cmd in curl tar; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Required commands not found: ${missing[*]}"
    fi
}

# Download agent files from GitHub
download_files() {
    local base_url="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/agent"

    info "Downloading files..."
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    # Download required files
    for file in install.sh intmax_builder_metrics.sh uninstall.sh; do
        info "  -> ${file}"
        curl -fsSL "${base_url}/${file}" -o "${file}"
        chmod +x "${file}"
    done

    ok "Download complete: $INSTALL_DIR"
}

# Main process
main() {
    echo "========================================"
    echo " INTMAX Builder Monitoring Agent"
    echo " Remote Setup"
    echo "========================================"
    echo
    info "GitHub: ${GITHUB_USER}/${GITHUB_REPO} (${GITHUB_BRANCH})"
    echo

    check_requirements
    download_files

    echo
    info "Running installation..."
    echo

    # Run install.sh
    cd "$INSTALL_DIR"
    ./install.sh

    echo
    ok "Setup complete!"
    echo
    info "Scripts location: $INSTALL_DIR"
    info "Uninstall: sudo ${INSTALL_DIR}/uninstall.sh"
}

main "$@"
