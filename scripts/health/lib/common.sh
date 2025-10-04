# shellcheck shell=bash
# 共通ユーティリティ: ログ関数や色指定などを提供

: "${USE_COLOR:=true}"

if [[ -z ${HEALTH_LIB_DIR+x} ]]; then
  HEALTH_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [[ -z ${REPO_ROOT+x} ]]; then
  REPO_ROOT="$(cd "${HEALTH_LIB_DIR}/../.." && pwd)"
fi

LOG_HELPERS="${REPO_ROOT}/.devcontainer/scripts/helpers/logging.sh"
IMAGESORCERY_HELPERS="${REPO_ROOT}/.devcontainer/scripts/helpers/imagesorcery.sh"

if [[ -f "${LOG_HELPERS}" ]]; then
  # shellcheck disable=SC1090
  source "${LOG_HELPERS}"
else
  info() { printf '[INFO] %s\n' "$*"; }
  warn() { printf '[WARN] %s\n' "$*"; }
  err()  { printf '[ERR ] %s\n' "$*"; }
  have() { command -v "$1" >/dev/null 2>&1; }
fi

if [[ -f "${IMAGESORCERY_HELPERS}" ]]; then
  # shellcheck disable=SC1090
  source "${IMAGESORCERY_HELPERS}"
else
  imagesorcery_log_dirs() { return 0; }
fi

ANSI_GREEN='\033[1;32m'
ANSI_YELLOW='\033[1;33m'
ANSI_RED='\033[1;31m'
ANSI_RESET='\033[0m'

print_status() {
  local status="$1" label="$2"
  shift 2
  local message="$*"
  local color=""

  if [[ "${USE_COLOR}" == true ]]; then
    case "$status" in
      PASS) color="$ANSI_GREEN" ;;
      WARN) color="$ANSI_YELLOW" ;;
      FAIL) color="$ANSI_RED" ;;
    esac
  fi

  printf '%b[%s]%b %s: %s\n' "$color" "$status" "$ANSI_RESET" "$label" "$message"
}
