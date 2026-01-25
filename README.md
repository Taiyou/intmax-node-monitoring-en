# INTMAX Node Monitoring

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)
[![Prometheus](https://img.shields.io/badge/Prometheus-2.45+-orange.svg)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-10.0+-green.svg)](https://grafana.com/)

A monitoring system for INTMAX Block Builder nodes with Prometheus and Grafana dashboards.

**[日本語版はこちら](https://github.com/Taiyou/intmax-node-monitoring)**

<img width="1160" height="463" alt="Dashboard Screenshot" src="https://github.com/user-attachments/assets/97fbc0f9-70e5-4ec4-8e82-458f945146b9" />

---

## Overview

When operating INTMAX Block Builders, you may face these challenges:

| Challenge | Solution |
|-----------|----------|
| Tedious to check multiple nodes | Dashboard displays all nodes at once |
| Hard to notice node outages | Status monitoring and alerts |
| Don't know how much rewards accumulated | Graph display of ETH/sITX balance |
| Worried about wallet gas fees | Balance monitoring with history |
| Forget to collect rewards | Automatic collection script (optional) |

## Prerequisites

| Component | Requirement |
|-----------|-------------|
| OS | Ubuntu 20.04+ / Debian 11+ |
| Docker | 20.10+ |
| Docker Compose | v2.0+ |
| Memory | 2GB+ (4GB recommended) |
| Storage | 10GB+ |
| Network | Port 9100 open for metrics |

## Quick Start

### Step 1: Set Up Block Builder

If you haven't started your Block Builder yet, refer to [About INTMAX](wiki/About-INTMAX.md) for setup instructions.

### Step 2: Set Up Monitoring Server

```bash
# Clone repository
git clone https://github.com/Taiyou/intmax-node-monitoring-en.git
cd intmax-node-monitoring-en/server

# Configure environment
cp .env.example .env
nano .env  # Edit settings

# Configure target nodes
cp prometheus/targets/builders.yml.example prometheus/targets/builders.yml
nano prometheus/targets/builders.yml

# Start services
docker compose up -d
```

Access Grafana: http://localhost:3000 (default: admin/admin)

For details, see [Server Setup](wiki/Setup-Server.md).

### Step 3: Install Agent on Each Node

Run on each Block Builder node:

```bash
curl -fsSL https://raw.githubusercontent.com/Taiyou/intmax-node-monitoring-en/main/agent/setup.sh | sudo bash
```

For details, see [Node Setup](wiki/Setup-Node.md).

### Step 4: Configure Reward Monitoring (Optional)

To monitor ETH rewards and wallet balances, see [Rewards](wiki/Rewards.md).

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            Monitoring Server                                 │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         Docker Compose                               │   │
│  │                                                                      │   │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐  │   │
│  │  │   Prometheus    │    │     Grafana     │    │ Wallet Exporter │  │   │
│  │  │   (port 9090)   │◄───│   (port 3000)   │    │   (port 9101)   │  │   │
│  │  │                 │    │                 │    │                 │  │   │
│  │  │  • Time series  │    │  • Dashboards   │    │  • ETH balance  │  │   │
│  │  │  • Alert rules  │    │  • Alerts       │    │  • sITX balance │  │   │
│  │  │  • 90d retention│    │  • Graphs       │    │  • Scroll RPC   │  │   │
│  │  └────────┬────────┘    └─────────────────┘    └────────┬────────┘  │   │
│  │           │                                              │           │   │
│  │           │  Scrape every 15 seconds                     │ HTTP/RPC  │   │
│  │           │                                              │           │   │
│  │  ┌────────┴────────┐                           ┌────────▼────────┐  │   │
│  │  │ Reward Exporter │                           │  Scroll Network │  │   │
│  │  │   (port 9102)   │                           │                 │  │   │
│  │  │                 │                           │  (Blockchain)   │  │   │
│  │  │  • SSH to nodes │                           └─────────────────┘  │   │
│  │  │  • CLI balance  │                                                │   │
│  │  └────────┬────────┘                                                │   │
│  │           │ SSH                                                     │   │
│  └───────────┼─────────────────────────────────────────────────────────┘   │
│              │                                                              │
└──────────────┼──────────────────────────────────────────────────────────────┘
               │
               │ Metrics scrape (HTTP :9100)
               │
    ┌──────────┴──────────┬───────────────────┬───────────────────┐
    │                     │                   │                   │
    ▼                     ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌───────────┐
│   Node 1        │ │   Node 2        │ │   Node 3        │ │  Node N   │
│ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │ │           │
│ │Block Builder│ │ │ │Block Builder│ │ │ │Block Builder│ │ │    ...    │
│ │  (Docker)   │ │ │ │  (Docker)   │ │ │ │  (Docker)   │ │ │           │
│ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │ │           │
│ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │ │           │
│ │node_exporter│ │ │ │node_exporter│ │ │ │node_exporter│ │ │           │
│ │ (port 9100) │ │ │ │ (port 9100) │ │ │ │ (port 9100) │ │ │           │
│ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │ │           │
│ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │ │           │
│ │Metrics Cron │ │ │ │Metrics Cron │ │ │ │Metrics Cron │ │ │           │
│ │ (1-5 min)   │ │ │ │ (1-5 min)   │ │ │ │ (1-5 min)   │ │ │           │
│ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │ │           │
└─────────────────┘ └─────────────────┘ └─────────────────┘ └───────────┘
```

## Key Metrics

| Metric | Description | Update Interval |
|--------|-------------|-----------------|
| `intmax_builder_up` | Agent running status | 1-5 min |
| `intmax_builder_container_running` | Docker container status | 1-5 min |
| `intmax_wallet_eth` | Wallet ETH balance | 1 hour |
| `intmax_wallet_sitx` | Wallet sITX balance | 1 hour |
| `intmax_builder_reward_eth` | Pending ETH rewards | 1 hour |
| `intmax_builder_reward_sitx` | Pending sITX rewards | 1 hour |

For the complete list, see [Metrics Reference](wiki/Metrics.md).

## Documentation

### Getting Started
| Page | Description |
|------|-------------|
| [About INTMAX](wiki/About-INTMAX.md) | Block Builder overview, setup, reward structure |
| [Server Setup](wiki/Setup-Server.md) | Prometheus + Grafana setup |
| [Node Setup](wiki/Setup-Node.md) | Agent setup on each node |

### Operations
| Page | Description |
|------|-------------|
| [Rewards](wiki/Rewards.md) | Reward monitoring and automatic collection |
| [Metrics Reference](wiki/Metrics.md) | Complete list of collected metrics and PromQL examples |
| [Upgrading](wiki/Upgrading.md) | How to upgrade the monitoring system |

### Reference
| Page | Description |
|------|-------------|
| [Security Best Practices](wiki/Security.md) | Security recommendations and hardening |
| [Raspberry Pi](wiki/Raspberry-Pi.md) | Supported models and considerations |
| [Troubleshooting & FAQ](wiki/Troubleshooting.md) | Common issues, solutions, and FAQ |

## Directory Structure

```
intmax-node-monitoring-en/
├── agent/                    # Node agent
│   ├── install.sh           # Installation script
│   ├── setup.sh             # Remote setup script
│   └── intmax_builder_metrics.sh  # Metrics collection script
├── server/                   # Monitoring server
│   ├── docker-compose.yml   # Docker Compose config
│   ├── .env.example         # Environment variables template
│   └── prometheus/          # Prometheus config
├── grafana/                  # Grafana config
│   └── dashboards/          # Dashboard JSON files
└── wiki/                     # Documentation
```

## Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

## License

This project is licensed under the [MIT License](LICENSE).

## Related Links

- [INTMAX Official](https://intmax.io/)
- [INTMAX Documentation](https://docs.network.intmax.io/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
