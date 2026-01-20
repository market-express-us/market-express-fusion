# FusionAuth Deployment Automation

Automated, repeatable FusionAuth deployment for marketexpress.us B2B marketplace authentication infrastructure. Provides infrastructure-as-code for identity and access management with persistent user data across version upgrades and configuration updates.

**Author:** Colin Bitterfield
**Email:** colin@bitterfield.com
**Version:** 1.0.0
**Date:** 2026-01-20

## Overview

This project deploys FusionAuth 1.53.2 identity provider with PostgreSQL 17.2 database backend for the Market Express B2B marketplace platform. Configuration is managed through Docker Compose with automated deployment via Make targets.

**Key Features:**
- Single-command deployment (`make init`)
- Automated Kickstart configuration (three pre-configured applications)
- Persistent data storage across container recreations
- Environment variable-based configuration (no hardcoded secrets)
- Health check monitoring and graceful startup sequencing
- Database backup and restore capabilities

## Prerequisites

**Required Software:**

- **Docker Engine 29.1+** with Compose 2.39+ bundled
  Install: [Docker Desktop](https://www.docker.com/products/docker-desktop) (macOS, Windows) or [Docker Engine](https://docs.docker.com/engine/install/) (Linux)

- **curl** (for health checks)
  - macOS: Pre-installed
  - Linux: `sudo apt-get install curl` or `sudo yum install curl`
  - Windows: Included in Git Bash or WSL2

- **jq** (for kickstart.json validation)
  - macOS: `brew install jq`
  - Linux: `sudo apt-get install jq` or `sudo yum install jq`
  - Windows: Download from [stedolan.github.io/jq](https://stedolan.github.io/jq/download/)

- **make** (for deployment automation)
  - macOS: Pre-installed (Xcode Command Line Tools)
  - Linux: Pre-installed or `sudo apt-get install build-essential`
  - Windows: Use Git Bash or WSL2

**System Requirements:**
- 4GB RAM minimum (8GB recommended)
- 10GB disk space for Docker images and volumes
- Ports 9011 (FusionAuth) available

## Quick Start

### First-time Setup

```bash
# Clone or navigate to project directory
cd /path/to/market-express-fusion

# Generate .env with cryptographically secure random passwords
make env-dev

# Review generated .env (optional - adjust non-password settings if needed)
cat .env

# Run initial deployment
make init
```

**What `make env-dev` does:**
- Copies `.env.template` to `.env`
- Generates 5 cryptographically secure random passwords using `/dev/urandom`
  - `DATABASE_PASSWORD` (32 characters) - PostgreSQL authentication
  - `FUSIONAUTH_API_KEY` (64 characters) - MercurJS integration API key
  - `ADMIN_CLIENT_SECRET` (64 characters) - Admin application OAuth2 secret
  - `VENDOR_CLIENT_SECRET` (64 characters) - Vendor application OAuth2 secret
  - `STORE_CLIENT_SECRET` (64 characters) - Store application OAuth2 secret
- Backs up existing `.env` before overwriting (with timestamp)
- Creates unique credentials for each deployment

**Expected output:**
```
FusionAuth Admin UI: http://localhost:9011
Kickstart has configured three applications:
  - marketexpress-admin  (platform administrators, MFA required)
  - marketexpress-vendor (vendor users, MFA optional)
  - marketexpress-store  (customers, MFA optional)
```

### Accessing FusionAuth

- **Admin UI:** [http://localhost:9011](http://localhost:9011)
- **API Endpoint:** [http://localhost:9011/api](http://localhost:9011/api)
- **Default setup wizard:** Disabled (silent mode active)
- **Applications:** Three applications pre-configured via Kickstart

### Updating Configuration

```bash
# Edit docker-compose.yml or update image versions
nano docker-compose.yml

# Deploy changes (preserves user data)
make update
```

**IMPORTANT:** Kickstart only runs on fresh installations (empty database). For post-deployment configuration changes, use:
- FusionAuth Admin UI (manual changes)
- FusionAuth API calls (scripted changes)
- Terraform FusionAuth provider (infrastructure-as-code)

## Architecture

### System Components

```
┌─────────────────────────────────────────┐
│  FusionAuth Admin UI (Port 9011)        │
│  - Application management               │
│  - User/role administration             │
│  - OAuth2/OIDC configuration            │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  FusionAuth App 1.53.2                  │
│  - Identity provider                    │
│  - OAuth2/OIDC server                   │
│  - JWT token generation                 │
│  - Multi-factor authentication          │
└──────────────┬──────────────────────────┘
               │ Bridge network (db_net)
┌──────────────▼──────────────────────────┐
│  PostgreSQL 17.2                        │
│  - Authentication database              │
│  - Named volume: fusionauth-db-data     │
│  - Connection pooling: 200 max          │
└─────────────────────────────────────────┘
```

### Networking

- **Bridge network:** `fusionauth-network` (isolates inter-container communication)
- **PostgreSQL:** Accessible only via Docker network (no external port exposure)
- **FusionAuth:** Port 9011 exposed to host for admin UI and API access

### Data Persistence

- **Named volume:** `fusionauth-db-data` (PostgreSQL data directory)
- **Survives:** Container stops, restarts, recreations via `make update`
- **Destroyed only by:** `make destroy` with volume removal confirmation

## Applications Configured

Three applications are pre-configured via Kickstart per FUSION-AUTH.md specification:

### 1. marketexpress-admin (Platform Administration)

**Purpose:** Platform administrator access to system configuration, user management, and vendor oversight

**Authentication:**
- OAuth 2.0 Authorization Code flow
- MFA: **Required** (email or SMS verification)
- Session: 8 hours (28800 seconds)
- Refresh token: 30 days (43200 minutes)

**Roles:**
- `platform-admin` - Full platform management capabilities including system configuration, user management, and vendor oversight
- `platform-support` - Read-only access with limited user management for customer support operations

**OAuth Configuration:**
- Client ID: `3c219e58-ed0e-4b18-ad48-f4f92793ae32`
- Redirect URLs: `http://localhost:9000/auth/fusionauth/callback`, `http://localhost:9000/admin/auth/fusionauth/callback`

### 2. marketexpress-vendor (Vendor Portal)

**Purpose:** Vendor user access to product management, orders, and team administration

**Authentication:**
- OAuth 2.0 Authorization Code flow
- MFA: **Disabled** by default (configurable per user)
- Session: 8 hours (28800 seconds)
- Refresh token: 30 days (43200 minutes)

**Roles:**
- `vendor-owner` - Full seller account control including financial settings, team management, and storefront configuration
- `vendor-manager` - Product, inventory, order, and team member management without financial or ownership controls
- `vendor-staff` - Order fulfillment and customer communication only, no product or team management

**OAuth Configuration:**
- Client ID: `0cc89d65-44e8-4662-940a-8e26c08b7a5e`
- Redirect URLs: `http://localhost:9000/auth/fusionauth/callback`, `http://localhost:9000/vendor/auth/fusionauth/callback`

### 3. marketexpress-store (Customer Store)

**Purpose:** Customer access to browsing, purchasing, order tracking, and account management (future B2C marketplace)

**Authentication:**
- OAuth 2.0 Authorization Code flow
- MFA: **Disabled** by default (configurable per user)
- Session: 8 hours (28800 seconds)
- Refresh token: 30 days (43200 minutes)

**Roles:**
- `customer` (default role) - Standard customer capabilities including browsing, purchasing, order tracking, and account management

**OAuth Configuration:**
- Client ID: `7c3a8d37-0e74-4a40-bc9e-df1d1d3f3456`
- Redirect URLs: `http://localhost:9000/auth/fusionauth/callback`, `http://localhost:9000/store/auth/fusionauth/callback`

## Makefile Targets

### Deployment Operations

**`make init`** - First-time deployment
- Creates `.env` from `.env.template` if not exists
- Prompts to edit credentials
- Pulls Docker images
- Starts containers in background
- Waits for health checks
- Displays success message with URL

**`make update`** - Deploy configuration changes
- Pulls updated Docker images
- Recreates containers with `--force-recreate`
- Preserves database volumes (no data loss)
- Waits for health checks
- Displays success message

**`make destroy`** - Tear down environment
- Stops and removes containers
- Optionally removes database volumes (confirmation required)
- Displays destruction confirmation

### Monitoring and Maintenance

**`make status`** - Check service health
- Shows container status via `docker-compose ps`
- Checks FusionAuth API health endpoint
- Lists database volumes

**`make logs`** - View container logs
- Follows logs from all containers in real-time
- Press Ctrl+C to exit

**`make backup`** - Backup PostgreSQL database
- Creates `backup.sql` in current directory
- Includes all FusionAuth configuration and user data
- Restore with: `docker-compose exec -T db psql -U fusionauth fusionauth < backup.sql`

**`make clean`** - Remove stopped containers and orphaned volumes
- Cleans up Docker resources
- Does not remove fusionauth-db-data volume

## File Structure

```
market-express-fusion/
├── docker-compose.yml       # Container orchestration configuration
├── kickstart.json           # FusionAuth initial configuration (apps, roles, tenant)
├── .env.template            # Environment variable documentation
├── .env                     # Actual credentials (gitignored, created by make init)
├── Makefile                 # Deployment automation targets
├── README.md                # This file
├── .gitignore               # Git exclusions (.env, logs, backups)
└── backup.sql               # Database backup (created by make backup)
```

## Security Notes

### Development Environment

This configuration is optimized for **local development**. Production deployments require additional security hardening:

**Current Security Measures:**
- Environment variable-based credentials (no hardcoded secrets)
- PostgreSQL isolated to Docker network (no external access)
- `.env` file excluded from git tracking
- MFA required for admin application
- Failed authentication lockout (5 attempts, 5 minute lockout, 1 hour reset)

**Production Recommendations:**
1. Use secrets management (AWS Secrets Manager, HashiCorp Vault, Azure Key Vault)
2. Enable HTTPS/TLS termination via reverse proxy (nginx, Traefik, Caddy)
3. Rotate OAuth client secrets regularly
4. Use production-grade OAuth client secrets (64+ characters, cryptographically random)
5. Enable MFA for all applications (not just admin)
6. Configure email/SMS providers for MFA delivery
7. Review and harden PostgreSQL configuration (connection limits, timeouts)
8. Implement network policies (restrict FusionAuth API access)
9. Enable FusionAuth audit logging
10. Configure database backups to external storage

### Secret Management

**Never commit `.env` file to git!**

- `.env` contains database credentials and OAuth secrets
- Use `.env.template` as documentation
- Rotate credentials after any exposure
- Use different credentials for dev/staging/production environments

**OAuth Client Secrets:**
- Development: 64-character random strings (current)
- Production: Use secrets manager with rotation policy

## Troubleshooting

### FusionAuth Not Accessible After `make init`

**Symptom:** Cannot access http://localhost:9011

**Diagnosis:**
```bash
# Check container status
docker-compose ps

# View FusionAuth logs
docker-compose logs fusionauth

# Verify database is running
docker-compose logs db

# Check if .env file has correct credentials
cat .env
```

**Common Causes:**
- Containers still starting (wait 60-90 seconds after `make init`)
- Database connection errors (check DATABASE_PASSWORD matches)
- Port 9011 already in use by another service
- Insufficient Docker resources (increase memory allocation)

### Database Connection Errors

**Symptom:** FusionAuth logs show "Connection refused" or "Authentication failed"

**Solution:**
```bash
# Verify DATABASE_HOST=db in .env (matches service name in docker-compose.yml)
grep DATABASE_HOST .env

# Check DATABASE_PASSWORD matches between .env and PostgreSQL container
grep DATABASE_PASSWORD .env

# Ensure db_data volume persists
docker volume ls | grep fusionauth-db-data

# If volume missing, database was deleted - reinitialize
make destroy
make init
```

### Kickstart Configuration Not Applied

**Symptom:** Applications or roles missing in FusionAuth admin UI

**Diagnosis:**
```bash
# Check FusionAuth logs for Kickstart messages
docker-compose logs fusionauth | grep -i kickstart
```

**Common Causes:**
1. **Database not empty** - Kickstart only runs on fresh installations (empty database)
   - Solution: Destroy and reinitialize with `make destroy` (remove volumes) then `make init`

2. **Kickstart file not mounted** - Docker volume mount failed
   - Check: `docker-compose exec fusionauth ls /usr/local/fusionauth/kickstart/`
   - Should show: `kickstart.json`

3. **Invalid JSON syntax** - kickstart.json has syntax errors
   - Validate: `jq . kickstart.json`

**For post-deployment config changes:**
- Use FusionAuth Admin UI (manual)
- Use FusionAuth API with curl/Postman (scripted)
- Use Terraform FusionAuth provider (infrastructure-as-code)

### Data Loss After `docker-compose down`

**Symptom:** User data or applications missing after restart

**Diagnosis:**
```bash
# Check if database volume exists
docker volume ls | grep fusionauth-db-data

# Inspect volume details
docker volume inspect fusionauth-db-data
```

**Prevention:**
- **DO NOT** use `docker-compose down -v` (removes volumes)
- Use `make destroy` without volume removal option
- Use `make update` for configuration changes (preserves volumes)

**Recovery:**
- If backup exists: `docker-compose exec -T db psql -U fusionauth fusionauth < backup.sql`
- If no backup: Reinitialize with `make init` (Kickstart will run on empty database)

**Best Practice:**
```bash
# Before major changes, backup database
make backup

# Create timestamped backup
make backup
mv backup.sql backup-$(date +%Y%m%d-%H%M%S).sql
```

### Port Already in Use

**Symptom:** `Error: bind: address already in use` for port 9011

**Diagnosis:**
```bash
# Find process using port 9011
lsof -i :9011
# or
netstat -an | grep 9011
```

**Solution:**
1. Stop conflicting service
2. Or change FusionAuth port in docker-compose.yml:
   ```yaml
   ports:
     - "9012:9011"  # Change external port to 9012
   ```
   Then access at http://localhost:9012

### Container Crash Loop

**Symptom:** Container repeatedly restarts

**Diagnosis:**
```bash
# View last 100 lines of logs
docker-compose logs --tail=100 fusionauth

# Check container exit code
docker-compose ps
```

**Common Causes:**
- Out of memory (increase Docker memory allocation)
- Invalid environment variables (check .env syntax)
- Database connection timeout (check database health)
- Corrupted volume data (destroy and reinitialize)

## Next Steps

### Phase 2: CI/CD Automation via GitHub Actions
- Automated testing of docker-compose configuration
- Kickstart validation on pull requests
- Automated security scanning (Snyk, Trivy)
- Version upgrade testing

### Phase 3: Documentation and Operational Hardening
- Production deployment guide
- Monitoring and alerting setup
- Disaster recovery procedures
- Performance tuning guide

## References

**FusionAuth Documentation:**
- [Docker Installation](https://fusionauth.io/docs/get-started/download-and-install/docker)
- [Kickstart](https://fusionauth.io/docs/get-started/download-and-install/development/kickstart)
- [API Reference](https://fusionauth.io/docs/apis/)
- [OAuth Configuration](https://fusionauth.io/docs/lifecycle/authenticate-users/oauth/)

**PostgreSQL Documentation:**
- [PostgreSQL 17 Docker Image](https://hub.docker.com/_/postgres)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/17/)

**Project Documentation:**
- [Specification](../specifications/FUSION-AUTH.md)
- [Planning Artifacts](.planning/)
- [Research Summary](.planning/research/SUMMARY.md)

## License

Proprietary - Market Express B2B Marketplace Platform
Copyright (c) 2026 Nevada Associates LLC

---

**Version:** 1.0.0
**Last Updated:** 2026-01-20
**Maintainer:** Colin Bitterfield (colin@bitterfield.com)
