# Troubleshooting

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
