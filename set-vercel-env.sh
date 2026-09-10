#!/usr/bin/env bash
# Configures the env vars the Loyola backend needs on Vercel.
# Usage: VERCE_TOKEN=<your-token> ./set-vercel-env.sh [production|preview]
set -euo pipefail

if [ -z "${VERCEL_TOKEN:-}" ]; then
  echo "Set VERCEL_TOKEN (get one at https://vercel.com/account/tokens)" >&2
  exit 1
fi

ENV="${1:-production}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT}/backend/.env"
SA_FILE="${ROOT}/backend/firebase-service-account.json"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE" >&2
  exit 1
fi

run() {
  # shellcheck disable=SC2001
  VERCEL_TOKEN="$VERCEL_TOKEN" vercel env add "$1" "$ENV" <<<"$2"
}

get() { grep -E "^${1}=" "$ENV_FILE" | head -1 | cut -d= -f2-; }

run MONGODB_URI "$(get MONGODB_URI)"
run MONGODB_DB_NAME "$(get MONGODB_DB_NAME)"
run SESSION_SECRET "$(get SESSION_SECRET)"
run ERP_CREDENTIALS_ENCRYPTION_KEY "$(get ERP_CREDENTIALS_ENCRYPTION_KEY)"
run FIREBASE_PROJECT_ID "$(get FIREBASE_PROJECT_ID)"
run LRMS_BASE_URL "$(get LRMS_BASE_URL)"
run NODE_ENV "$ENV"
  run FIREBASE_SERVICE_ACCOUNT "$(cat "$SA_FILE")"
  echo "Added FIREBASE_SERVICE_ACCOUNT from $SA_FILE"
else
  echo "NOTE: $SA_FILE not found - add FIREBASE_SERVICE_ACCOUNT manually" >&2
fi

echo "Done. Redeploy with: vercel --prod"