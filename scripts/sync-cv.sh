#!/usr/bin/env bash
set -euo pipefail

# Sync the latest CV from Google Drive to the landing page repo.
# The CV is expected to match the pattern:
#   Mauricio-Sialer-Head-of-Product-Digital-Commerce (EN AAAA.MM.DDx).pdf
# where AAAA.MM.DD is the date and x is the version letter (a-z, z is newest).
# Google Drive folder ID:
GDRIVE_FOLDER_ID="1WD8jqkP68A948oBiBsWv-eiRcLTtcJtw"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_FILE="${REPO_DIR}/mauricio-sialer-cv.pdf"
REMOTE_DIR="gdrive:"

echo "[$(date -Iseconds)] Starting CV sync..."

# List PDFs in the CV folder and find the one with the most recent date and highest
# version letter in the filename. Example:
#   Mauricio-Sialer-Head-of-Product-Digital-Commerce (EN 2026.08.06b).pdf
LATEST_REMOTE=$(rclone lsf "${REMOTE_DIR}" \
  --drive-root-folder-id "${GDRIVE_FOLDER_ID}" \
  --include "*.pdf" 2>/dev/null \
  | grep -i "Mauricio-Sialer-Head-of-Product-Digital-Commerce" \
  | sort -t'(' -k2,2 -r \
  | head -n1)

if [ -z "${LATEST_REMOTE}" ]; then
  echo "[$(date -Iseconds)] ERROR: No CV PDF found in Google Drive folder ${GDRIVE_FOLDER_ID}"
  exit 1
fi

echo "[$(date -Iseconds)] Latest CV found: ${LATEST_REMOTE}"

# Download to a temporary file first.
TMP_FILE=$(mktemp)
trap 'rm -f "${TMP_FILE}"' EXIT

rclone copyto "${REMOTE_DIR}${LATEST_REMOTE}" "${TMP_FILE}" \
  --drive-root-folder-id "${GDRIVE_FOLDER_ID}" 2>/dev/null

# Compare with existing file.
if [ -f "${TARGET_FILE}" ] && cmp -s "${TMP_FILE}" "${TARGET_FILE}"; then
  echo "[$(date -Iseconds)] CV is already up to date. No changes."
  exit 0
fi

# Update target file.
cp "${TMP_FILE}" "${TARGET_FILE}"
echo "[$(date -Iseconds)] Updated ${TARGET_FILE}"

# Commit and push if there are changes.
cd "${REPO_DIR}"
if git diff --quiet HEAD -- "${TARGET_FILE}" 2>/dev/null; then
  echo "[$(date -Iseconds)] No git diff. Skipping commit."
  exit 0
fi

git add "${TARGET_FILE}"
git commit -m "chore: sync CV from Google Drive (${LATEST_REMOTE})"
git push origin main

echo "[$(date -Iseconds)] CV synced and pushed."

# Trigger a production deployment on Vercel using the stored token.
VERCEL_TOKEN_FILE="${HOME}/projects/personal-server/infra/credentials/landing/vercel-token"
if [ -f "${VERCEL_TOKEN_FILE}" ]; then
  VERCEL_TOKEN="$(cat "${VERCEL_TOKEN_FILE}")"
  if [ -n "${VERCEL_TOKEN}" ]; then
    echo "[$(date -Iseconds)] Triggering Vercel production deploy..."
    npx vercel@latest --prod --yes --token "${VERCEL_TOKEN}"
    echo "[$(date -Iseconds)] Vercel deploy triggered."
  else
    echo "[$(date -Iseconds)] WARNING: Vercel token file is empty. Skipping deploy trigger."
  fi
else
  echo "[$(date -Iseconds)] WARNING: Vercel token file not found at ${VERCEL_TOKEN_FILE}. Skipping deploy trigger."
fi
