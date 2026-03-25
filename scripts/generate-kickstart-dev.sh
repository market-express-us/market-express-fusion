#!/usr/bin/env bash
#
# Generate kickstart-dev.json for VPS deployment
# kickstart.json now uses #{ENV.X} interpolation natively — just copy it.
#
# Author: Colin Bitterfield
# Email: colin@bitterfield.com
# Date Created: 2026-01-21
# Date Updated: 2026-03-25
# Version: 2.0.0
#
# Changelog:
#   2.0.0: Remove sed substitution — kickstart.json uses #{ENV.X} natively (v2 kickstart)
#   1.0.0: Initial sed-based substitution (v1 kickstart)

set -euo pipefail

if [ ! -f "kickstart.json" ]; then
  echo "ERROR: kickstart.json not found"
  exit 1
fi

cp kickstart.json kickstart-dev.json
echo "✓ Generated kickstart-dev.json (copied from kickstart.json)"
echo "  Secrets injected via #{ENV.X} interpolation at container start"
