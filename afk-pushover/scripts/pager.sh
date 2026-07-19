#!/usr/bin/env bash
# pager.sh — Pushover pager for AFK Mode (afk-pushover skill).
#
# Sends a push notification via Pushover. Secrets are read from an env file,
# never passed as args, never echoed on error.
#
# Env file search order (first match wins):
#   1. $AFK_PUSHOVER_ENV          (explicit override)
#   2. ~/.config/afk-pushover/.env  (default install location, user-level)
#   3. <skill dir>/.env.local       (fallback for non-standard installs)
#
# Env vars consumed:
#   PUSHOVER_USER              (required)  account user key
#   PUSHOVER_TOKEN             (required)  application API token
#   SOFT_CHECK_IDLE_SECONDS    (optional)  default 1800; informational only,
#                                          used by the skill to decide whether
#                                          to append the Soft-Check note.
#
# Usage:
#   pager.sh "<message>"
#   pager.sh "<message>" --title "Custom title"
#   pager.sh "<message>" --priority 2     # emergency, breaks DND
#
# Exit codes:
#   0  sent
#   1  usage / missing message
#   2  missing or unreadable env file / keys
#   3  Pushover API rejected the request

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$(cd ~ && pwd)"

# --- resolve env file --------------------------------------------------------
ENV_FILE=""
for candidate in \
  "${AFK_PUSHOVER_ENV:-}" \
  "$HOME_DIR/.config/afk-pushover/.env" \
  "$SCRIPT_DIR/.env.local"
do
  [[ -z "$candidate" ]] && continue
  if [[ -f "$candidate" && -r "$candidate" ]]; then
    ENV_FILE="$candidate"
    break
  fi
done

if [[ -z "$ENV_FILE" ]]; then
  echo "no env file found. Looked for (in order):" >&2
  [[ -n "${AFK_PUSHOVER_ENV:-}" ]] && echo "  - \$AFK_PUSHOVER_ENV = $AFK_PUSHOVER_ENV" >&2
  echo "  - ~/.config/afk-pushover/.env" >&2
  echo "  - $SCRIPT_DIR/.env.local" >&2
  echo "Copy assets/env.local.example to one of those and fill in PUSHOVER_USER + PUSHOVER_TOKEN." >&2
  exit 2
fi

# --- arg parsing -------------------------------------------------------------
MESSAGE=""
TITLE="Agent needs you"
PRIORITY="1"   # 1 = high (breaks silent on iOS). Use 2 for emergency.

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      [[ $# -lt 2 ]] && { echo "--title requires a value" >&2; exit 1; }
      TITLE="$2"; shift 2 ;;
    --priority)
      [[ $# -lt 2 ]] && { echo "--priority requires a value" >&2; exit 1; }
      PRIORITY="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,30p' "$0"; exit 0 ;;
    -*)
      echo "unknown flag: $1" >&2; exit 1 ;;
    *)
      if [[ -z "$MESSAGE" ]]; then MESSAGE="$1"; else
        echo "unexpected extra argument: $1" >&2; exit 1
      fi
      shift ;;
  esac
done

if [[ -z "$MESSAGE" ]]; then
  echo "usage: $0 \"<message>\" [--title \"...\"] [--priority 0|1|2]" >&2
  exit 1
fi

# --- load secrets ------------------------------------------------------------
set +u
# shellcheck disable=SC1090
source "$ENV_FILE"
set -u

if [[ -z "${PUSHOVER_USER:-}" || -z "${PUSHOVER_TOKEN:-}" ]]; then
  echo "$ENV_FILE must define PUSHOVER_USER and PUSHOVER_TOKEN" >&2
  exit 2
fi

# --- send --------------------------------------------------------------------
RESPONSE_FILE="$(mktemp)"
HTTP_CODE="$(
  curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
    --retry 3 --retry-delay 2 --retry-connrefused \
    --max-time 15 \
    -F "token=$PUSHOVER_TOKEN" \
    -F "user=$PUSHOVER_USER" \
    -F "title=$TITLE" \
    -F "message=$MESSAGE" \
    -F "priority=$PRIORITY" \
    https://api.pushover.net/1/messages.json 2>/dev/null
)"

# Scrub response before any error printing; Pushover's error JSON references
# status/errors, not the token, but we still write to temp + clean up.
BODY="$(cat "$RESPONSE_FILE" 2>/dev/null || true)"
rm -f "$RESPONSE_FILE"

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "pushover failed: HTTP $HTTP_CODE" >&2
  echo "response: $BODY" >&2
  exit 3
fi

echo "paged: $TITLE"
