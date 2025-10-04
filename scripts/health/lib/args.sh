# shellcheck shell=bash
# 引数解析とオプション管理

RUN_MODE="full"
OUTPUT_FORMAT="text"
USE_COLOR=${USE_COLOR:-true}
LIST_CHECKS=false
SKIP_CHECKS=()

show_help() {
  cat <<'EOF'
Claym health check
Usage: check-environment.sh [--quick] [--full] [--json] [--list-checks] [--skip <id>] [--no-color]

Options:
  --quick         Run the minimal fast checks (default is full suite)
  --full          Run all checks (default)
  --json          Output machine-readable JSON summary only (no text)
  --list-checks   Print available check IDs and exit
  --skip <id>     Skip a specific check (can be repeated)
  --no-color      Disable ANSI colors in text output
  -h, --help      Display this help
EOF
}

parse_args() {
  while (($#)); do
    case "$1" in
      --quick)
        RUN_MODE="quick"
        ;;
      --full)
        RUN_MODE="full"
        ;;
      --json)
        OUTPUT_FORMAT="json"
        ;;
      --list-checks)
        LIST_CHECKS=true
        ;;
      --no-color)
        USE_COLOR=false
        ;;
      --skip)
        if [[ $# -lt 2 ]]; then
          err "--skip requires an argument"
          exit 2
        fi
        SKIP_CHECKS+=("$2")
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      --)
        shift
        break
        ;;
      *)
        err "Unknown option: $1"
        show_help
        exit 2
        ;;
    esac
    shift
  done
}

is_skipped() {
  local id="$1"
  local skip
  for skip in "${SKIP_CHECKS[@]}"; do
    if [[ "$skip" == "$id" ]]; then
      return 0
    fi
  done
  return 1
}
