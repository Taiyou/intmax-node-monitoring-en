#!/usr/bin/env bash
set -euo pipefail

#=============================================================================
# INTMAX Builder Monitoring Agent - Uninstall Script
#
# - Remove cron jobs
# - Stop and remove node_exporter
# - Clean up textfile collector directory
#=============================================================================

TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"

# Colored output
info()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
ok()    { echo -e "\033[1;32m[OK]\033[0m $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; exit 1; }

# Root check
[[ $EUID -eq 0 ]] || error "Please run with root privileges: sudo $0"

# Remove cron job
remove_cron() {
    info "Removing cron job..."
    local cron_marker="# intmax-builder-metrics"

    if crontab -l 2>/dev/null | grep -q "$cron_marker"; then
        crontab -l 2>/dev/null | grep -v "$cron_marker" | crontab -
        ok "Cron job removed"
    else
        warn "Cron job not found"
    fi
}

# Stop and remove node_exporter
remove_node_exporter() {
    info "Stopping and removing node_exporter..."

    # Stop systemd service
    if systemctl is-active --quiet node_exporter 2>/dev/null; then
        systemctl stop node_exporter
        ok "node_exporter service stopped"
    fi

    if systemctl is-enabled --quiet node_exporter 2>/dev/null; then
        systemctl disable node_exporter
    fi

    # Remove service file
    if [[ -f /etc/systemd/system/node_exporter.service ]]; then
        rm -f /etc/systemd/system/node_exporter.service
        systemctl daemon-reload
        ok "systemd service file removed"
    fi

    # Remove binary
    if [[ -f /usr/local/bin/node_exporter ]]; then
        rm -f /usr/local/bin/node_exporter
        ok "node_exporter binary removed"
    else
        warn "node_exporter binary not found"
    fi

    # Remove user (optional)
    if id -u node_exporter &>/dev/null; then
        userdel node_exporter 2>/dev/null || true
        ok "node_exporter user removed"
    fi
}

# Clean up textfile collector directory
cleanup_textfile_dir() {
    info "Cleaning up textfile collector directory..."

    if [[ -d "$TEXTFILE_DIR" ]]; then
        # Remove only INTMAX-related files
        rm -f "${TEXTFILE_DIR}/intmax_builder.prom"
        rm -f "${TEXTFILE_DIR}/intmax_builder.prom.tmp"

        # Remove directory if empty
        if [[ -z "$(ls -A "$TEXTFILE_DIR" 2>/dev/null)" ]]; then
            rmdir "$TEXTFILE_DIR" 2>/dev/null || true
            rmdir "$(dirname "$TEXTFILE_DIR")" 2>/dev/null || true
        fi

        ok "textfile collector files removed"
    else
        warn "textfile collector directory does not exist"
    fi
}

# Confirmation prompt
confirm() {
    echo "========================================"
    echo " INTMAX Builder Monitoring Agent"
    echo " Uninstall"
    echo "========================================"
    echo
    warn "The following will be removed:"
    echo "  - cron job (intmax-builder-metrics)"
    echo "  - node_exporter service and binary"
    echo "  - textfile collector files"
    echo

    read -rp "Continue? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            echo "Cancelled"
            exit 0
            ;;
    esac
}

# Main process
main() {
    # Skip confirmation with --yes option
    if [[ "${1:-}" != "--yes" ]] && [[ "${1:-}" != "-y" ]]; then
        confirm
    fi

    echo
    remove_cron
    remove_node_exporter
    cleanup_textfile_dir

    echo
    ok "Uninstall complete!"
}

main "$@"
