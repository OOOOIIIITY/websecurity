#!/bin/bash

# Wazuh Management Script
# This script provides easy management of Wazuh installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
WAZUH_VERSION="4.7.0"

# Determine which docker compose command to use
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo "Error: Neither 'docker compose' nor 'docker-compose' found"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Docker Compose check is done at script start
    if [ -z "$DOCKER_COMPOSE" ]; then
        print_error "Docker Compose is not available."
        exit 1
    fi
}

# Generate SSL certificates
generate_certs() {
    print_info "Generating SSL certificates..."
    
    mkdir -p "$CONFIG_DIR/wazuh_indexer_ssl_certs"
    
    cd "$CONFIG_DIR/wazuh_indexer_ssl_certs"
    
    # Download certificate generation tool
    if [ ! -f "wazuh-certs-tool.sh" ]; then
        print_info "Downloading certificate generation tool..."
        curl -sO "https://packages.wazuh.com/${WAZUH_VERSION%.*}/wazuh-certs-tool.sh"
        chmod +x wazuh-certs-tool.sh
    fi
    
    # Create config.yml for certificate generation
    cat > config.yml << EOF
nodes:
  indexer:
    - name: wazuh.indexer
      ip: wazuh.indexer
  server:
    - name: wazuh.manager
      ip: wazuh.manager
  dashboard:
    - name: wazuh.dashboard
      ip: wazuh.dashboard
EOF
    
    # Generate certificates
    print_info "Generating certificates..."
    bash wazuh-certs-tool.sh -A
    
    # Extract certificates
    if [ -f "wazuh-certificates.tar" ]; then
        tar -xf wazuh-certificates.tar
        
        # Copy root CA for manager
        cp wazuh.indexer/root-ca.pem root-ca-manager.pem
        
        print_info "Certificates generated successfully"
    else
        print_error "Failed to generate certificates"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
}

