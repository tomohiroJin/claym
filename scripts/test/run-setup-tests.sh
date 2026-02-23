#!/usr/bin/env bash
# セットアップスクリプトおよびテンプレート品質テストを実行するスクリプト
#
# このスクリプトは bats-core を使用して以下のテストを実行します:
# - セットアップスクリプトの動作テスト（tests/setup/）
# - テンプレート品質テスト（tests/templates/）

set -euo pipefail

# =============================================================================
# 共通ライブラリの読み込み
# =============================================================================

# scripts/lib/logging.sh から色定義とログ関数を読み込み
TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_SCRIPT_DIR

SCRIPTS_ROOT="$(cd "${TEST_SCRIPT_DIR}/.." && pwd)"
readonly SCRIPTS_ROOT

PROJECT_ROOT="$(cd "${SCRIPTS_ROOT}/.." && pwd)"
readonly PROJECT_ROOT

# ログ出力ライブラリを読み込む
if [[ ! -f "${SCRIPTS_ROOT}/lib/logging.sh" ]]; then
    echo "エラー: ログ出力ライブラリが見つかりません: ${SCRIPTS_ROOT}/lib/logging.sh" >&2
    exit 1
fi

# shellcheck source=../lib/logging.sh
source "${SCRIPTS_ROOT}/lib/logging.sh"

# テストディレクトリ
SETUP_TESTS_DIR="${PROJECT_ROOT}/tests/setup"
TEMPLATE_TESTS_DIR="${PROJECT_ROOT}/tests/templates"

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
    local test_target="$1"
    log_info "テストファイルを確認中..."

    local test_files=()

    case "${test_target}" in
        "setup"|"init"|"reinit"|"copy")
            test_files=(
                "${SETUP_TESTS_DIR}/init-ai-configs.bats"
                "${SETUP_TESTS_DIR}/reinit-ai-configs.bats"
                "${SETUP_TESTS_DIR}/copy-template-to-local.bats"
            )
            ;;
        "templates")
            test_files=(
                "${TEMPLATE_TESTS_DIR}/template-existence.bats"
                "${TEMPLATE_TESTS_DIR}/template-quality.bats"
                "${TEMPLATE_TESTS_DIR}/cross-tool-consistency.bats"
                "${TEMPLATE_TESTS_DIR}/template-genericity.bats"
                "${TEMPLATE_TESTS_DIR}/init-script-integration.bats"
            )
            ;;
        "all")
            test_files=(
                "${SETUP_TESTS_DIR}/init-ai-configs.bats"
                "${SETUP_TESTS_DIR}/reinit-ai-configs.bats"
                "${SETUP_TESTS_DIR}/copy-template-to-local.bats"
                "${TEMPLATE_TESTS_DIR}/template-existence.bats"
                "${TEMPLATE_TESTS_DIR}/template-quality.bats"
                "${TEMPLATE_TESTS_DIR}/cross-tool-consistency.bats"
                "${TEMPLATE_TESTS_DIR}/template-genericity.bats"
                "${TEMPLATE_TESTS_DIR}/init-script-integration.bats"
            )
            ;;
    esac

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
            bats "${SETUP_TESTS_DIR}/init-ai-configs.bats"
            ;;
        "reinit")
            bats "${SETUP_TESTS_DIR}/reinit-ai-configs.bats"
            ;;
        "copy")
            bats "${SETUP_TESTS_DIR}/copy-template-to-local.bats"
            ;;
        "setup")
            bats "${SETUP_TESTS_DIR}"/*.bats
            ;;
        "templates")
            bats "${TEMPLATE_TESTS_DIR}"/*.bats
            ;;
        "all")
            bats "${SETUP_TESTS_DIR}"/*.bats "${TEMPLATE_TESTS_DIR}"/*.bats
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
  init        init-ai-configs.sh のテストを実行
  reinit      reinit-ai-configs.sh のテストを実行
  copy        copy-template-to-local.sh のテストを実行
  setup       セットアップテストをすべて実行（init + reinit + copy）
  templates   テンプレート品質テストを実行（存在確認・品質・一貫性・汎用性・init統合）
  all         すべてのテストを実行（デフォルト）

Options:
  -h, --help    このヘルプメッセージを表示

Examples:
  # すべてのテストを実行
  bash scripts/test/run-setup-tests.sh

  # セットアップテストのみ実行
  bash scripts/test/run-setup-tests.sh setup

  # テンプレート品質テストのみ実行
  bash scripts/test/run-setup-tests.sh templates

  # 特定のテストのみ実行
  bash scripts/test/run-setup-tests.sh init

Environment Variables:
  PROJECT_ROOT    プロジェクトルートディレクトリ（自動検出）

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
            init|reinit|copy|setup|templates|all)
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
    echo "  Bats Test Runner"
    echo "========================================"
    echo ""

    log_info "プロジェクトルート: ${PROJECT_ROOT}"
    log_info "セットアップテストディレクトリ: ${SETUP_TESTS_DIR}"
    log_info "テンプレートテストディレクトリ: ${TEMPLATE_TESTS_DIR}"
    echo ""

    # 事前チェック
    check_bats_installation
    check_bats_helpers || true  # 警告のみでエラーにはしない
    check_test_files "${test_target}"
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
