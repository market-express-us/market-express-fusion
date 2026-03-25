#!/usr/bin/env bash
#
# FusionAuth VPS Rebuild Script
# Destroys existing volumes and re-initializes from kickstart.
# Use when kickstart.json changes require a clean database.
#
# Author: Colin Bitterfield
# Email: colin@bitterfield.com
# Date Created: 2026-03-25
# Date Updated: 2026-03-25
# Version: 1.0.0
#
# WARNING: This destroys ALL FusionAuth data (users, apps, groups).
# Only run when rebuilding from scratch.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=======================================${NC}"
echo -e "${YELLOW}FusionAuth VPS REBUILD (Data Destroy)${NC}"
echo -e "${YELLOW}=======================================${NC}"
echo ""
echo -e "${RED}WARNING: This will destroy all FusionAuth data and reinitialize from kickstart.${NC}"
echo ""

# Stop and remove containers + volumes
echo "Stopping FusionAuth and removing volumes..."
docker compose down -v --remove-orphans
echo -e "${GREEN}✓ Containers stopped and volumes removed${NC}"

# Now run the standard deploy (kickstart will run on fresh DB)
echo ""
echo "Running fresh deployment..."
bash "$(dirname "$0")/deploy-vps.sh"
