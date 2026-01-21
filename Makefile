# FusionAuth Deployment Automation
#
# Provides semantic deployment targets for FusionAuth infrastructure.
# Abstracts Docker Compose complexity for developers and CI/CD pipelines.
#
# Author: Colin Bitterfield
# Email: colin@bitterfield.com
# Version: 1.0.0
# Date Created: 2026-01-20
# Date Updated: 2026-01-20
#
# Usage:
#   make init     - First-time deployment with environment setup
#   make update   - Deploy configuration changes (recreate containers)
#   make destroy  - Tear down environment (optionally remove data)
#   make status   - Check service health
#   make logs     - View container logs

.PHONY: init update destroy status logs help clean backup env-sandbox env-dev env-stage env-prod status-env

# Default target
help:
	@echo "FusionAuth Deployment Automation"
	@echo ""
	@echo "Environment-specific targets:"
	@echo "  make env-sandbox  - Generate sandbox .env (local development)"
	@echo "  make env-dev      - Deploy to dev VPS (via GitHub Actions)"
	@echo "  make env-stage    - Deploy to stage OCI (via GitHub Actions, requires release)"
	@echo "  make env-prod     - Deploy to prod OCI (via GitHub Actions, requires release)"
	@echo "  make status-env   - Show current environment configuration"
	@echo ""
	@echo "Available targets:"
	@echo "  make init     - First-time deployment (creates .env, starts containers)"
	@echo "  make update   - Deploy configuration changes (preserves data)"
	@echo "  make destroy  - Tear down environment (optional data removal)"
	@echo "  make status   - Check service health"
	@echo "  make logs     - View container logs (follow mode)"
	@echo "  make backup   - Backup PostgreSQL database to backup.sql"
	@echo "  make clean    - Remove stopped containers and orphaned volumes"
	@echo ""
	@echo "Quick start (Sandbox):"
	@echo "  1. make env-sandbox"
	@echo "  2. make init"
	@echo "  3. Visit http://localhost:9011"
	@echo ""
	@echo "Quick start (Dev VPS):"
	@echo "  1. Configure GitHub Secrets"
	@echo "  2. git push origin main"
	@echo "  3. Visit https://auth-dev.marketexpress.us"
	@echo ""

# First-time deployment
init:
	@echo "========================================="
	@echo "FusionAuth First-Time Deployment"
	@echo "========================================="
	@echo ""
	@if [ ! -f .env ]; then \
		echo "Creating .env from .env.template..."; \
		cp .env.template .env; \
		echo ""; \
		echo "IMPORTANT: Edit .env file with your actual credentials!"; \
		echo "  - Change DATABASE_PASSWORD"; \
		echo "  - Review other settings as needed"; \
		echo ""; \
		echo "After editing .env, run 'make init' again."; \
		echo ""; \
		exit 1; \
	fi
	@echo "Environment file exists: .env"
	@echo ""
	@echo "Pulling Docker images..."
	@docker-compose pull
	@echo ""
	@echo "Starting containers in background..."
	@docker-compose up -d
	@echo ""
	@echo "Waiting for services to start (this may take 60-90 seconds)..."
	@sleep 15
	@echo "Checking database health..."
	@for i in 1 2 3 4 5 6; do \
		if docker-compose exec -T db pg_isready -U fusionauth >/dev/null 2>&1; then \
			echo "Database is ready!"; \
			break; \
		fi; \
		echo "Waiting for database ($$i/6)..."; \
		sleep 10; \
	done
	@echo ""
	@echo "Checking FusionAuth health..."
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		if curl --fail --silent http://localhost:9011/api/status >/dev/null 2>&1; then \
			echo "FusionAuth is ready!"; \
			break; \
		fi; \
		echo "Waiting for FusionAuth ($$i/10)..."; \
		sleep 10; \
	done
	@echo ""
	@echo "========================================="
	@echo "Deployment Complete!"
	@echo "========================================="
	@echo ""
	@echo "FusionAuth Admin UI: http://localhost:9011"
	@echo ""
	@echo "Kickstart has configured three applications:"
	@echo "  - marketexpress-admin  (platform administrators, MFA required)"
	@echo "  - marketexpress-vendor (vendor users, MFA optional)"
	@echo "  - marketexpress-store  (customers, MFA optional)"
	@echo ""
	@echo "View status: make status"
	@echo "View logs:   make logs"
	@echo ""

# Deploy configuration changes
update:
	@echo "========================================="
	@echo "FusionAuth Configuration Update"
	@echo "========================================="
	@echo ""
	@echo "NOTE: Kickstart only runs on fresh installations."
	@echo "For configuration changes, use FusionAuth API or Terraform provider."
	@echo ""
	@echo "Pulling latest images..."
	@docker-compose pull
	@echo ""
	@echo "Recreating containers (preserving volumes)..."
	@docker-compose up -d --force-recreate
	@echo ""
	@echo "Waiting for services to restart..."
	@sleep 15
	@echo "Checking FusionAuth health..."
	@for i in 1 2 3 4 5 6; do \
		if curl --fail --silent http://localhost:9011/api/status >/dev/null 2>&1; then \
			echo "FusionAuth is ready!"; \
			break; \
		fi; \
		echo "Waiting for FusionAuth ($$i/6)..."; \
		sleep 10; \
	done
	@echo ""
	@echo "========================================="
	@echo "Update Complete!"
	@echo "========================================="
	@echo ""
	@echo "Data has been preserved (volumes not removed)"
	@echo "FusionAuth Admin UI: http://localhost:9011"
	@echo ""

