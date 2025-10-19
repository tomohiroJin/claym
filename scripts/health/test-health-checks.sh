#!/usr/bin/env bash
# test-health-checks.sh
# scripts/health/check-environment.sh の基本動作をテストするスクリプト
#
# 使い方:
#   bash scripts/health/test-health-checks.sh

set -euo pipefail

# 色付き出力
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# テスト結果カウンター
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# スクリプトのパス
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CHECK_SCRIPT="${SCRIPT_DIR}/check-environment.sh"

# テスト用一時ディレクトリ
readonly TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

# ログ関数
log_test() {
    echo -e "${BLUE}[TEST]${NC} $*"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

# テスト実行関数
run_test() {
    local test_name="$1"
    shift
    TESTS_RUN=$((TESTS_RUN + 1))
    log_test "Running: $test_name"
    # エラーを捕捉するために一時的に set +e
    set +e
    "$@"
    local result=$?
    set -e

    if [[ $result -eq 0 ]]; then
        log_pass "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_fail "$test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 0  # テスト失敗でもスクリプトは続行
    fi
}

# =============================================================================
# テストケース
# =============================================================================

# テスト1: スクリプトが存在し実行可能であること
test_script_exists() {
    [[ -f "$CHECK_SCRIPT" ]] && [[ -x "$CHECK_SCRIPT" ]]
}

# テスト2: --help オプションが動作すること
test_help_option() {
    "$CHECK_SCRIPT" --help >/dev/null 2>&1
}

# テスト3: --list-checks オプションが動作すること
test_list_checks_option() {
    local output
    output=$("$CHECK_SCRIPT" --list-checks 2>&1)
    # チェックIDが含まれていることを確認
    grep -q "system-basics" <<<"$output" && \
    grep -q "cli-paths" <<<"$output"
}

# テスト4: 通常実行が成功すること（終了コード0または2）
test_normal_execution() {
    local exit_code=0
    "$CHECK_SCRIPT" >/dev/null 2>&1 || exit_code=$?
    # 0（全成功）または 2（警告あり）は許容
    [[ $exit_code -eq 0 || $exit_code -eq 2 ]]
}

# テスト5: --json オプションで JSON 形式の出力が得られること
test_json_output() {
    local output
    # 標準エラー出力を破棄し、標準出力のみをキャプチャ
    output=$("$CHECK_SCRIPT" --json 2>/dev/null || true)
    # JSON として解釈可能か確認（jq がある場合）
    if command -v jq >/dev/null 2>&1; then
        echo "$output" | jq empty 2>/dev/null
    else
        # jq がない場合は、最低限 JSON っぽい形式をチェック
        grep -q '"checks"' <<<"$output"
    fi
}

# テスト6: --quick オプションが動作すること
test_quick_option() {
    "$CHECK_SCRIPT" --quick >/dev/null 2>&1 || [[ $? -eq 2 ]]
}

# テスト7: 主要チェック項目が実行されること（system-basics）
test_system_basics_check() {
    local output
    output=$("$CHECK_SCRIPT" 2>&1 || true)
    # "System basics" または "Debian" が出力に含まれることを確認
    grep -qi "system.basics\|debian" <<<"$output"
}

# テスト8: CLI 可用性チェックが実行されること
test_cli_paths_check() {
    local output
    output=$("$CHECK_SCRIPT" 2>&1 || true)
    # CLI関連のキーワードが含まれることを確認
    grep -qi "cli" <<<"$output"
}

# テスト9: モダン CLI ツールチェックが実行されること
test_modern_cli_check() {
    local output
    output=$("$CHECK_SCRIPT" --list-checks 2>&1)
    # modern-cli-tools チェックが登録されていることを確認
    grep -q "modern-cli-tools" <<<"$output"
}

# テスト10: Python MCP 環境チェックが実行されること
test_mcp_python_env_check() {
    local output
    output=$("$CHECK_SCRIPT" --list-checks 2>&1)
    # mcp-python-env チェックが登録されていることを確認
    grep -q "mcp-python-env" <<<"$output"
}

# テスト11: ワークスペース権限チェックが実行されること
test_workspace_perms_check() {
    local output
    output=$("$CHECK_SCRIPT" --list-checks 2>&1)
    # workspace-perms チェックが登録されていることを確認
    grep -q "workspace-perms" <<<"$output"
}

# テスト12: 既知のチェックをスキップできること
test_skip_option() {
    local output exit_code=0
    output=$("$CHECK_SCRIPT" --skip system-basics 2>&1 || true)
    # system-basics がスキップされていることを確認（実行されていないこと）
    if grep -qi "skipped" <<<"$output"; then
        return 0
    else
        # スキップ表示がない場合でも、実行されていなければOK
        ! grep -qi "system.basics.*\(PASS\|FAIL\)" <<<"$output"
    fi
}

# テスト13: MCP 登録チェックが存在すること
test_mcp_registrations_check() {
    local output
    output=$("$CHECK_SCRIPT" --list-checks 2>&1)
    grep -q "mcp-registrations" <<<"$output"
}

# テスト14: Git delta 設定チェックが存在すること
test_git_delta_check() {
    local output
    output=$("$CHECK_SCRIPT" --list-checks 2>&1)
    grep -q "git-delta-config" <<<"$output"
}

# テスト15: シェルエイリアス設定チェックが存在すること
test_shell_aliases_check() {
    local output
    output=$("$CHECK_SCRIPT" --list-checks 2>&1)
    grep -q "shell-aliases" <<<"$output"
}

# =============================================================================
# メイン実行
# =============================================================================

main() {
    log_info "========================================"
    log_info "Health Check Script Test Suite"
    log_info "========================================"
    echo ""

    # 基本動作テスト
    log_info "基本動作テスト"
    run_test "スクリプトが存在し実行可能" test_script_exists
    run_test "--help オプション" test_help_option
    run_test "--list-checks オプション" test_list_checks_option
    run_test "通常実行" test_normal_execution
    run_test "--json オプション" test_json_output
    run_test "--quick オプション" test_quick_option
    run_test "--skip オプション" test_skip_option
    echo ""

    # チェック項目の存在確認
    log_info "チェック項目の存在確認"
    run_test "system-basics チェック" test_system_basics_check
    run_test "cli-paths チェック" test_cli_paths_check
    run_test "modern-cli-tools チェック" test_modern_cli_check
    run_test "mcp-python-env チェック" test_mcp_python_env_check
    run_test "workspace-perms チェック" test_workspace_perms_check
    run_test "mcp-registrations チェック" test_mcp_registrations_check
    run_test "git-delta-config チェック" test_git_delta_check
    run_test "shell-aliases チェック" test_shell_aliases_check
    echo ""

    # サマリ表示
    log_info "========================================"
    log_info "テスト結果サマリ"
    log_info "========================================"
    echo -e "実行: ${TESTS_RUN}"
    echo -e "${GREEN}成功: ${TESTS_PASSED}${NC}"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}失敗: ${TESTS_FAILED}${NC}"
    else
        echo -e "失敗: ${TESTS_FAILED}"
    fi
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_info "すべてのテストが成功しました！"
        return 0
    else
        log_info "一部のテストが失敗しました。"
        return 1
    fi
}

# スクリプトが直接実行された場合のみ main を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
