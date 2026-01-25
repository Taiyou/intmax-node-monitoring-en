# Security Best Practices

This document describes security recommendations when operating the INTMAX Node Monitoring system.

## Overview

The monitoring system handles the following sensitive information:
- SSH keys for node access
- Wallet addresses
- spend-key files for reward claims
- Network topology information

Follow these guidelines to minimize security risks.

---

## File Permissions

### Configuration Files

```bash
# .env file (contains sensitive settings)
chmod 600 server/.env
chown $USER:$USER server/.env

# SSH private key
chmod 600 ~/.ssh/id_ed25519
chown $USER:$USER ~/.ssh/id_ed25519

# spend-key file on nodes
sudo chmod 644 /etc/intmax-builder/spend-key
sudo chown root:root /etc/intmax-builder/spend-key
```

### Docker Socket

Restrict Docker socket access to necessary users only:

```bash
# Check current permissions
ls -la /var/run/docker.sock

# Add only trusted users to docker group
sudo usermod -aG docker <username>
```

---

## Network Security

### Firewall Configuration

Configure firewall rules to restrict access:

```bash
# Allow metrics collection only from monitoring server
sudo ufw allow from <monitoring-server-ip> to any port 9100

# Restrict Grafana access (optional - internal network only)
sudo ufw allow from 192.168.0.0/16 to any port 3000

# Deny public access to Prometheus
sudo ufw deny 9090
```

### Recommended Firewall Rules

| Port | Service | Recommendation |
|------|---------|----------------|
| 9100 | node_exporter | Allow only from monitoring server IP |
| 9090 | Prometheus | Internal access only (do not expose) |
| 3000 | Grafana | Internal network or VPN only |
| 22 | SSH | Key authentication only, consider port change |

### SSH Hardening

Edit `/etc/ssh/sshd_config`:

```bash
# Disable password authentication
PasswordAuthentication no

# Allow only specific users
AllowUsers your-username

# Disable root login
PermitRootLogin no

# Use SSH protocol 2 only
Protocol 2
```

Restart SSH service:
```bash
sudo systemctl restart sshd
```

---

## Credential Management

### Environment Variables

Do not commit sensitive data to version control:

```bash
# Items to include in .gitignore:
.env
server/.env
prometheus/targets/builders.yml
scripts/claim_config.env
```

### SSH Key Management

1. **Use ED25519 keys** (more secure than RSA):
   ```bash
   ssh-keygen -t ed25519 -C "monitoring-server"
   ```

2. **Separate keys by purpose**:
   - Key for monitoring (read-only operations)
   - Key for reward claiming (if automating)

3. **Restrict SSH key usage**:
   On the node, edit `~/.ssh/authorized_keys` to restrict commands the SSH key can execute:
   ```bash
   command="cd /home/user/intmax2/cli && ./target/release/intmax2-cli balance --private-key $(cat /etc/intmax-builder/spend-key)",no-port-forwarding,no-X11-forwarding ssh-ed25519 AAAA... monitoring-key
   ```

### spend-key Security

The spend-key is used for:
- Checking reward balance
- Claiming rewards

It **cannot** be used for:
- Transferring funds from wallet
- Accessing other accounts

However, protection is needed because:
- Anyone with the key can claim rewards
- It reveals the association with your wallet

**Recommendations:**
1. Store in `/etc/intmax-builder/` with restricted permissions
2. Do not include in backups that leave the server
3. Rotate if compromise is suspected

---

## Docker Security

### Run Containers as Non-root

The exporters in this project run as non-root by default. Verify:

```bash
docker compose exec wallet-exporter whoami
```

### Limit Container Capabilities

The `docker-compose.yml` already limits capabilities. Do not change unless necessary:

```yaml
security_opt:
  - no-new-privileges:true
```

### Use Read-only Volumes When Possible

```yaml
volumes:
  - ./config:/config:ro  # Read-only mount
```

---

## Monitoring Security

### Grafana Security

1. **Change default password immediately**:
   ```bash
   # Set in .env
   GRAFANA_ADMIN_PASSWORD=your-strong-password
   ```

2. **Enable HTTPS** (recommended for production):
   Use a reverse proxy (nginx, Traefik) with SSL certificates.

3. **Disable anonymous access**:
   Disabled by default in this configuration.

### Prometheus Security

1. **Do not expose Prometheus publicly**:
   Prometheus has no built-in authentication. Keep it internal.

2. **Use reverse proxy for external access**:
   ```nginx
   # nginx configuration example
   location /prometheus/ {
       auth_basic "Prometheus";
       auth_basic_user_file /etc/nginx/.htpasswd;
       proxy_pass http://localhost:9090/;
   }
   ```

---

## Backup Security

### What to Backup

| Item | Location | Sensitivity |
|------|----------|-------------|
| Grafana dashboards | `grafana/dashboards/` | Low |
| Prometheus data | Docker volume `prom_data` | Medium |
| Configuration | `.env`, `builders.yml` | High |
| SSH keys | `~/.ssh/` | **Critical** |

### Backup Recommendations

1. **Encrypt backups** before storing offsite
2. **Do not backup** spend-key files unless necessary
3. **Test restores** regularly

```bash
# Example: Encrypted backup
tar -czf - server/.env prometheus/targets/ | gpg -c > backup-$(date +%Y%m%d).tar.gz.gpg
```

---

## Incident Response

### If SSH Key is Compromised

1. **Immediately** regenerate the key:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
   ```

2. Remove old key from all nodes:
   ```bash
   # Edit authorized_keys on each node
   nano ~/.ssh/authorized_keys
   # Remove the line with the compromised key
   ```

3. Add the new key to all nodes

### If spend-key is Compromised

1. **Immediately claim all pending rewards**:
   ```bash
   ./intmax2-cli claim --private-key 0xYOUR_SPEND_KEY
   ```

2. Rewards are sent to registered wallet (requires different key to access)

3. Generate a new spend-key with INTMAX CLI

### If Monitoring Server is Compromised

1. Stop all services immediately:
   ```bash
   docker compose down
   ```

2. Rotate all SSH keys

3. Change Grafana password

4. Check access logs:
   ```bash
   docker compose logs > incident-logs.txt
   ```

5. Rebuild from clean installation

---

## Security Checklist

Before deploying to production:

- [ ] Changed default Grafana password
- [ ] Configured firewall rules
- [ ] SSH key authentication only
- [ ] `.env` file permissions restricted (600)
- [ ] Prometheus not publicly exposed
- [ ] Docker socket access restricted
- [ ] Proper permissions on spend-key files
- [ ] Backup strategy in place
- [ ] Monitoring server on separate network segment (if possible)

---

## Reporting Security Issues

If you discover a security vulnerability in this project:

1. **Do not** open a public GitHub issue
2. Contact maintainers directly
3. Provide details of the vulnerability
4. Allow time for fix before disclosure