# Generate configuration files
generate_configs() {
    print_info "Generating configuration files..."
    
    # Create necessary directories
    mkdir -p "$CONFIG_DIR/wazuh_cluster"
    mkdir -p "$CONFIG_DIR/wazuh_indexer"
    mkdir -p "$CONFIG_DIR/wazuh_dashboard"
    
    # Wazuh Manager configuration
    cat > "$CONFIG_DIR/wazuh_cluster/wazuh_manager.conf" << 'EOF'
<ossec_config>
  <global>
    <jsonout_output>yes</jsonout_output>
    <alerts_log>yes</alerts_log>
    <logall>no</logall>
    <logall_json>no</logall_json>
    <email_notification>no</email_notification>
    <smtp_server>smtp.example.wazuh.com</smtp_server>
    <email_from>wazuh@example.wazuh.com</email_from>
    <email_to>recipient@example.wazuh.com</email_to>
    <email_maxperhour>12</email_maxperhour>
    <email_log_source>alerts.log</email_log_source>
  </global>

  <alerts>
    <log_alert_level>3</log_alert_level>
    <email_alert_level>12</email_alert_level>
  </alerts>

  <remote>
    <connection>secure</connection>
    <port>1514</port>
    <protocol>tcp</protocol>
    <queue_size>131072</queue_size>
  </remote>

  <rootcheck>
    <disabled>no</disabled>
    <check_files>yes</check_files>
    <check_trojans>yes</check_trojans>
    <check_dev>yes</check_dev>
    <check_sys>yes</check_sys>
    <check_pids>yes</check_pids>
    <check_ports>yes</check_ports>
    <check_if>yes</check_if>
    <frequency>43200</frequency>
    <rootkit_files>etc/shared/rootkit_files.txt</rootkit_files>
    <rootkit_trojans>etc/shared/rootkit_trojans.txt</rootkit_trojans>
  </rootcheck>

  <wodle name="open-scap">
    <disabled>yes</disabled>
    <timeout>1800</timeout>
    <interval>1d</interval>
    <scan-on-start>yes</scan-on-start>
  </wodle>

  <wodle name="cis-cat">
    <disabled>yes</disabled>
    <timeout>1800</timeout>
    <interval>1d</interval>
    <scan-on-start>yes</scan-on-start>
    <java_path>wodles/java</java_path>
    <ciscat_path>wodles/ciscat</ciscat_path>
  </wodle>

  <wodle name="osquery">
    <disabled>yes</disabled>
    <run_daemon>yes</run_daemon>
    <log_path>/var/log/osquery/osqueryd.results.log</log_path>
    <config_path>/etc/osquery/osquery.conf</config_path>
    <add_labels>yes</add_labels>
  </wodle>

  <wodle name="syscollector">
    <disabled>no</disabled>
    <interval>1h</interval>
    <scan_on_start>yes</scan_on_start>
    <hardware>yes</hardware>
    <os>yes</os>
    <network>yes</network>
    <packages>yes</packages>
    <ports all="no">yes</ports>
    <processes>yes</processes>
  </wodle>

  <sca>
    <enabled>yes</enabled>
    <scan_on_start>yes</scan_on_start>
    <interval>12h</interval>
    <skip_nfs>yes</skip_nfs>
  </sca>

  <vulnerability-detector>
    <enabled>yes</enabled>
    <interval>5m</interval>
    <min_full_scan_interval>6h</min_full_scan_interval>
    <run_on_start>yes</run_on_start>
    <provider name="canonical">
      <enabled>yes</enabled>
      <os>trusty</os>
      <os>xenial</os>
      <os>bionic</os>
      <os>focal</os>
      <os>jammy</os>
      <update_interval>1h</update_interval>
    </provider>
  </vulnerability-detector>

  <indexer>
    <enabled>yes</enabled>
    <hosts>
      <host>https://wazuh.indexer:9200</host>
    </hosts>
    <ssl>
      <certificate_authorities>/etc/ssl/root-ca.pem</certificate_authorities>
      <certificate>/etc/ssl/filebeat.pem</certificate>
      <key>/etc/ssl/filebeat.key</key>
    </ssl>
  </indexer>

  <cluster>
    <name>wazuh</name>
    <node_name>wazuh-manager</node_name>
    <node_type>master</node_type>
    <key></key>
    <port>1516</port>
    <bind_addr>0.0.0.0</bind_addr>
    <nodes>
      <node>wazuh-manager</node>
    </nodes>
    <hidden>no</hidden>
    <disabled>no</disabled>
  </cluster>
</ossec_config>
EOF

    # Wazuh Indexer configuration
    cat > "$CONFIG_DIR/wazuh_indexer/wazuh.indexer.yml" << 'EOF'
network.host: "0.0.0.0"
node.name: "wazuh.indexer"
cluster.initial_master_nodes:
  - "wazuh.indexer"
cluster.name: "wazuh-cluster"
discovery.seed_hosts:
  - "wazuh.indexer"
node.max_local_storage_nodes: "3"
path.data: /var/lib/wazuh-indexer
path.logs: /var/log/wazuh-indexer

plugins.security.ssl.http.pemcert_filepath: /usr/share/wazuh-indexer/certs/wazuh.indexer.pem
plugins.security.ssl.http.pemkey_filepath: /usr/share/wazuh-indexer/certs/wazuh.indexer.key
plugins.security.ssl.http.pemtrustedcas_filepath: /usr/share/wazuh-indexer/certs/root-ca.pem
plugins.security.ssl.transport.pemcert_filepath: /usr/share/wazuh-indexer/certs/wazuh.indexer.pem
plugins.security.ssl.transport.pemkey_filepath: /usr/share/wazuh-indexer/certs/wazuh.indexer.key
plugins.security.ssl.transport.pemtrustedcas_filepath: /usr/share/wazuh-indexer/certs/root-ca.pem
plugins.security.ssl.http.enabled: true
plugins.security.ssl.transport.enforce_hostname_verification: false
plugins.security.ssl.transport.resolve_hostname: false

plugins.security.authcz.admin_dn:
  - "CN=admin,OU=Wazuh,O=Wazuh,L=California,C=US"
plugins.security.check_snapshot_restore_write_privileges: true
plugins.security.enable_snapshot_restore_privilege: true
plugins.security.nodes_dn:
  - "CN=wazuh.indexer,OU=Wazuh,O=Wazuh,L=California,C=US"
plugins.security.restapi.roles_enabled:
  - "all_access"
  - "security_rest_api_access"
plugins.security.system_indices.enabled: true
plugins.security.system_indices.indices: [".opendistro-alerting-config", ".opendistro-alerting-alert*", ".opendistro-anomaly-results*", ".opendistro-anomaly-detector*", ".opendistro-anomaly-checkpoints", ".opendistro-anomaly-detection-state", ".opendistro-reports-*", ".opendistro-notifications-*", ".opendistro-notebooks", ".opensearch-observability", ".opendistro-asynchronous-search-response*", ".replication-metadata-store"]

compatibility.override_main_response_version: true
EOF

    # Internal users for indexer
    cat > "$CONFIG_DIR/wazuh_indexer/internal_users.yml" << 'EOF'
---
_meta:
  type: "internalusers"
  config_version: 2

admin:
  hash: "$2y$12$K/SpwjtB.wOHJ/Nc6GVRDuc1h0rM1DfvziFRNPtk27P.c4yDr9njO"
  reserved: true
  backend_roles:
  - "admin"
  description: "Demo admin user"

kibanaserver:
  hash: "$2y$12$4AcgAt3xwOWadA5s5blL6ev39OXDNhmOesEoo33eZtrq2N0YrU3H."
  reserved: true
  description: "Demo kibanaserver user"
EOF

    # Wazuh Dashboard configuration
    cat > "$CONFIG_DIR/wazuh_dashboard/opensearch_dashboards.yml" << 'EOF'
server.host: "0.0.0.0"
server.port: 5601
opensearch.hosts: ["https://wazuh.indexer:9200"]
opensearch.ssl.verificationMode: certificate
opensearch.username: "kibanaserver"
opensearch.password: "kibanaserver"
opensearch.requestHeadersAllowlist: ["securitytenant","Authorization"]
opensearch_security.multitenancy.enabled: false
opensearch_security.readonly_mode.roles: ["kibana_read_only"]
server.ssl.enabled: true
server.ssl.key: "/usr/share/wazuh-dashboard/certs/wazuh-dashboard-key.pem"
server.ssl.certificate: "/usr/share/wazuh-dashboard/certs/wazuh-dashboard.pem"
opensearch.ssl.certificateAuthorities: ["/usr/share/wazuh-dashboard/certs/root-ca.pem"]
uiSettings.overrides.defaultRoute: "/app/wazuh"
EOF

    # Wazuh Dashboard Wazuh plugin configuration
    cat > "$CONFIG_DIR/wazuh_dashboard/wazuh.yml" << 'EOF'
hosts:
  - default:
      url: "https://wazuh.manager"
      port: 55000
      username: wazuh-wui
      password: MyS3cr37P450r.*-
      run_as: false

pattern: "wazuh-alerts-*"
timeout: 20000
EOF

    print_info "Configuration files generated successfully"
}

