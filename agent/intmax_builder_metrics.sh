#!/usr/bin/env bash
#=============================================================================
# INTMAX Builder Metrics Collection Script
#
# Collects metrics about the INTMAX Builder and outputs in Prometheus format.
# Results are written to textfile_collector for node_exporter to read.
#=============================================================================

set -euo pipefail

# Configuration
CONFIG_FILE="${CONFIG_FILE:-/etc/default/intmax-builder-metrics}"
TEXTFILE_DIR="${TEXTFILE_DIR:-/var/lib/node_exporter/textfile_collector}"
OUTPUT_FILE="${TEXTFILE_DIR}/intmax_builder.prom"

# Default values
NODE_NAME="${NODE_NAME:-unknown}"
BUILDER_CONTAINER_NAME="${BUILDER_CONTAINER_NAME:-block-builder}"
BUILDER_DATA_DIR="${BUILDER_DATA_DIR:-/home/pi/intmax2}"

# Load config file
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

# Create output directory if it doesn't exist
mkdir -p "$TEXTFILE_DIR"

# Temporary file
TMP_FILE="${OUTPUT_FILE}.tmp"

# Start writing metrics
cat > "$TMP_FILE" << EOF
# HELP intmax_builder_up Whether the builder monitoring script is running
# TYPE intmax_builder_up gauge
intmax_builder_up{node="${NODE_NAME}"} 1

# HELP intmax_builder_last_scrape_timestamp Unix timestamp of last metrics collection
# TYPE intmax_builder_last_scrape_timestamp gauge
intmax_builder_last_scrape_timestamp{node="${NODE_NAME}"} $(date +%s)
EOF

#-----------------------------------------------------------------------------
# Docker Container Status
#-----------------------------------------------------------------------------

# Check if container is running
container_running=0
container_id=""

if command -v docker &>/dev/null; then
    # Search for container matching the name
    container_id=$(docker ps --filter "name=${BUILDER_CONTAINER_NAME}" --format "{{.ID}}" 2>/dev/null | head -n1)
    if [[ -n "$container_id" ]]; then
        container_running=1
    fi
fi

cat >> "$TMP_FILE" << EOF

# HELP intmax_builder_container_running Whether the Docker container is running (1=running, 0=stopped)
# TYPE intmax_builder_container_running gauge
intmax_builder_container_running{node="${NODE_NAME}"} ${container_running}
EOF

#-----------------------------------------------------------------------------
# Process Status (alternative to Docker)
#-----------------------------------------------------------------------------

process_running=0
if pgrep -f "intmax" &>/dev/null || pgrep -f "block-builder" &>/dev/null; then
    process_running=1
fi

cat >> "$TMP_FILE" << EOF

# HELP intmax_builder_process_running Whether an INTMAX-related process is running
# TYPE intmax_builder_process_running gauge
intmax_builder_process_running{node="${NODE_NAME}"} ${process_running}
EOF

#-----------------------------------------------------------------------------
# Container Uptime
#-----------------------------------------------------------------------------

uptime_seconds=0
if [[ -n "$container_id" ]]; then
    # Get container start time
    started_at=$(docker inspect --format '{{.State.StartedAt}}' "$container_id" 2>/dev/null || echo "")
    if [[ -n "$started_at" ]]; then
        # Convert to Unix timestamp
        if command -v date &>/dev/null; then
            start_ts=$(date -d "$started_at" +%s 2>/dev/null || date -jf "%Y-%m-%dT%H:%M:%S" "${started_at%%.*}" +%s 2>/dev/null || echo "0")
            now_ts=$(date +%s)
            if [[ "$start_ts" -gt 0 ]]; then
                uptime_seconds=$((now_ts - start_ts))
            fi
        fi
    fi
fi

cat >> "$TMP_FILE" << EOF

# HELP intmax_builder_uptime_seconds Container uptime in seconds
# TYPE intmax_builder_uptime_seconds gauge
intmax_builder_uptime_seconds{node="${NODE_NAME}"} ${uptime_seconds}
EOF

#-----------------------------------------------------------------------------
# Health Check (HTTP)
#-----------------------------------------------------------------------------

health_ok=0
if [[ $container_running -eq 1 ]]; then
    # Try to access health endpoint
    if curl -sf --max-time 5 "http://localhost:8080/health-check" &>/dev/null; then
        health_ok=1
    elif curl -sf --max-time 5 "http://localhost:80/health-check" &>/dev/null; then
        health_ok=1
    fi
fi

cat >> "$TMP_FILE" << EOF

# HELP intmax_builder_health_ok Whether health check passed (1=healthy, 0=unhealthy)
# TYPE intmax_builder_health_ok gauge
intmax_builder_health_ok{node="${NODE_NAME}"} ${health_ok}
EOF

#-----------------------------------------------------------------------------
# Data Directory Size
#-----------------------------------------------------------------------------

data_dir_exists=0
data_dir_bytes=0

if [[ -d "$BUILDER_DATA_DIR" ]]; then
    data_dir_exists=1
    # Get directory size in bytes
    data_dir_bytes=$(du -sb "$BUILDER_DATA_DIR" 2>/dev/null | cut -f1 || echo "0")
fi

cat >> "$TMP_FILE" << EOF

# HELP intmax_builder_data_dir_exists Whether the data directory exists
# TYPE intmax_builder_data_dir_exists gauge
intmax_builder_data_dir_exists{node="${NODE_NAME}"} ${data_dir_exists}

# HELP intmax_builder_data_dir_bytes Data directory size in bytes
# TYPE intmax_builder_data_dir_bytes gauge
intmax_builder_data_dir_bytes{node="${NODE_NAME}"} ${data_dir_bytes}
EOF

#-----------------------------------------------------------------------------
# Overall Ready Status
#-----------------------------------------------------------------------------

# Builder is ready if container is running and health check passes
ready=0
if [[ $container_running -eq 1 ]] && [[ $health_ok -eq 1 ]]; then
    ready=1
elif [[ $container_running -eq 1 ]]; then
    # Health check may not be available, consider ready if container is running
    ready=1
fi

cat >> "$TMP_FILE" << EOF

# HELP intmax_builder_ready Overall builder ready status (1=ready, 0=not ready)
# TYPE intmax_builder_ready gauge
intmax_builder_ready{node="${NODE_NAME}"} ${ready}
EOF

#-----------------------------------------------------------------------------
# Finalize
#-----------------------------------------------------------------------------

# Atomically move temp file to output
mv "$TMP_FILE" "$OUTPUT_FILE"

# Set permissions for node_exporter to read
chmod 644 "$OUTPUT_FILE"
