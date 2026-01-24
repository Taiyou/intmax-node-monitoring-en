# INTMAX Node Monitoring Wiki

## About This Project

When operating INTMAX Block Builder, you may face these challenges:

| Challenge | Solution |
|-----------|----------|
| Checking multiple nodes is tedious | Dashboard displays all nodes at once |
| Hard to notice when a node stops | Status monitoring and alerts |
| Don't know how much reward has accumulated | Graph display of ETH/sITX balance |
| Worried if wallet has enough gas | Balance monitoring and history display |
| Forget to collect rewards | Automatic collection script (optional) |

## Block Builder Operations Flow

```
┌──────────────────┐
│ 1. Node Setup    │  ← Launch with official builder.sh
└────────┬─────────┘
         ↓
┌──────────────────┐
│ 2. Monitoring    │  ← This Project
│   - Server setup │
│   - Agent setup  │
└────────┬─────────┘
         ↓
┌──────────────────┐
│ 3. Operations    │
│   - Dashboard    │
│   - Check rewards│
│   - Auto-collect │
└──────────────────┘
```

## Setup Guide

### Step 1: Launch Block Builder

If you haven't launched Block Builder yet, refer to [About INTMAX Block Builder](About-INTMAX) for setup.

### Step 2: Set Up Monitoring Server

Follow [Server Setup](Setup-Server) to build the Prometheus + Grafana environment.

### Step 3: Install Agent on Each Node

Follow [Node Setup](Setup-Node) to install the agent on each target node.

### Step 4: Configure Reward Monitoring (Optional)

To monitor ETH rewards and wallet balance, refer to [Rewards](Rewards).

## Table of Contents

| Page | Description |
|------|-------------|
| [About INTMAX Block Builder](About-INTMAX) | Block Builder overview, setup, and reward structure |
| [Server Setup](Setup-Server) | Prometheus + Grafana setup |
| [Node Setup](Setup-Node) | Agent setup for each node |
| [Rewards](Rewards) | Reward monitoring and automatic collection |
| [Raspberry Pi](Raspberry-Pi) | Compatible models and notes |
| [Troubleshooting](Troubleshooting) | Common issues and solutions |

## System Architecture

```
                    ┌─────────────────────────────────────┐
                    │         Monitoring Server           │
                    │  ┌───────────┐  ┌───────────┐      │
                    │  │ Prometheus │  │  Grafana  │      │
                    │  └─────┬─────┘  └───────────┘      │
                    │        │                            │
                    │  ┌─────┴─────┐                      │
                    │  │ Exporters │                      │
                    │  │ - wallet  │                      │
                    │  │ - reward  │                      │
                    │  └───────────┘                      │
                    └────────┬────────────────────────────┘
                             │ scrape (HTTP)
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   Node 1        │ │   Node 2        │ │   Node N        │
│ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │
│ │ Block       │ │ │ │ Block       │ │ │ │ Block       │ │
│ │ Builder     │ │ │ │ Builder     │ │ │ │ Builder     │ │
│ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │
│ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │
│ │node_exporter│ │ │ │node_exporter│ │ │ │node_exporter│ │
│ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```