# Install Wazuh
install() {
    print_info "Installing Wazuh..."
    
    check_docker
    
    # Generate certificates if they don't exist
    if [ ! -d "$CONFIG_DIR/wazuh_indexer_ssl_certs/wazuh.indexer" ]; then
        generate_certs
    else
        print_info "Certificates already exist, skipping generation"
    fi
    
    # Generate config files if they don't exist
    if [ ! -f "$CONFIG_DIR/wazuh_cluster/wazuh_manager.conf" ]; then
        generate_configs
    else
        print_info "Configuration files already exist, skipping generation"
    fi
    
    print_info "Starting Wazuh containers..."
    $DOCKER_COMPOSE up -d
    
    print_info "Waiting for services to be ready..."
    sleep 30
    
    print_info ""
    print_info "Wazuh installation completed!"
    print_info ""
    print_info "Access Wazuh Dashboard at: https://localhost:443"
    print_info "Default credentials:"
    print_info "  Username: admin"
    print_info "  Password: SecretPassword"
    print_info ""
    print_info "⚠️  WARNING: Change these default passwords immediately in production!"
    print_info ""
    print_info "Use './wazuh.sh status' to check the status of services"
}

# Start Wazuh
start() {
    print_info "Starting Wazuh..."
    $DOCKER_COMPOSE start
    print_info "Wazuh started successfully"
}

