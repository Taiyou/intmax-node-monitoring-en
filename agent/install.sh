#!/usr/bin/env bash
set -euo pipefail

#=============================================================================
# INTMAX Builder Monitoring Agent - Installation Script
#
# Installs:
# - node_exporter (Prometheus metrics exporter)
# - intmax_builder_metrics.sh (custom metrics collection)
# - cron job (metrics update every minute)
#=============================================================================

# node_exporter version
NODE_EXPORTER_VERSION="1.8.2"
TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"

# Colored output
info()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
ok()    { echo -e "\033[1;32m[OK]\033[0m $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; exit 1; }

# Root check
[[ $EUID -eq 0 ]] || error "Please run with root privileges: sudo $0"

# Architecture detection
detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7l)  echo "armv7" ;;
        *)       error "Unsupported architecture: $arch" ;;
    esac
}

# Create node_exporter user
create_user() {
    if ! id -u node_exporter &>/dev/null; then
        useradd --no-create-home --shell /bin/false node_exporter
        ok "Created node_exporter user"
    fi
}

# Install node_exporter
install_node_exporter() {
    if [[ -f /usr/local/bin/node_exporter ]]; then
        warn "node_exporter is already installed"
        return 0
    fi

    local arch
    arch=$(detect_arch)
    local url="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${arch}.tar.gz"

    info "Downloading node_exporter (v${NODE_EXPORTER_VERSION}, ${arch})..."
    cd /tmp
    curl -fsSL "$url" -o node_exporter.tar.gz
    tar xzf node_exporter.tar.gz
    cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-${arch}/node_exporter" /usr/local/bin/
    chmod +x /usr/local/bin/node_exporter
    rm -rf node_exporter.tar.gz "node_exporter-${NODE_EXPORTER_VERSION}.linux-${arch}"

    ok "node_exporter installed"
}

# Configure systemd service
setup_systemd() {
    info "Configuring systemd service..."

    # Create textfile collector directory
    mkdir -p "$TEXTFILE_DIR"
    chown node_exporter:node_exporter "$TEXTFILE_DIR"

    cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory=/var/lib/node_exporter/textfile_collector
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl start node_exporter

    ok "systemd service configured and started"
}

# Copy metrics script
copy_scripts() {
    local script_dir
    script_dir=$(dirname "$(readlink -f "$0")")

    info "Copying metrics script..."

    # Determine destination directory
    local dest_dir="/opt/intmax-monitoring"
    mkdir -p "$dest_dir"

    # Copy script
    if [[ -f "${script_dir}/intmax_builder_metrics.sh" ]]; then
        cp "${script_dir}/intmax_builder_metrics.sh" "$dest_dir/"
        chmod +x "$dest_dir/intmax_builder_metrics.sh"
        ok "Script copied"
    else
        error "intmax_builder_metrics.sh not found in ${script_dir}"
    fi
}

# Setup cron job
setup_cron() {
    info "Setting up cron job..."

    local cron_entry="* * * * * /opt/intmax-monitoring/intmax_builder_metrics.sh > /dev/null 2>&1 # intmax-builder-metrics"

    # Remove existing entry if present
    crontab -l 2>/dev/null | grep -v "intmax-builder-metrics" | crontab - 2>/dev/null || true

    # Add new entry
    (crontab -l 2>/dev/null || true; echo "$cron_entry") | crontab -

    ok "cron job configured"
}

# Create default config file
create_default_config() {
    local config_file="/etc/default/intmax-builder-metrics"

    if [[ -f "$config_file" ]]; then
        warn "Config file already exists: $config_file"
        return 0
    fi

    info "Creating default config file..."

    cat > "$config_file" << 'EOF'
# INTMAX Builder Monitoring Agent Configuration
#
# NODE_NAME: Name displayed in Grafana (e.g., builder-01)
# BUILDER_CONTAINER_NAME: Docker container name (partial match OK)
# BUILDER_DATA_DIR: intmax2 data directory

NODE_NAME="builder-01"
BUILDER_CONTAINER_NAME="block-builder"
BUILDER_DATA_DIR="/home/pi/intmax2"
EOF

    ok "Default config file created: $config_file"
}

# Main process
main() {
    echo "========================================"
    echo " INTMAX Builder Monitoring Agent"
    echo " Installation"
    echo "========================================"
    echo

    create_user
    install_node_exporter
    setup_systemd
    copy_scripts
    create_default_config
    setup_cron

    # Run metrics collection once
    /opt/intmax-monitoring/intmax_builder_metrics.sh 2>/dev/null || true

    echo
    ok "Installation complete!"
    echo
    info "Next steps:"
    echo "  1. Edit config file: sudo nano /etc/default/intmax-builder-metrics"
    echo "  2. Verify metrics: curl localhost:9100/metrics | grep intmax"
    echo
}

main "$@"