# Tear down environment
destroy:
	@echo "========================================="
	@echo "FusionAuth Environment Teardown"
	@echo "========================================="
	@echo ""
	@echo "This will stop and remove containers."
	@echo ""
	@read -p "Remove database volumes (destroys all user data)? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo "Stopping containers and removing volumes..."; \
		docker-compose down -v; \
		echo ""; \
		echo "WARNING: All user data has been deleted!"; \
	else \
		echo "Stopping containers (preserving volumes)..."; \
		docker-compose down; \
		echo ""; \
		echo "Containers stopped. Data volumes preserved."; \
		echo "Restart with: make update"; \
	fi
	@echo ""
	@echo "========================================="
	@echo "Teardown Complete"
	@echo "========================================="
	@echo ""

# Check service health
status:
	@echo "========================================="
	@echo "FusionAuth Service Status"
	@echo "========================================="
	@echo ""
	@echo "Container Status:"
	@docker-compose ps
	@echo ""
	@echo "FusionAuth Health Check:"
	@if curl --fail --silent http://localhost:9011/api/status >/dev/null 2>&1; then \
		echo "  Status: HEALTHY"; \
		echo "  URL:    http://localhost:9011"; \
	else \
		echo "  Status: UNAVAILABLE"; \
		echo "  Check logs with: make logs"; \
	fi
	@echo ""
	@echo "Database Volumes:"
	@docker volume ls | grep fusionauth || echo "  No volumes found"
	@echo ""

# View container logs
logs:
	@echo "Following container logs (Ctrl+C to exit)..."
	@echo ""
	@docker-compose logs -f

# Backup database
backup:
	@echo "========================================="
	@echo "Database Backup"
	@echo "========================================="
	@echo ""
	@if ! docker-compose ps | grep fusionauth-db | grep -q Up; then \
		echo "ERROR: Database container is not running"; \
		echo "Start with: make init"; \
		exit 1; \
	fi
	@echo "Creating backup: backup.sql"
	@docker-compose exec -T db pg_dump -U fusionauth fusionauth > backup.sql
	@echo ""
	@echo "Backup complete: backup.sql"
	@echo "Restore with: docker-compose exec -T db psql -U fusionauth fusionauth < backup.sql"
	@echo ""

# Clean up stopped containers and orphaned volumes
clean:
	@echo "========================================="
	@echo "Cleanup"
	@echo "========================================="
	@echo ""
	@echo "Removing stopped containers..."
	@docker-compose rm -f
	@echo ""
	@echo "Pruning orphaned volumes (not fusionauth-db-data)..."
	@docker volume prune -f
	@echo ""
	@echo "Cleanup complete"
	@echo ""

# Environment-specific deployments
env-sandbox:
	@echo "Generating sandbox environment..."
	@./scripts/generate-env.sh

env-dev:
	@echo "========================================="
	@echo "Dev Environment Configuration"
	@echo "========================================="
	@echo ""
	@echo "ERROR: Dev environment uses GitHub Secrets"
	@echo "Deployment is handled via GitHub Actions:"
	@echo ""
	@echo "  git push origin main"
	@echo ""
	@echo "Manual VPS deployment:"
	@echo "  ssh fusion-auth@15.204.91.25"
	@echo "  cd ~/fusionauth"
	@echo "  # Set environment variables from GitHub Secrets"
	@echo "  bash scripts/deploy-vps.sh"
	@echo ""

env-stage:
	@echo "========================================="
	@echo "Stage Environment Configuration"
	@echo "========================================="
	@echo ""
	@echo "ERROR: Stage deployment not yet implemented (Phase 4)"
	@echo "Stage environment requires:"
	@echo "  - OCI Kubernetes cluster setup"
	@echo "  - Helm chart configuration"
	@echo "  - Release version/tag"
	@echo ""
	@echo "Usage (future):"
	@echo "  make env-stage RELEASE=v1.2.3"
	@echo ""

env-prod:
	@echo "========================================="
	@echo "Production Environment Configuration"
	@echo "========================================="
	@echo ""
	@echo "ERROR: Production deployment not yet implemented (Phase 4)"
	@echo "Production environment requires:"
	@echo "  - OCI Kubernetes cluster setup"
	@echo "  - Helm chart configuration"
	@echo "  - Release version/tag"
	@echo ""
	@echo "Usage (future):"
	@echo "  make env-prod RELEASE=v1.2.3"
	@echo ""

status-env:
	@echo "Current environment: $$(grep '^ENVIRONMENT=' .env 2>/dev/null | cut -d= -f2 || echo 'unknown')"
	@echo "Callback URL: $$(grep '^OAUTH_CALLBACK_BASE_URL=' .env 2>/dev/null | cut -d= -f2 || echo 'not set')"
	@echo "FusionAuth URL: $$(grep '^FUSIONAUTH_PUBLIC_URL=' .env 2>/dev/null | cut -d= -f2 || echo 'not set')"
