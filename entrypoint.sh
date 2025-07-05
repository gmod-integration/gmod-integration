#!/usr/bin/env bash
set -e

: "${STEAM_USER:?Please set STEAM_USER}"
: "${STEAM_PASS:?Please set STEAM_PASS}"
: "${CONTENT_PATH:?Please set CONTENT_PATH (e.g. /data/adn-test)}"
: "${TITLE:?Please set TITLE}"
: "${DESCRIPTION:?Please set DESCRIPTION}"

# Optional Steam Guard:
STEAM_GUARD_ARG=""
[ -n "$STEAM_GUARD" ] && STEAM_GUARD_ARG="$STEAM_GUARD"

# Generate the VDF pointing at your folder
cat > /app/workshop_item.vdf <<EOF
"workshopitem"
{
    "appid"           "4000"
    "publishedfileid" "${PUBLISHED_FILE_ID:-0}"
    "contentfolder"   "${CONTENT_PATH}"
    "previewfile"     "${PREVIEW_FILE:-}"
    "visibility"      "${VISIBILITY:-0}"
    "title"           "${TITLE}"
    "description"     "${DESCRIPTION}"
}
EOF

echo "[`date '+%F %T'`] Publishing to Workshop…"
/steamcmd/steamcmd.sh +login "${STEAM_USER}" "${STEAM_PASS}" "${STEAM_GUARD_ARG}" \
    +workshop_build_item /app/workshop_item.vdf \
    +quit

echo "[`date '+%F %T'`] Done."
