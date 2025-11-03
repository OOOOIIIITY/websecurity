# Security Policy

## Overview

This repository provides deployment scripts and configurations for Wazuh, a security monitoring platform. Security is paramount when deploying security infrastructure.

## Supported Versions

We recommend always using the latest stable version of Wazuh. This repository currently supports:

| Version | Supported          |
| ------- | ------------------ |
| 4.7.x   | :white_check_mark: |
| < 4.7   | :x:                |

## Default Credentials

**⚠️ CRITICAL**: This deployment uses default credentials for demonstration purposes:

**Wazuh Dashboard:**
- Username: `admin`
- Password: `SecretPassword`

**Wazuh API:**
- Username: `wazuh-wui`
- Password: `MyS3cr37P450r.*-`

**Dashboard Service:**
- Username: `kibanaserver`
- Password: `kibanaserver`

### You MUST change these passwords before using in any environment, especially production!

## Security Best Practices

### 1. Verify Downloaded Files

The installation script downloads the Wazuh certificate generation tool. For production deployments, verify file integrity:

```bash
# After download, verify the checksum
cd config/wazuh_indexer_ssl_certs
sha256sum wazuh-certs-tool.sh

# Compare with official checksum from:
# https://documentation.wazuh.com/current/deployment-options/docker/wazuh-container.html

# Only proceed if checksums match
```

**Note**: The installation script includes a warning about this. Always verify checksums for production use.

### 2. Change Default Passwords Immediately

**For the Indexer (Dashboard login):**
```bash
docker exec -it wazuh-indexer bash
/usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh -p "YourNewStrongPassword123!"
```

Then update `config/wazuh_indexer/internal_users.yml` with the new hash.

**For the Wazuh API:**
Edit environment variables in `docker-compose.yml`:
```yaml
environment:
  - API_PASSWORD=YourNewStrongPassword123!
```

**Password Requirements:**
- Minimum 16 characters
- Mix of uppercase and lowercase letters
- Include numbers and special characters
- Avoid common words or patterns
- Use a password manager

### 3. Replace Self-Signed Certificates

The installation generates self-signed certificates for testing. For production:

1. Obtain certificates from a trusted Certificate Authority (CA)
2. Replace certificates in `config/wazuh_indexer_ssl_certs/`
3. Update volume mounts in `docker-compose.yml`

Alternatively, use Let's Encrypt:
```bash
certbot certonly --standalone -d your-wazuh-domain.com
```

### 4. Network Security

**Firewall Rules:**
```bash
# Allow only necessary ports
ufw allow 22/tcp     # SSH (restrict to known IPs)
ufw allow 1514/tcp   # Wazuh agents
ufw allow 443/tcp    # Dashboard (restrict to known IPs)
ufw deny 9200/tcp    # Indexer (internal only)
ufw deny 55000/tcp   # API (internal only)
ufw enable
```

**Docker Network Isolation:**
- Use Docker's internal networks
- Don't expose unnecessary ports
- Consider using a reverse proxy (nginx, Traefik)

### 5. Use Environment Variables or Secrets

Instead of hardcoding credentials in `docker-compose.yml`:

**Option A - Environment File:**
```bash
cp .env.example .env
# Edit .env with your credentials
# Ensure .env is in .gitignore
```

**Option B - Docker Secrets:**
```yaml
secrets:
  wazuh_api_password:
    external: true

services:
  wazuh.manager:
    secrets:
      - wazuh_api_password
```

### 6. Regular Updates

Keep Wazuh updated to receive security patches:
```bash
./wazuh.sh update
```

Subscribe to Wazuh security announcements:
- [Wazuh Security Advisories](https://wazuh.com/security-advisories/)
- [GitHub Security Advisories](https://github.com/wazuh/wazuh/security/advisories)

### 7. Access Control

**Implement Role-Based Access Control (RBAC):**
- Create separate users for different team members
- Assign minimal necessary permissions
- Disable default accounts after creating new ones
- Use multi-factor authentication (MFA) where possible

**API Access:**
```bash
# Create read-only API user
docker exec -it wazuh-manager /var/ossec/bin/wazuh-api-user create \
    -u readonly_user \
    -p "StrongPassword123!"
```

### 8. Audit Logging

Enable comprehensive audit logging:
```xml
<logging>
  <log_alert_level>1</log_alert_level>
</logging>
```

Review logs regularly:
```bash
./wazuh.sh logs wazuh.manager | grep -i "security\|error\|critical"
```

### 9. Data Encryption

**At Rest:**
- Use encrypted volumes for Docker
- Enable disk encryption on the host system
- Consider encrypted backups

**In Transit:**
- All communications use TLS/SSL
- Verify certificate validation is enabled
- Use strong cipher suites

### 10. Secure Backups

```bash
# Create encrypted backup
./wazuh.sh backup
openssl enc -aes-256-cbc -salt -in backups/wazuh-backup-*.tar.gz \
    -out backups/wazuh-backup-encrypted.tar.gz.enc

# Verify backup integrity
sha256sum backups/wazuh-backup-*.tar.gz > backups/checksums.txt
```

**Backup Security:**
- Store backups in a secure location
- Encrypt backup files
- Test restore procedures regularly
- Implement backup retention policies
- Keep backups offline or in separate networks

### 11. Monitoring and Alerting

Monitor the Wazuh infrastructure itself:
- Set up health checks
- Monitor resource usage
- Alert on failed authentication attempts
- Track configuration changes

### 12. Principle of Least Privilege

- Run containers as non-root users where possible
- Limit container capabilities
- Use read-only file systems where applicable
- Restrict network access between containers

### 13. Security Hardening Checklist

Before production deployment:

- [ ] All default passwords changed
- [ ] Self-signed certificates replaced with proper SSL certificates
- [ ] Firewall rules configured and tested
- [ ] Access limited to known IP addresses
- [ ] RBAC implemented with appropriate roles
- [ ] API access restricted and audited
- [ ] Backups configured and tested
- [ ] Monitoring and alerting set up
- [ ] Security patches applied
- [ ] Documentation reviewed and updated
- [ ] Incident response plan in place
- [ ] Regular security audits scheduled

## Reporting a Vulnerability

If you discover a security vulnerability in this deployment configuration:

1. **Do NOT** open a public GitHub issue
2. Email security concerns to the repository maintainers
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will acknowledge receipt within 48 hours and provide a timeline for resolution.

For Wazuh core vulnerabilities, report to the Wazuh team:
- https://github.com/wazuh/wazuh/security/advisories/new

## Security Resources

- [Wazuh Security Documentation](https://documentation.wazuh.com/current/deployment-options/docker/container-security.html)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [OWASP Security Guidelines](https://owasp.org/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)

## Compliance

This deployment can be configured to help meet various compliance requirements:
- **PCI-DSS**: Payment Card Industry Data Security Standard
- **GDPR**: General Data Protection Regulation
- **HIPAA**: Health Insurance Portability and Accountability Act
- **SOC 2**: Service Organization Control 2
- **ISO 27001**: Information Security Management

Refer to `ADVANCED.md` for compliance configuration details.

## License

This security policy is provided as-is without warranties. Users are responsible for their own security implementations and compliance requirements.

## Updates

This security policy is reviewed and updated regularly. Last update: 2025-11-03

Check for updates: https://github.com/OOOOIIIITY/websecurity
