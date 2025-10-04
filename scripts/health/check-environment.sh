#!/usr/bin/env bash
# Claym dev container health check entry point

set -Eeuo pipefail

readonly HEALTH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${HEALTH_DIR}/../.." && pwd)"
readonly HEALTH_LIB_DIR="${HEALTH_DIR}/lib"

# ライブラリの読み込み
# shellcheck source=lib/common.sh
source "${HEALTH_LIB_DIR}/common.sh"
# shellcheck source=lib/args.sh
source "${HEALTH_LIB_DIR}/args.sh"
# shellcheck source=lib/core.sh
source "${HEALTH_LIB_DIR}/core.sh"

parse_args "$@"

# チェックモジュールをロード
for module in "${HEALTH_DIR}/checks"/*.sh; do
  # shellcheck disable=SC1090
  source "$module"
done

if [[ "$LIST_CHECKS" == true ]]; then
  list_checks
  exit 0
fi

run_all_checks
exit $?
