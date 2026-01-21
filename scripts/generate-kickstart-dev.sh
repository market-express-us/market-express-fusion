#!/usr/bin/env bash
#
# Generate kickstart-dev.json for VPS deployment
# Replaces sandbox values with dev environment values from environment variables
#
# Author: Colin Bitterfield
# Email: colin@bitterfield.com
# Date Created: 2026-01-21
# Version: 1.0.0

set -euo pipefail

# Verify required environment variables
REQUIRED_VARS=(
  "FUSIONAUTH_ADMIN_EMAIL"
  "FUSIONAUTH_ADMIN_PASSWORD"
  "FUSIONAUTH_API_KEY"
  "ADMIN_CLIENT_SECRET"
  "VENDOR_CLIENT_SECRET"
  "STORE_CLIENT_SECRET"
  "EMPLOYEE_CLIENT_SECRET"
)

for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: Required environment variable $var not set"
    exit 1
  fi
done

# Read the sandbox kickstart.json
if [ ! -f "kickstart.json" ]; then
  echo "ERROR: kickstart.json not found"
  exit 1
fi

echo "Generating kickstart-dev.json for VPS deployment..."

# Copy kickstart.json to kickstart-dev.json and replace values
cp kickstart.json kickstart-dev.json

# Replace sandbox URLs with dev URLs
sed -i.bak 's|http://localhost:9000|https://app-dev.marketexpress.us|g' kickstart-dev.json

# Replace hardcoded secrets with values from environment variables
# Admin email and password
sed -i.bak "s|admin@marketexpress.us|${FUSIONAUTH_ADMIN_EMAIL}|g" kickstart-dev.json
sed -i.bak "s|oIYfDqX2TU9xsLPRBMjQF0pJJVAHbOal|${FUSIONAUTH_ADMIN_PASSWORD}|g" kickstart-dev.json

# API Key
sed -i.bak "s|xCsOSKWaPTYy1DDJSZTrvbYUBWFpu2qyoukwaFsAKbINSD1xy8hpEDzeEUebn9r7|${FUSIONAUTH_API_KEY}|g" kickstart-dev.json

# Client Secrets
sed -i.bak "s|09MLZa9lQvaMvFGaesaEviVaTph8dyAHhlRoH93xF2y7uLi1GdHm297JanLhnQiN|${ADMIN_CLIENT_SECRET}|g" kickstart-dev.json
sed -i.bak "s|yzWPgzc95Q51xVE6vEfsWd7oXCNqYrkdWOn7v02QVSTh0SDOjsk2lmRkwWfsm9MS|${VENDOR_CLIENT_SECRET}|g" kickstart-dev.json
sed -i.bak "s|o51hDzBysU5xFQAoO73UEeu2lpHPZZN5D2kcsUjTXOEENBQk2rpCAFYO9a6hW1QL|${STORE_CLIENT_SECRET}|g" kickstart-dev.json
sed -i.bak "s|zXug1h9OjagAFgk8kf3KzHdCiHqnSIB9fmG4oNnv97fqs7563t1eSKEFt23GjMoO|${EMPLOYEE_CLIENT_SECRET}|g" kickstart-dev.json

# Remove backup file
rm -f kickstart-dev.json.bak

echo "✓ Generated kickstart-dev.json successfully"
echo "  - Replaced localhost URLs with https://app-dev.marketexpress.us"
echo "  - Replaced sandbox secrets with environment variable values"
