# Advanced Wazuh Configuration Guide

This guide covers advanced configuration and management topics for Wazuh.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Custom Rules and Decoders](#custom-rules-and-decoders)
3. [Active Response](#active-response)
4. [Agent Management](#agent-management)
5. [Integration with External Systems](#integration-with-external-systems)
6. [Performance Tuning](#performance-tuning)
7. [High Availability Setup](#high-availability-setup)
8. [Security Hardening](#security-hardening)
9. [Monitoring and Alerting](#monitoring-and-alerting)
10. [Troubleshooting](#troubleshooting)

## Architecture Overview

### Components

1. **Wazuh Manager**
   - Analyzes data from agents
   - Processes security events
   - Triggers alerts and active responses
   - Manages agent registration and configuration

2. **Wazuh Indexer (OpenSearch)**
   - Stores and indexes security alerts
   - Provides search capabilities
   - Stores historical data

3. **Wazuh Dashboard**
   - Web-based interface
   - Visualizations and dashboards
   - Security event analysis
   - Agent management

4. **Wazuh Agents**
   - Installed on monitored systems
   - Collect security data
   - Execute active response actions
   - Report to manager

### Data Flow

```
Agent → Manager → Indexer → Dashboard
         ↓
    Active Response
```

## Custom Rules and Decoders

### Creating Custom Rules

Custom rules allow you to define specific security scenarios to detect.

1. Create a rules file:
```bash
docker exec -it wazuh-manager bash
cd /var/ossec/etc/rules
nano local_rules.xml
```

2. Example custom rule:
```xml
<group name="custom,">
  <!-- Rule to detect failed SSH login attempts -->
  <rule id="100001" level="5">
    <if_sid>5716</if_sid>
    <srcip>!192.168.1.0/24</srcip>
    <description>SSH failed login from external IP</description>
    <group>authentication_failed,pci_dss_10.2.4,pci_dss_10.2.5,</group>
  </rule>

  <!-- Rule to detect multiple failed logins -->
  <rule id="100002" level="10" frequency="5" timeframe="300">
    <if_matched_sid>100001</if_matched_sid>
    <description>Multiple SSH failed logins from same IP (brute force)</description>
    <group>authentication_failures,pci_dss_11.4,pci_dss_10.2.4,</group>
  </rule>
</group>
```

3. Restart manager:
```bash
./wazuh.sh restart
```

### Creating Custom Decoders

Decoders parse log messages into structured fields.

1. Create decoder file:
```bash
docker exec -it wazuh-manager bash
cd /var/ossec/etc/decoders
nano local_decoder.xml
```

2. Example decoder:
```xml
<decoder name="custom-app">
  <prematch>^custom-app: </prematch>
</decoder>

<decoder name="custom-app-fields">
  <parent>custom-app</parent>
  <regex>user=(\w+), action=(\w+), status=(\w+)</regex>
  <order>user, action, status</order>
</decoder>
```

## Active Response

Active response allows automatic actions in response to threats.

### Built-in Active Responses

1. **Firewall Block**: Block IP addresses
2. **Disable Account**: Disable user accounts
3. **Restart Service**: Restart compromised services

### Creating Custom Active Response

1. Create response script:
```bash
docker exec -it wazuh-manager bash
cd /var/ossec/active-response/bin
nano custom-response.sh
```

2. Example script:
```bash
#!/bin/bash
# Custom active response script

ACTION=$1
USER=$2
IP=$3
ALERTID=$4
RULEID=$5

# Log the action
echo "`date` $0 $ACTION $USER $IP $ALERTID $RULEID" >> /var/ossec/logs/active-responses.log

if [ "$ACTION" = "add" ]; then
    # Take action (e.g., send notification)
    curl -X POST https://api.example.com/alert \
         -H "Content-Type: application/json" \
         -d "{\"user\":\"$USER\",\"ip\":\"$IP\",\"alert\":\"$ALERTID\"}"
fi
```

3. Configure in ossec.conf:
```xml
<command>
  <name>custom-response</name>
  <executable>custom-response.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>

<active-response>
  <command>custom-response</command>
  <location>server</location>
  <rules_id>100002</rules_id>
</active-response>
```

## Agent Management

### Agent Registration

#### Method 1: Using authd (Automatic)
```bash
# On agent
sudo /var/ossec/bin/agent-auth -m MANAGER_IP
```

#### Method 2: Manual Registration
```bash
# On manager
docker exec -it wazuh-manager /var/ossec/bin/manage_agents

# Follow prompts to add agent
# Copy key and add to agent
```

### Agent Groups

Group agents for centralized configuration:

```bash
# Create agent group
docker exec -it wazuh-manager /var/ossec/bin/agent_groups -a -g webservers

# Assign agent to group
docker exec -it wazuh-manager /var/ossec/bin/agent_groups -a -i 001 -g webservers

# Create group-specific configuration
docker exec -it wazuh-manager bash
mkdir -p /var/ossec/etc/shared/webservers
nano /var/ossec/etc/shared/webservers/agent.conf
```

Example group configuration:
```xml
<agent_config>
  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/apache2/access.log</location>
  </localfile>
  
  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/apache2/error.log</location>
  </localfile>
</agent_config>
```

### Agent Commands

```bash
# List all agents
docker exec -it wazuh-manager /var/ossec/bin/agent_control -l

# Get agent info
docker exec -it wazuh-manager /var/ossec/bin/agent_control -i AGENT_ID

# Restart agent remotely
docker exec -it wazuh-manager /var/ossec/bin/agent_control -R AGENT_ID

# Remove agent
docker exec -it wazuh-manager /var/ossec/bin/manage_agents -r AGENT_ID
```

## Integration with External Systems

### Slack Integration

1. Create Slack webhook URL
2. Configure integration in ossec.conf:

```xml
<integration>
  <name>slack</name>
  <hook_url>https://hooks.slack.com/services/YOUR/WEBHOOK/URL</hook_url>
  <level>10</level>
  <alert_format>json</alert_format>
</integration>
```

### PagerDuty Integration

```xml
<integration>
  <name>pagerduty</name>
  <api_key>YOUR_PAGERDUTY_API_KEY</api_key>
  <level>12</level>
</integration>
```

### Custom Webhook Integration

```xml
<integration>
  <name>custom-webhook</name>
  <hook_url>https://your-webhook-url.com/endpoint</hook_url>
  <level>7</level>
  <alert_format>json</alert_format>
  <options>{"content_type":"application/json"}</options>
</integration>
```

### VirusTotal Integration

```xml
<integration>
  <name>virustotal</name>
  <api_key>YOUR_VIRUSTOTAL_API_KEY</api_key>
  <group>syscheck</group>
  <alert_format>json</alert_format>
</integration>
```

## Performance Tuning

### Manager Performance

1. **Adjust log analysis threads**:
```xml
<global>
  <logall_json>no</logall_json>
  <alerts_log>yes</alerts_log>
</global>

<analysisd>
  <log_alert_level>3</log_alert_level>
</analysisd>
```

2. **Configure queue size**:
```xml
<remote>
  <queue_size>131072</queue_size>
</remote>
```

3. **Optimize file integrity monitoring**:
```xml
<syscheck>
  <frequency>43200</frequency>  <!-- 12 hours -->
  <scan_on_start>no</scan_on_start>
</syscheck>
```

### Indexer Performance

1. **Increase JVM heap size** (docker-compose.yml):
```yaml
environment:
  - "OPENSEARCH_JAVA_OPTS=-Xms4g -Xmx4g"
```

2. **Adjust index settings**:
```bash
curl -X PUT "https://localhost:9200/wazuh-alerts-*/_settings" \
     -H 'Content-Type: application/json' \
     -d '{
       "index": {
         "refresh_interval": "30s",
         "number_of_replicas": 0
       }
     }'
```

### Agent Performance

1. **Reduce monitoring frequency**:
```xml
<syscheck>
  <frequency>86400</frequency>  <!-- Daily -->
</syscheck>

<rootcheck>
  <frequency>86400</frequency>
</rootcheck>
```

2. **Limit file monitoring**:
```xml
<syscheck>
  <directories check_all="yes">/etc</directories>
  <ignore>/etc/mtab</ignore>
  <ignore type="sregex">/etc/.*\.swp$</ignore>
</syscheck>
```

## High Availability Setup

### Multi-Node Cluster

For production environments, deploy multiple Wazuh managers in a cluster.

1. **Update cluster configuration** in wazuh_manager.conf:
```xml
<cluster>
  <name>wazuh-cluster</name>
  <node_name>wazuh-master</node_name>
  <node_type>master</node_type>
  <key>CLUSTER_SECRET_KEY</key>
  <port>1516</port>
  <bind_addr>0.0.0.0</bind_addr>
  <nodes>
    <node>wazuh-master</node>
    <node>wazuh-worker1</node>
    <node>wazuh-worker2</node>
  </nodes>
  <hidden>no</hidden>
  <disabled>no</disabled>
</cluster>
```

2. **Deploy worker nodes** with appropriate configuration
3. **Configure load balancer** for agent connections

### Database Replication

Configure indexer cluster for data replication:

```yaml
# Add to docker-compose.yml
wazuh.indexer2:
  image: wazuh/wazuh-indexer:4.7.0
  hostname: wazuh.indexer2
  environment:
    - cluster.initial_master_nodes=wazuh.indexer,wazuh.indexer2
    - discovery.seed_hosts=wazuh.indexer,wazuh.indexer2
```

## Security Hardening

### SSL/TLS Configuration

1. **Use proper certificates** (not self-signed)
2. **Enable mutual TLS** for agent-manager communication
3. **Configure strong ciphers**

### Access Control

1. **Change default passwords**
2. **Use role-based access control (RBAC)**
3. **Enable audit logging**
4. **Implement IP whitelisting**

### Network Security

1. **Use VPN or private network**
2. **Configure firewall rules**:
   - Allow 1514/TCP (agent communication)
   - Allow 55000/TCP (API - restricted)
   - Allow 443/TCP (dashboard - restricted)
   - Deny all other traffic

### Secure API Access

```bash
# Create API user with limited permissions
docker exec -it wazuh-manager /var/ossec/bin/wazuh-api-user create \
    -u readonly_user \
    -p SecurePassword123!
```

## Monitoring and Alerting

### Monitor Wazuh Infrastructure

1. **Check manager status**:
```bash
docker exec -it wazuh-manager /var/ossec/bin/wazuh-control status
```

2. **Monitor logs**:
```bash
./wazuh.sh logs wazuh.manager | grep -i error
```

3. **Check agent connectivity**:
```bash
docker exec -it wazuh-manager /var/ossec/bin/agent_control -l | grep Active
```

### Set Up Health Checks

Create monitoring script:
```bash
#!/bin/bash
# health-check.sh

# Check if manager is responding
if ! docker exec wazuh-manager /var/ossec/bin/wazuh-control status > /dev/null; then
    echo "CRITICAL: Wazuh manager not responding"
    exit 2
fi

# Check indexer health
if ! curl -s http://localhost:9200/_cluster/health | grep -q "green\|yellow"; then
    echo "WARNING: Indexer cluster health degraded"
    exit 1
fi

echo "OK: All services healthy"
exit 0
```

## Troubleshooting

### Common Issues

#### Manager won't start
```bash
# Check logs
./wazuh.sh logs wazuh.manager

# Verify configuration
docker exec -it wazuh-manager /var/ossec/bin/wazuh-control check
```

#### Agent disconnected
```bash
# On agent
sudo systemctl status wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log

# Check connectivity
telnet MANAGER_IP 1514
```

#### High CPU/Memory usage
```bash
# Check resource usage
docker stats

# Review event rate
docker exec -it wazuh-manager tail -f /var/ossec/logs/ossec.log | grep "Event"
```

#### Indexer issues
```bash
# Check cluster health
curl -X GET "http://localhost:9200/_cluster/health?pretty"

# Check indices
curl -X GET "http://localhost:9200/_cat/indices?v"

# Clear old indices (CAUTION: deletes data)
curl -X DELETE "http://localhost:9200/wazuh-alerts-4.x-2023.01.*"
```

### Debug Mode

Enable debug mode for detailed logging:

```xml
<logging>
  <log_alert_level>1</log_alert_level>
</logging>
```

### Performance Analysis

```bash
# Analyze manager performance
docker exec -it wazuh-manager /var/ossec/bin/wazuh-analysisd -t

# Check queue status
docker exec -it wazuh-manager /var/ossec/bin/wazuh-control status | grep queue
```

## Best Practices

1. **Regular backups**: Schedule daily backups
2. **Update regularly**: Keep Wazuh updated
3. **Monitor performance**: Set up monitoring
4. **Review alerts**: Regularly review and tune rules
5. **Document changes**: Keep configuration documented
6. **Test changes**: Test in staging before production
7. **Plan capacity**: Monitor growth and scale accordingly
8. **Security audits**: Regular security reviews
9. **Disaster recovery**: Have recovery procedures
10. **Training**: Ensure team knows how to use Wazuh

## References

- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Wazuh Rule Sets](https://github.com/wazuh/wazuh-ruleset)
- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
- [Wazuh API Reference](https://documentation.wazuh.com/current/user-manual/api/reference.html)
