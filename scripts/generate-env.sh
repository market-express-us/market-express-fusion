#!/usr/bin/env bash
#
# Generate .env file from .env.template with random secure passwords
#
# Author: Colin Bitterfield
# Email: colin@bitterfield.com
# Date Created: 2026-01-20
# Date Updated: 2026-01-20
# Version: 0.1.0
#
# Usage:
#   ./scripts/generate-env.sh
#
# This script:
# - Copies .env.template to .env
# - Generates cryptographically secure random passwords
# - Replaces placeholder values with generated passwords
# - Preserves all other environment variables and comments

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory (works regardless of where it's called from)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

ENV_TEMPLATE="${PROJECT_ROOT}/.env.template"
ENV_FILE="${PROJECT_ROOT}/.env"

# Function to generate secure random password
generate_password() {
  local length=${1:-32}
  # Use /dev/urandom for cryptographically secure random data
  # LC_ALL=C ensures proper character handling
  # 2>/dev/null suppresses SIGPIPE error when head closes pipe early
  LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()-_=+' < /dev/urandom 2>/dev/null | head -c "$length"
}

# Function to generate alphanumeric password (for database names, usernames)
generate_alphanumeric() {
  local length=${1:-16}
  LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c "$length"
}

echo -e "${GREEN}FusionAuth Environment Generator${NC}"
echo "================================"
echo ""

# Check if .env.template exists
if [ ! -f "$ENV_TEMPLATE" ]; then
  echo -e "${RED}ERROR: .env.template not found at $ENV_TEMPLATE${NC}"
  exit 1
fi

# Check if .env already exists
if [ -f "$ENV_FILE" ]; then
  echo -e "${YELLOW}WARNING: .env file already exists${NC}"
  read -p "Overwrite existing .env? (yes/no): " confirm
  if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
  fi
  # Backup existing .env
  backup="${ENV_FILE}.backup.$(date +%Y%m%d-%H%M%S)"
  cp "$ENV_FILE" "$backup"
  echo -e "${GREEN}Backed up existing .env to $backup${NC}"
fi

echo "Generating secure random passwords..."

# Generate passwords (set +e to ignore SIGPIPE from tr/head pipe)
set +e
DB_PASSWORD=$(generate_password 32)
FUSIONAUTH_PASSWORD=$(generate_password 32)
set -e

# Copy template to .env
cp "$ENV_TEMPLATE" "$ENV_FILE"

# Replace placeholder values with generated passwords
# Using platform-compatible sed (works on both macOS and Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS sed
  sed -i '' "s/^DATABASE_PASSWORD=.*/DATABASE_PASSWORD=${DB_PASSWORD}/" "$ENV_FILE"
else
  # Linux sed
  sed -i "s/^DATABASE_PASSWORD=.*/DATABASE_PASSWORD=${DB_PASSWORD}/" "$ENV_FILE"
fi

echo ""
echo -e "${GREEN}✓ .env file created successfully${NC}"
echo ""
echo "Generated credentials:"
echo "  - DATABASE_PASSWORD: <32 character random password>"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC}"
echo "  1. .env file is gitignored and will NOT be committed"
echo "  2. Review .env and adjust any non-password settings if needed"
echo "  3. Keep these credentials secure - do not share or commit them"
echo ""
echo "Next steps:"
echo "  1. Review: cat .env"
echo "  2. Deploy: make init"
echo ""
