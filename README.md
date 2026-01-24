# INTMAX Node Monitoring

A Prometheus + Grafana monitoring environment for managing multiple INTMAX Block Builder nodes.

<img width="1160" height="463" alt="Dashboard Screenshot" src="https://github.com/user-attachments/assets/97fbc0f9-70e5-4ec4-8e82-458f945146b9" />

## Project Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    INTMAX Block Builder Operations                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. Block Builder Setup                                             │
│     └─ Launch nodes using official script (builder.sh)              │
│     └─ Details: wiki/About-INTMAX.md                                │
│                                                                     │
│  2. Operations Monitoring  ← This Project                           │
│     └─ Centralized management of multiple nodes                     │
│     └─ Visualization of rewards (ETH/sITX)                          │
│     └─ Anomaly detection and alerting                               │
│                                                                     │
│  3. Reward Collection                                               │
│     └─ Automatic collection script (optional)                       │
│     └─ Manual collection via INTMAX CLI                             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

After launching Block Builder, **set up the monitoring environment with this project** to:

- View status of multiple nodes on a single dashboard
- Detect node downtime immediately
- Visualize accumulated rewards in graphs
- Monitor wallet balance (gas fees)

## Features

- Raspberry Pi compatible (64-bit)
- One-liner installation
- Reward monitoring & automatic collection (optional)
- 3 months of history retention

## Quick Start

### Monitoring Server

```bash
git clone https://github.com/Taiyou/intmax-node-monitoring-en.git
cd intmax-node-monitoring-en/server

cp .env.example .env
cp prometheus/targets/builders.yml.example prometheus/targets/builders.yml
# Edit builders.yml to add target node IPs

docker compose up -d
```

- Grafana: http://localhost:3000 (admin/admin)
- Prometheus: http://localhost:9090

### Each Node

```bash
curl -fsSL https://raw.githubusercontent.com/Taiyou/intmax-node-monitoring-en/main/agent/setup.sh | sudo bash
```

Create configuration file `/etc/default/intmax-builder-metrics`:
```bash
NODE_NAME="builder-01"
BUILDER_CONTAINER_NAME="block-builder"
BUILDER_DATA_DIR="/home/pi/intmax2"
```

## Documentation

| Page | Description |
|------|-------------|
| [About INTMAX](../../wiki/About-INTMAX) | Block Builder overview, setup, and reward structure |
| [Server Setup](../../wiki/Setup-Server) | Prometheus + Grafana setup |
| [Node Setup](../../wiki/Setup-Node) | Agent setup for each node |
| [Rewards](../../wiki/Rewards) | Reward monitoring and automatic collection |
| [Raspberry Pi](../../wiki/Raspberry-Pi) | Compatible models and notes |
| [Troubleshooting](../../wiki/Troubleshooting) | Common issues and solutions |

## Structure

```
├── agent/              # Node-side agent
├── server/             # Monitoring server (Docker)
│   ├── prometheus/     # Metrics collection
│   ├── wallet-exporter/  # Wallet balance retrieval
│   ├── reward-exporter/  # Reward balance retrieval
│   └── scripts/        # Auto-collection scripts
└── grafana/            # Dashboard
```

## License

MIT License
