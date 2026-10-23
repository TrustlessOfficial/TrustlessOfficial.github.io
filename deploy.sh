#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${HOME}/Documents/GitHub/finality-lab/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing Cloudflare env file: $ENV_FILE" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

export CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-${CLOUDFLARE_MILES_MINTON_ACCOUNT_ID:-}}"
export CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-${CLOUDFLARE_MILES_MINTON_PAGES_TOKEN:-}}"

if [[ -z "$CLOUDFLARE_ACCOUNT_ID" || -z "$CLOUDFLARE_API_TOKEN" ]]; then
  echo "Missing CLOUDFLARE_ACCOUNT_ID or CLOUDFLARE_API_TOKEN after sourcing $ENV_FILE" >&2
  exit 1
fi

cd "$ROOT"

# Static site: stage only the public files into dist/.
# Leaves out git, deploy tooling, dependencies, and the GitHub Pages CNAME file.
rm -rf dist
mkdir dist
rsync -a \
  --exclude '.git' \
  --exclude '.gitignore' \
  --exclude '.wrangler' \
  --exclude '.yarn' \
  --exclude '.env*' \
  --exclude '.DS_Store' \
  --exclude 'node_modules' \
  --exclude 'dist' \
  --exclude 'package.json' \
  --exclude 'yarn.lock' \
  --exclude '.yarnrc.yml' \
  --exclude 'deploy.sh' \
  --exclude 'CNAME' \
  --exclude 'README.md' \
  ./ dist/

yarn wrangler pages deploy dist --project-name trustlessfi --commit-dirty=true
