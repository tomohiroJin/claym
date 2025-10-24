#!/usr/bin/env bash
# セットアップスクリプトのテストを実行するスクリプト
#
# このスクリプトは bats-core を使用して、セットアップスクリプトの
# 自動テストを実行します。

set -euo pipefail

# =============================================================================
# 共通ライブラリの読み込み
# =============================================================================

# scripts/lib/common.sh から色定義とログ関数を読み込み
readonly TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPTS_ROOT="$(cd "${TEST_SCRIPT_DIR}/.." && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPTS_ROOT}/.." && pwd)"

# 共通ライブラリが存在する場合は読み込む
if [[ -f "${SCRIPTS_ROOT}/lib/common.sh" ]]; then
    # shellcheck source=../lib/common.sh
    source "${SCRIPTS_ROOT}/lib/common.sh"
else
    # フォールバック: 共通ライブラリがない場合の基本定義
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly NC='\033[0m'

    log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
    log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
    log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
    log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
    show_header() { local title="$1" width="${2:-40}"; printf '=%.0s' $(seq 1 "$width"); echo ""; printf "  %s\\n" "$title"; printf '=%.0s' $(seq 1 "$width"); echo ""; echo ""; }
    show_footer() { local message="$1" width="${2:-40}"; echo ""; printf '=%.0s' $(seq 1 "$width"); echo ""; echo -e "  ${message}"; printf '=%.0s' $(seq 1 "$width"); echo ""; echo ""; }
fi

# テストディレクトリ
TESTS_DIR="${PROJECT_ROOT}/tests/setup"

# bats が利用可能かチェック
check_bats_installation() {
    log_info "bats-core のインストールを確認中..."

    if ! command -v bats &> /dev/null; then
        log_error "bats-core がインストールされていません"
        log_info "インストール方法:"
        log_info "  - Dockerfile でインストール: 詳細は .devcontainer/Dockerfile を参照"
        log_info "  - 手動インストール: https://github.com/bats-core/bats-core"
        exit 1
    fi

    log_success "bats-core が利用可能です: $(bats --version)"
}

# ヘルパーライブラリの確認
check_bats_helpers() {
    log_info "bats ヘルパーライブラリを確認中..."

    local missing_helpers=()

    [[ ! -d "/usr/local/lib/bats-support" ]] && missing_helpers+=("bats-support")
    [[ ! -d "/usr/local/lib/bats-assert" ]] && missing_helpers+=("bats-assert")
    [[ ! -d "/usr/local/lib/bats-file" ]] && missing_helpers+=("bats-file")

    if [[ ${#missing_helpers[@]} -gt 0 ]]; then
        log_warn "以下のヘルパーライブラリが見つかりません:"
        for helper in "${missing_helpers[@]}"; do
            log_warn "  - ${helper}"
        done
        log_info "一部のテストが失敗する可能性があります"
        return 1
    fi

    log_success "すべてのヘルパーライブラリが利用可能です"
}

# テストファイルの存在確認
check_test_files() {
    log_info "テストファイルを確認中..."

    local test_files=(
        "${TESTS_DIR}/init-ai-configs.bats"
        "${TESTS_DIR}/reinit-ai-configs.bats"
        "${TESTS_DIR}/copy-template-to-local.bats"
    )

    local missing_files=()

    for file in "${test_files[@]}"; do
        if [[ ! -f "${file}" ]]; then
            missing_files+=("${file}")
        fi
    done

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "以下のテストファイルが見つかりません:"
        for file in "${missing_files[@]}"; do
            log_error "  - ${file}"
        done
        exit 1
    fi

    log_success "すべてのテストファイルが存在します"
}

# テストの実行
run_tests() {
    local test_target="$1"

    log_info "テストを実行中..."
    echo ""

    case "${test_target}" in
        "init")
            bats "${TESTS_DIR}/init-ai-configs.bats"
            ;;
        "reinit")
            bats "${TESTS_DIR}/reinit-ai-configs.bats"
            ;;
        "copy")
            bats "${TESTS_DIR}/copy-template-to-local.bats"
            ;;
        "all")
            bats "${TESTS_DIR}"/*.bats
            ;;
        *)
            log_error "不明なテスト対象: ${test_target}"
            show_usage
            exit 1
            ;;
    esac
}

# 使い方を表示
show_usage() {
    cat << 'EOF'
Usage: bash scripts/test/run-setup-tests.sh [TARGET]

セットアップスクリプトのテストを実行します。

TARGET:
  init      init-ai-configs.sh のテストを実行
  reinit    reinit-ai-configs.sh のテストを実行
  copy      copy-template-to-local.sh のテストを実行
  all       すべてのテストを実行（デフォルト）

Options:
  -h, --help    このヘルプメッセージを表示

Examples:
  # すべてのテストを実行
  bash scripts/test/run-setup-tests.sh

  # 特定のテストのみ実行
  bash scripts/test/run-setup-tests.sh init

Environment Variables:
  PROJECT_ROOT    プロジェクトルートディレクトリ（自動検出）
  TESTS_DIR       テストファイルのディレクトリ（自動検出）

EOF
}

# メイン処理
main() {
    # 引数のパース
    local test_target="all"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            init|reinit|copy|all)
                test_target="$1"
                shift
                ;;
            *)
                log_error "不明なオプション: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    echo "========================================"
    echo "  Setup Scripts Test Runner"
    echo "========================================"
    echo ""

    log_info "プロジェクトルート: ${PROJECT_ROOT}"
    log_info "テストディレクトリ: ${TESTS_DIR}"
    echo ""

    # 事前チェック
    check_bats_installation
    check_bats_helpers || true  # 警告のみでエラーにはしない
    check_test_files
    echo ""

    # テスト実行
    echo "========================================"
    log_info "テスト対象: ${test_target}"
    echo "========================================"
    echo ""

    if run_tests "${test_target}"; then
        echo ""
        echo "========================================"
        log_success "すべてのテストが成功しました！"
        echo "========================================"
        exit 0
    else
        echo ""
        echo "========================================"
        log_error "一部のテストが失敗しました"
        echo "========================================"
        exit 1
    fi
}

# スクリプト実行
main "$@"