# Stop Wazuh
stop() {
    print_info "Stopping Wazuh..."
    $DOCKER_COMPOSE stop
    print_info "Wazuh stopped successfully"
}

# Restart Wazuh
restart() {
    print_info "Restarting Wazuh..."
    $DOCKER_COMPOSE restart
    print_info "Wazuh restarted successfully"
}

# Check status
status() {
    print_info "Checking Wazuh status..."
    $DOCKER_COMPOSE ps
}

# View logs
logs() {
    if [ -z "$2" ]; then
        print_info "Showing logs for all services..."
        $DOCKER_COMPOSE logs -f
    else
        print_info "Showing logs for $2..."
        $DOCKER_COMPOSE logs -f "$2"
    fi
}

# Uninstall Wazuh
uninstall() {
    print_warning "This will remove all Wazuh containers and volumes!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" == "yes" ]; then
        print_info "Uninstalling Wazuh..."
        $DOCKER_COMPOSE down -v
        print_info "Wazuh uninstalled successfully"
    else
        print_info "Uninstall cancelled"
    fi
}

# Update Wazuh
update() {
    print_info "Updating Wazuh..."
    $DOCKER_COMPOSE pull
    $DOCKER_COMPOSE up -d
    print_info "Wazuh updated successfully"
}

# Backup Wazuh data
backup() {
    BACKUP_DIR="${BACKUP_DIR:-./backups}"
    BACKUP_FILE="$BACKUP_DIR/wazuh-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    print_info "Creating backup..."
    mkdir -p "$BACKUP_DIR"
    
    docker run --rm \
        -v wazuh_api_configuration:/backup/api_configuration \
        -v wazuh_etc:/backup/etc \
        -v wazuh_logs:/backup/logs \
        -v wazuh_queue:/backup/queue \
        -v wazuh_var_multigroups:/backup/var_multigroups \
        -v wazuh-indexer-data:/backup/indexer-data \
        -v "$(pwd)/$BACKUP_DIR:/output" \
        alpine \
        tar czf "/output/$(basename $BACKUP_FILE)" -C /backup .
    
    print_info "Backup created: $BACKUP_FILE"
}

# Show help
show_help() {
    cat << EOF
Wazuh Management Script

Usage: ./wazuh.sh [command]

Commands:
    install     - Install and setup Wazuh
    start       - Start Wazuh services
    stop        - Stop Wazuh services
    restart     - Restart Wazuh services
    status      - Check status of Wazuh services
    logs        - View logs (optionally specify service name)
    update      - Update Wazuh to latest version
    backup      - Backup Wazuh data
    uninstall   - Uninstall Wazuh (removes all data)
    help        - Show this help message

Examples:
    ./wazuh.sh install
    ./wazuh.sh status
    ./wazuh.sh logs wazuh.manager
    ./wazuh.sh backup

EOF
}

# Main script logic
case "${1}" in
    install)
        install
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs "$@"
        ;;
    update)
        update
        ;;
    backup)
        backup
        ;;
    uninstall)
        uninstall
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: ${1}"
        echo ""
        show_help
        exit 1
        ;;
esac
