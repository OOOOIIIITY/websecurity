# Web Security - Wazuh SIEM Deployment

This repository provides an easy-to-use setup for installing, running, and managing [Wazuh](https://github.com/wazuh/wazuh), a free and open-source security monitoring platform.

## Overview

Wazuh is a comprehensive security platform that provides:
- **Intrusion Detection**: Real-time threat detection and security monitoring
- **Log Data Analysis**: Centralized log management and analysis
- **File Integrity Monitoring**: Detect unauthorized file changes
- **Vulnerability Detection**: Identify security vulnerabilities in your systems
- **Security Configuration Assessment**: Ensure systems meet security policies
- **Incident Response**: Automated response to security events
- **Regulatory Compliance**: Meet PCI-DSS, GDPR, HIPAA, and other requirements

## Architecture

This deployment includes three main components:
1. **Wazuh Manager**: Central server that analyzes data from agents
2. **Wazuh Indexer**: Indexes and stores security alerts
3. **Wazuh Dashboard**: Web interface for visualization and management

## Prerequisites

- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)
- At least 4GB RAM available for Docker
- At least 10GB free disk space

## Quick Start

### 1. Install Wazuh

```bash
./wazuh.sh install
```

This command will:
- Generate SSL certificates
- Create configuration files
- Start all Wazuh services
- Set up the complete security monitoring platform

### 2. Access the Dashboard

Once installation is complete, access the Wazuh Dashboard at:
- **URL**: https://localhost:443
- **Username**: admin
- **Password**: SecretPassword

⚠️ **Important**: You'll see a browser warning about the self-signed certificate. This is normal for local development. Click "Advanced" and proceed to the site.

### 3. Deploy Agents

To monitor systems, deploy Wazuh agents on the hosts you want to monitor. Agents send security data to the Wazuh Manager for analysis.

#### Linux Agent Installation:
```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt-get update
apt-get install wazuh-agent

# Configure manager address
echo "WAZUH_MANAGER='<your-manager-ip>'" > /var/ossec/etc/ossec.conf

# Start the agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent
```

## Management Commands

The `wazuh.sh` script provides easy management of your Wazuh deployment:

### Basic Operations

```bash
# Check status of all services
./wazuh.sh status

# Start services
./wazuh.sh start

# Stop services
./wazuh.sh stop

# Restart services
./wazuh.sh restart

# View logs (all services)
./wazuh.sh logs

# View logs for specific service
./wazuh.sh logs wazuh.manager
./wazuh.sh logs wazuh.indexer
./wazuh.sh logs wazuh.dashboard
```

### Advanced Operations

```bash
# Update Wazuh to latest version
./wazuh.sh update

# Backup Wazuh data
./wazuh.sh backup

# Uninstall Wazuh (removes all data)
./wazuh.sh uninstall

# Show help
./wazuh.sh help
```

## Configuration

### Default Credentials

**Wazuh Dashboard:**
- Username: `admin`
- Password: `SecretPassword`

**Wazuh API:**
- Username: `wazuh-wui`
- Password: `MyS3cr37P450r.*-`

⚠️ **Security Note**: Change these default passwords in production environments!

### Changing Passwords

1. **Dashboard Password:**
   Edit `config/wazuh_indexer/internal_users.yml` and generate a new hash:
   ```bash
   docker exec -it wazuh-indexer bash
   /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh -p <new-password>
   ```

2. **API Password:**
   Edit the environment variables in `docker-compose.yml`:
   ```yaml
   - API_PASSWORD=YourNewPassword
   ```

### Custom Configuration

Configuration files are stored in the `config/` directory:
- `config/wazuh_cluster/wazuh_manager.conf` - Wazuh Manager settings
- `config/wazuh_indexer/wazuh.indexer.yml` - Indexer settings
- `config/wazuh_dashboard/opensearch_dashboards.yml` - Dashboard settings
- `config/wazuh_dashboard/wazuh.yml` - Wazuh plugin settings

After modifying configurations, restart the affected services:
```bash
./wazuh.sh restart
```

