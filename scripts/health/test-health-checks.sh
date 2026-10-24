#!/usr/bin/env bash
# test-health-checks.sh
# scripts/health/check-environment.sh の基本動作をテストするスクリプト
#
# 使い方:
#   bash scripts/health/test-health-checks.sh

set -euo pipefail

# スクリプトのパス
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly SCRIPTS_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHECK_SCRIPT="${SCRIPT_DIR}/check-environment.sh"
readonly CHECK_SCRIPT

# ログ出力ライブラリを読み込む
if [[ ! -f "${SCRIPTS_ROOT}/lib/logging.sh" ]]; then
    echo "エラー: ログ出力ライブラリが見つかりません: ${SCRIPTS_ROOT}/lib/logging.sh" >&2
    exit 1
fi

# shellcheck source=../lib/logging.sh
source "${SCRIPTS_ROOT}/lib/logging.sh"

# テスト結果カウンター
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# テスト用一時ディレクトリ
TEST_TMPDIR="$(mktemp -d)"
readonly TEST_TMPDIR
trap 'rm -rf "$TEST_TMPDIR"' EXIT

# テスト固有のログ関数
log_test() {
    echo -e "${BLUE}[TEST]${NC} $*"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
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

# テスト4: 通常実行が成功すること（終了コード0、1、または2）
test_normal_execution() {
    local exit_code=0
    "$CHECK_SCRIPT" >/dev/null 2>&1 || exit_code=$?
    # 0（全成功）、1（エラーあり）、または 2（警告あり）は許容
    [[ $exit_code -eq 0 || $exit_code -eq 1 || $exit_code -eq 2 ]]
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
    local exit_code=0
    "$CHECK_SCRIPT" --quick >/dev/null 2>&1 || exit_code=$?
    # 0（成功）、1（エラー）、または 2（警告）は許容
    [[ $exit_code -eq 0 || $exit_code -eq 1 || $exit_code -eq 2 ]]
}

# テスト7: 主要チェック項目が実行されること（system-basics）
test_system_basics_check() {
    local output
    output=$("$CHECK_SCRIPT" 2>&1 || true)
    # "System basics" または "Ubuntu" が出力に含まれることを確認
    grep -qi "system.basics\|ubuntu" <<<"$output"
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

# テスト16: 脆弱性チェックが登録されていること
test_security_checks_registered() {
    local output
    output=$("$CHECK_SCRIPT" --list-checks 2>&1)
    grep -q "apt-security-updates" <<<"$output" && \
    grep -q "python-vulnerabilities" <<<"$output"
}

# テスト17: 脆弱性チェックが既知の陽性を検出すること
# 「0件」だけでは異常なしと検査が死んでいるを区別できないため、
# 古い ca-certificates を入れた体の dpkg status と、修正前の Pillow を入れた
# 使い捨て venv を渡して、両方が WARN になることを確かめる（要ネットワーク）。
test_security_checks_detect_known_positive() {
    local tmp output
    tmp=$(mktemp -d)
    local installed
    installed=$(dpkg-query -W -f='${Version}' ca-certificates)
    sed "/^Package: ca-certificates$/,/^$/ s/^Version: .*/Version: 20240203/" \
        /var/lib/dpkg/status >"$tmp/status"
    python3 -m venv "$tmp/venv" && \
        "$tmp/venv/bin/pip" install -q --disable-pip-version-check pillow==12.3.0 >/dev/null 2>&1

    # 未適用の更新が多い環境でも ca-certificates が表示から切れないよう上限を外す
    output=$(SECURITY_DPKG_STATUS="$tmp/status" SECURITY_PYTHON_ENVS="$tmp/venv" \
        SECURITY_PREVIEW_LIMIT=100000 "$CHECK_SCRIPT" --no-color 2>&1 || true)
    rm -rf "$tmp"

    # --no-color でも print_status は [WARN] の直後にリセットの制御文字を出すため、間を .* で受ける
    [[ -n "$installed" ]] && \
    grep -q "\[WARN\].*Ubuntu security updates: .*ca-certificates" <<<"$output" && \
    grep -q "\[WARN\].*Python package vulnerabilities: .*pillow 12.3.0" <<<"$output"
}

# テスト18: 脆弱性チェックが検査できないとき PASS にも異常終了にもならないこと
# 依存の壊れた dpkg status（apt のシミュレーションが失敗する）と、空の venv を渡す。
# 以前は前者が PASS、後者が --json を含めて検査全体を終了コード 1 で落としていた。
test_security_checks_fail_safe() {
    local tmp output exit_code=0
    tmp=$(mktemp -d)
    # ca-certificates の依存を、存在しないパッケージに差し替える
    sed "/^Package: ca-certificates$/,/^$/ s/^Depends: .*/Depends: no-such-package-for-health-test/" \
        /var/lib/dpkg/status >"$tmp/status"
    python3 -m venv --without-pip "$tmp/venv"

    # --json は既存の imagesorcery-diagnostics の hint にログの改行が混ざって壊れることがあるため、
    # テキスト出力で判定する（異常終了は出力形式に関係なく終了コード 1 で現れる）
    output=$(SECURITY_DPKG_STATUS="$tmp/status" SECURITY_PYTHON_ENVS="$tmp/venv" \
        "$CHECK_SCRIPT" --no-color 2>&1) || exit_code=$?
    rm -rf "$tmp"

    [[ $exit_code -ne 1 ]] && \
    grep -q "Summary:" <<<"$output" && \
    grep -q "\[WARN\].*Ubuntu security updates: apt upgrade simulation failed" <<<"$output" && \
    grep -q "\[PASS\].*Python package vulnerabilities:" <<<"$output"
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
    run_test "脆弱性チェックの登録" test_security_checks_registered
    run_test "脆弱性チェックが既知の陽性を検出" test_security_checks_detect_known_positive
    run_test "脆弱性チェックが検査不能時に PASS も異常終了もしない" test_security_checks_fail_safe
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
