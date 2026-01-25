# Troubleshooting & FAQ

## Frequently Asked Questions (FAQ)

### General Questions

**Q: What are the minimum system requirements for the monitoring server?**

A: For the monitoring server:
- CPU: 2 cores
- RAM: 2GB (4GB recommended)
- Storage: 10GB+ (depending on retention period)
- Docker and Docker Compose installed

**Q: Can I run the monitoring server on the same machine as Block Builder?**

A: Yes, but not recommended for production. The monitoring server uses additional resources which may impact Block Builder performance. It's fine for testing purposes.

**Q: How long is data retained?**

A: By default, Prometheus retains data for 90 days. You can adjust this by setting `PROMETHEUS_RETENTION` in the `.env` file:
```bash
PROMETHEUS_RETENTION=30d   # 30 days
PROMETHEUS_RETENTION=90d   # 90 days (default)
PROMETHEUS_RETENTION=180d  # 180 days
```

**Q: Can I monitor nodes on different networks (different subnets)?**

A: Yes, as long as the monitoring server can reach nodes on port 9100. For nodes on different networks, you may need to configure firewall rules or use a VPN.

**Q: Do I need to restart services after configuration changes?**

A: Yes. After changing `.env` or `builders.yml`, restart services:
```bash
docker compose down && docker compose up -d
```

### Reward Monitoring

**Q: Why does reward monitoring require SSH access?**

A: The reward exporter needs to run the INTMAX CLI `balance` command on each node to fetch pending rewards. This requires SSH access to execute commands remotely.

**Q: Is it safe to store the spend-key on nodes?**

A: The spend-key is only used for balance checking and reward claiming. It cannot be used to transfer funds elsewhere. However, follow these security practices:
- Set proper file permissions (`chmod 644`)
- Restrict SSH access with key-based authentication
- See [Security Best Practices](Security) for details

**Q: Can I automatically claim rewards?**

A: Yes, you can set up automatic reward claiming using the `claim_rewards.sh` script with cron. See [Rewards](Rewards) for configuration details.

### Dashboard and Visualization

**Q: Why does the dashboard show "No data"?**

A: This usually means:
1. Prometheus cannot reach nodes (check `builders.yml` configuration)
2. node_exporter is not running on target nodes
3. Firewall is blocking port 9100

Check Prometheus targets at http://localhost:9090/targets

**Q: Can I create custom dashboards?**

A: Yes, you can create custom dashboards in Grafana. The existing dashboard is a starting point. You can export custom dashboards as JSON and place them in `grafana/dashboards/` to persist them.

**Q: How do I change the dashboard refresh interval?**

A: In Grafana, click the refresh icon in the top right and select your preferred interval (5s, 10s, 30s, 1m, etc.).

---

## 404 Error During Installation

### Symptom
```
curl: (22) The requested URL returned error: 404
```

### Cause
GitHub CDN cache not updated

### Solution

**Method 1: Use git clone**
```bash
git clone https://github.com/Taiyou/intmax-node-monitoring-en.git /tmp/intmax-monitoring
cd /tmp/intmax-monitoring/agent
sudo ./install.sh
```

**Method 2: Wait and retry**
```bash
curl -fsSL https://raw.githubusercontent.com/Taiyou/intmax-node-monitoring-en/main/agent/setup.sh | sudo bash
```

---

## Metrics Not Being Collected

### Check if node_exporter is running
```bash
sudo systemctl status node_exporter
curl localhost:9100/metrics | head
```

### Check firewall
```bash
sudo ufw status
sudo ufw allow 9100/tcp
```

---

## "No data" in Grafana

### Check if Prometheus can connect to nodes
Prometheus UI (http://localhost:9090) → Status → Targets

### Check if builders.yml IPs are correct
```bash
cat server/prometheus/targets/builders.yml
```

---

## Docker Container Not Detected

### Check container name
```bash
docker ps --format '{{.Names}}'
```

### Update BUILDER_CONTAINER_NAME in config
```bash
sudo nano /etc/default/intmax-builder-metrics
# BUILDER_CONTAINER_NAME="actual container name prefix"
```

---

## SSH Connection Error (Reward Monitoring)

### Check if public key is registered
```bash
# SSH manually from monitoring server
ssh user@192.168.1.10

# Check on node side
cat ~/.ssh/authorized_keys
```

### Add to known_hosts
```bash
ssh-keyscan 192.168.1.10 >> ~/.ssh/known_hosts
```

---

## spend-key Related Errors

### Check if file exists
```bash
ls -la /etc/intmax-builder/spend-key
```

### Check permissions
```bash
sudo chmod 644 /etc/intmax-builder/spend-key
sudo chown $USER:$USER /etc/intmax-builder/spend-key
```

---

## Services Not Starting After Reboot

### Check Docker services
```bash
cd server
docker compose ps
docker compose up -d
```

### Check node_exporter
```bash
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
```

---

## Block Builder Setup Issues

### uuidgen not found

```
❌ Missing required tools: uuidgen
```

**Solution:**
```bash
sudo apt install -y uuid-runtime
```

### Mainnet/Testnet Mismatch

```
🚨 NETWORK MISMATCH DETECTED!
Expected: Chain ID 534351 (Scroll Sepolia Testnet)
Actual: Chain ID 534352
```

**Solution:**

For Mainnet operation, download the Mainnet script:
```bash
curl -o builder.sh https://raw.githubusercontent.com/InternetMaximalism/intmax2/refs/heads/main/scripts/block-builder-mainnet.sh
chmod +x builder.sh
./builder.sh clean && ./builder.sh setup
```

---

## CLI Build Errors

### OpenSSL not found

```
Could not find directory of OpenSSL installation
```

**Solution:**
```bash
sudo apt install -y libssl-dev pkg-config
cargo build -r
```

### Build tools missing

```
error: linker `cc` not found
```

**Solution:**
```bash
sudo apt install -y build-essential
cargo build -r
```

---

## Diagnostic Commands

Commands to quickly diagnose common issues:

### Check Overall System Status

```bash
# On monitoring server
docker compose ps                    # Check service status
docker compose logs -f               # Show all logs
curl localhost:9090/-/healthy        # Prometheus health
curl localhost:3000/api/health       # Grafana health

# On each node
sudo systemctl status node_exporter  # node_exporter status
curl localhost:9100/metrics | grep intmax  # Check custom metrics
```

### Network Connection Test

```bash
# From monitoring server to nodes
nc -zv <node-ip> 9100               # Port connection test
curl http://<node-ip>:9100/metrics  # Fetch metrics directly
```

### SSH Connection Test (for reward monitoring)

```bash
# Test SSH access
ssh -v user@<node-ip> "echo 'SSH works'"

# Test CLI command
ssh user@<node-ip> "cd /path/to/intmax2/cli && ./target/release/intmax2-cli balance --private-key \$(cat /etc/intmax-builder/spend-key)"
```

---

## Getting Help

If you're still having issues:

1. Check [GitHub Issues](https://github.com/Taiyou/intmax-node-monitoring-en/issues) for known issues
2. Search existing issues before creating a new one
3. When reporting an issue, include:
   - Operating system and version
   - Docker and Docker Compose versions
   - Relevant log output
   - Steps to reproduce the problem
