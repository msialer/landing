#!/usr/bin/env bash
set -euo pipefail

# Sync the latest English and Spanish CVs from Google Drive to the landing page repo.
# The CVs are expected to match the patterns:
#   Mauricio-Sialer-Head-of-Product-Digital-Commerce (EN AAAA.MM.DDx).pdf
#   Mauricio-Sialer-Lider-de-Producto-Comercio-Digital (ES AAAA.MM.DDx).pdf
# where AAAA.MM.DD is the date and x is the version letter (a-z, z is newest).
# Google Drive folder ID:
GDRIVE_FOLDER_ID="1WD8jqkP68A948oBiBsWv-eiRcLTtcJtw"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE_DIR="gdrive:"

EN_TARGET="${REPO_DIR}/mauricio-sialer-cv-en.pdf"
ES_TARGET="${REPO_DIR}/mauricio-sialer-cv-es.pdf"

CHANGED=0

echo "[$(date -Iseconds)] Starting CV sync..."

# Find the latest CV for a given base name and language suffix (EN or ES).
find_latest() {
  local base="$1"
  local lang="$2"
  rclone lsf "${REMOTE_DIR}" \
    --drive-root-folder-id "${GDRIVE_FOLDER_ID}" \
    --include "*.pdf" 2>/dev/null \
    | grep -i "${base}" \
    | grep -i "(${lang} " \
    | sort -t'(' -k2,2 -r \
    | head -n1
}

# Download and update a CV if it has changed.
sync_lang() {
  local base="$1"
  local lang="$2"
  local target="$3"
  local latest

  latest=$(find_latest "${base}" "${lang}")
  if [ -z "${latest}" ]; then
    echo "[$(date -Iseconds)] ERROR: No ${lang} CV PDF found in Google Drive folder ${GDRIVE_FOLDER_ID}"
    return 1
  fi

  echo "[$(date -Iseconds)] Latest ${lang} CV found: ${latest}"

  # Download to a temporary file first.
  local tmp_file
  tmp_file=$(mktemp)

  rclone copyto "${REMOTE_DIR}${latest}" "${tmp_file}" \
    --drive-root-folder-id "${GDRIVE_FOLDER_ID}" 2>/dev/null

  # Compare with existing file.
  if [ -f "${target}" ] && cmp -s "${tmp_file}" "${target}"; then
    rm -f "${tmp_file}"
    echo "[$(date -Iseconds)] ${target} is already up to date. No changes."
    return 0
  fi

  # Update target file.
  cp "${tmp_file}" "${target}"
  rm -f "${tmp_file}"
  echo "[$(date -Iseconds)] Updated ${target}"
  CHANGED=1
  return 0
}

sync_lang "Mauricio-Sialer-Head-of-Product-Digital-Commerce" "EN" "${EN_TARGET}" || true
sync_lang "Mauricio-Sialer-Lider-de-Producto-Comercio-Digital" "ES" "${ES_TARGET}" || true

if [ "${CHANGED}" -eq 0 ]; then
  echo "[$(date -Iseconds)] All available CVs are up to date. No changes."
  exit 0
fi

# Commit and push if there are changes.
cd "${REPO_DIR}"
git add "${EN_TARGET}" "${ES_TARGET}"
git commit -m "chore: sync CVs from Google Drive (EN + ES)"
git push origin main

echo "[$(date -Iseconds)] CVs synced and pushed."

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