## Ports

The following ports are exposed:
- `443` - Wazuh Dashboard (HTTPS)
- `1514` - Agent communication (TCP)
- `1515` - Agent enrollment service
- `514` - Syslog collector (UDP)
- `55000` - Wazuh API
- `9200` - Wazuh Indexer (for internal communication)

## Data Persistence

Data is persisted in Docker volumes:
- `wazuh_api_configuration` - API configurations
- `wazuh_etc` - Wazuh configurations
- `wazuh_logs` - Wazuh logs
- `wazuh_queue` - Event queue
- `wazuh-indexer-data` - Indexed security data

To backup these volumes, use:
```bash
./wazuh.sh backup
```

## Troubleshooting

### Services won't start

Check Docker resources:
```bash
docker stats
```

Ensure you have at least 4GB RAM available for Docker.

### Can't access the dashboard

1. Check if all services are running:
   ```bash
   ./wazuh.sh status
   ```

2. View logs for errors:
   ```bash
   ./wazuh.sh logs wazuh.dashboard
   ```

3. Ensure port 443 is not used by another service:
   ```bash
   sudo netstat -tlnp | grep :443
   ```

### Agent not connecting

1. Verify the manager is reachable from the agent:
   ```bash
   telnet <manager-ip> 1514
   ```

2. Check firewall rules allow traffic on port 1514

3. Review agent logs:
   ```bash
   tail -f /var/ossec/logs/ossec.log
   ```

### Certificate errors

If you encounter certificate errors, regenerate certificates:
```bash
rm -rf config/wazuh_indexer_ssl_certs
./wazuh.sh install
```

## Performance Tuning

### For Production Environments

1. **Increase Java Heap Size** (in `docker-compose.yml`):
   ```yaml
   environment:
     - "OPENSEARCH_JAVA_OPTS=-Xms2g -Xmx2g"
   ```

2. **Adjust ulimits**:
   ```yaml
   ulimits:
     memlock:
       soft: -1
       hard: -1
     nofile:
       soft: 65536
       hard: 65536
   ```

3. **Use external volumes** for better performance:
   ```bash
   docker volume create --driver local wazuh-indexer-data
   ```

## Security Best Practices

1. **Change default passwords** immediately after installation
2. **Use strong SSL certificates** in production (replace self-signed certs)
3. **Restrict network access** using firewalls
4. **Enable authentication** on all APIs
5. **Regular backups** of configuration and data
6. **Monitor resource usage** to prevent DoS
7. **Keep Wazuh updated** to the latest stable version
8. **Review security alerts** regularly
9. **Configure proper log retention** policies
10. **Use network segmentation** to isolate Wazuh infrastructure

## Production Deployment

For production environments, consider:

1. **High Availability Setup**: Deploy multiple Wazuh managers in a cluster
2. **External Database**: Use dedicated storage for the indexer
3. **Load Balancing**: Distribute agent connections across multiple managers
4. **Monitoring**: Set up monitoring for Wazuh infrastructure itself
5. **Backup Strategy**: Implement automated backups with retention policies
6. **Disaster Recovery**: Plan for failover and recovery scenarios

## Additional Resources

- [Official Wazuh Documentation](https://documentation.wazuh.com/)
- [Wazuh GitHub Repository](https://github.com/wazuh/wazuh)
- [Wazuh Community](https://groups.google.com/g/wazuh)
- [Wazuh Use Cases](https://documentation.wazuh.com/current/getting-started/use-cases/index.html)
- [Integration Guides](https://documentation.wazuh.com/current/user-manual/manager/manual-integration.html)

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This deployment setup is provided as-is. Wazuh itself is licensed under GPL-2.0. See the [Wazuh repository](https://github.com/wazuh/wazuh) for more details.

## Support

For Wazuh-specific issues, please refer to the [official Wazuh documentation](https://documentation.wazuh.com/) or open an issue in the [Wazuh repository](https://github.com/wazuh/wazuh/issues).

For issues with this deployment setup, please open an issue in this repository.