# Wazuh Quick Start Guide

This guide will help you get Wazuh up and running in minutes.

## Step 1: Prerequisites Check

Before starting, ensure you have:
- Docker installed and running
- Docker Compose installed
- At least 4GB of available RAM
- At least 10GB of free disk space

Verify Docker is working:
```bash
docker --version
docker-compose --version
```

## Step 2: Install Wazuh

Run the installation script:
```bash
./wazuh.sh install
```

This will:
1. Generate SSL certificates for secure communication
2. Create configuration files
3. Pull Docker images
4. Start all services

The installation takes about 2-5 minutes depending on your internet connection.

## Step 3: Access the Dashboard

Once installation completes, open your browser and navigate to:
```
https://localhost:443
```

**Default credentials:**
- Username: `admin`
- Password: `SecretPassword`

⚠️ Your browser will show a security warning because we're using self-signed certificates. This is normal for local development. Click "Advanced" and proceed.

## Step 4: First Login

After logging in, you'll see the Wazuh Dashboard. Take a moment to explore:

1. **Overview** - Shows security events summary
2. **Agents** - Lists connected agents (currently empty)
3. **Modules** - Various security monitoring modules
4. **Settings** - Configuration options

## Step 5: Deploy Your First Agent

To monitor a system, install a Wazuh agent. Here are quick commands for different platforms:

### Linux (Ubuntu/Debian):
```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt-get update
apt-get install wazuh-agent -y

# Set manager address (use your server's IP or localhost if on same machine)
sed -i 's|MANAGER_IP|localhost|g' /var/ossec/etc/ossec.conf

# Start agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent
```

### Linux (RHEL/CentOS):
```bash
rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
cat > /etc/yum.repos.d/wazuh.repo << EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-\$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF

yum install wazuh-agent -y

# Set manager address
sed -i 's|MANAGER_IP|localhost|g' /var/ossec/etc/ossec.conf

# Start agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent
```

### Windows:
1. Download agent from: https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.0-1.msi
2. Run installer
3. Configure manager address: `localhost` (or your server IP)
4. Start the agent service

### macOS:
```bash
curl -o wazuh-agent.pkg https://packages.wazuh.com/4.x/macos/wazuh-agent-4.7.0-1.pkg
sudo installer -pkg wazuh-agent.pkg -target /
sudo /Library/Ossec/bin/wazuh-control start
```

## Step 6: Verify Agent Connection

1. Go back to the Wazuh Dashboard
2. Navigate to **Agents** in the left menu
3. You should see your agent listed (it may take 1-2 minutes to appear)
4. Click on the agent to see detailed information

## Step 7: Explore Security Events

Once agents are connected, they'll start sending security data:

1. Go to **Security Events** to see real-time alerts
2. Check **Integrity Monitoring** to track file changes
3. Review **Vulnerability Detection** for security issues
4. Explore **Security Configuration Assessment** for compliance

## Common First-Time Tasks

### View Real-Time Events
```bash
# Watch the manager logs
./wazuh.sh logs wazuh.manager

# Filter for specific agent
docker exec -it wazuh-manager tail -f /var/ossec/logs/alerts/alerts.json | grep "agent-id"
```

### Check Service Status
```bash
./wazuh.sh status
```

### Restart Services
```bash
./wazuh.sh restart
```

### Create Backup
```bash
./wazuh.sh backup
```

## Next Steps

Now that Wazuh is running:

1. **Customize Rules**: Configure custom detection rules for your environment
2. **Set Up Alerts**: Configure email or webhook notifications
3. **Add More Agents**: Deploy agents to all systems you want to monitor
4. **Configure Integrations**: Integrate with Slack, PagerDuty, etc.
5. **Review Compliance**: Check compliance with PCI-DSS, GDPR, etc.
6. **Tune Performance**: Adjust resource allocation based on your needs

## Troubleshooting

### Can't access dashboard?
```bash
# Check if services are running
./wazuh.sh status

# Check dashboard logs
./wazuh.sh logs wazuh.dashboard
```

### Agent not connecting?
```bash
# On agent machine, check agent status
sudo systemctl status wazuh-agent

# Check agent logs
sudo tail -f /var/ossec/logs/ossec.log
```

### Out of memory errors?
```bash
# Check Docker resources
docker stats

# Adjust memory in docker-compose.yml
# Increase OPENSEARCH_JAVA_OPTS value
```

## Getting Help

- Read the full README.md for detailed documentation
- Check [Wazuh documentation](https://documentation.wazuh.com/)
- Join [Wazuh community](https://groups.google.com/g/wazuh)
- Run `./wazuh.sh help` for management commands

## Security Reminder

🔒 **Important**: This quick start uses default passwords. For production use:
1. Change all default passwords
2. Replace self-signed certificates with proper SSL certificates
3. Configure firewall rules
4. Enable additional authentication mechanisms
5. Review and apply security best practices from the main README

---

**Congratulations!** You now have a working Wazuh security monitoring platform. Start exploring and securing your infrastructure!
