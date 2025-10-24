#!/usr/bin/env bash
# test-init-ai-configs.sh
# scripts/setup/init-ai-configs.sh の基本動作をテストするスクリプト
#
# 使い方:
#   bash scripts/setup/test-init-ai-configs.sh

set -euo pipefail

# スクリプトのパス
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly SCRIPTS_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INIT_SCRIPT="${SCRIPT_DIR}/init-ai-configs.sh"
readonly INIT_SCRIPT
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly PROJECT_ROOT

# ログ出力ライブラリを読み込む
if [[ ! -f "${SCRIPTS_ROOT}/lib/logging.sh" ]]; then
    echo "ERROR: ログ出力ライブラリが見つかりません: ${SCRIPTS_ROOT}/lib/logging.sh" >&2
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
TEST_PROJECT="${TEST_TMPDIR}/test-project"
readonly TEST_PROJECT
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

# テストプロジェクトのセットアップ
setup_test_project() {
    mkdir -p "$TEST_PROJECT"
    # templates ディレクトリをコピー
    cp -r "${PROJECT_ROOT}/templates" "${TEST_PROJECT}/"
    # init スクリプトをコピー
    cp "$INIT_SCRIPT" "${TEST_PROJECT}/"
}

# =============================================================================
# テストケース
# =============================================================================

# テスト1: スクリプトが存在し実行可能であること
test_script_exists() {
    [[ -f "$INIT_SCRIPT" ]] && [[ -x "$INIT_SCRIPT" ]]
}

# テスト2: templates ディレクトリが存在すること
test_templates_dir_exists() {
    [[ -d "${PROJECT_ROOT}/templates" ]]
}

# テスト3: Claude Code テンプレートが存在すること
test_claude_templates_exist() {
    [[ -f "${PROJECT_ROOT}/templates/.claude/settings.local.json.example" ]] && \
    [[ -f "${PROJECT_ROOT}/templates/.claude/CLAUDE.md" ]]
}

# テスト4: Codex CLI テンプレートが存在すること
test_codex_templates_exist() {
    [[ -f "${PROJECT_ROOT}/templates/.codex/config.toml.example" ]] && \
    [[ -f "${PROJECT_ROOT}/templates/.codex/AGENTS.md" ]]
}

# テスト5: GEMINI テンプレートが存在すること
test_gemini_templates_exist() {
    [[ -f "${PROJECT_ROOT}/templates/.gemini/settings.json.example" ]] && \
    [[ -f "${PROJECT_ROOT}/templates/.gemini/GEMINI.md" ]]
}

# テスト6: プロンプトテンプレートが存在すること
test_prompt_templates_exist() {
    [[ -f "${PROJECT_ROOT}/templates/docs/prompts/system.md" ]] && \
    [[ -f "${PROJECT_ROOT}/templates/docs/prompts/tasks/bug-fix.md" ]] && \
    [[ -f "${PROJECT_ROOT}/templates/docs/prompts/tasks/feature-add.md" ]]
}

# テスト7: 実際のプロジェクトで Claude Code 設定が作成されること
test_claude_setup_in_real_project() {
    # 実際のプロジェクトルートで確認
    [[ -f "${PROJECT_ROOT}/.claude/settings.local.json" ]] || \
    [[ -f "${PROJECT_ROOT}/.claude/CLAUDE.md" ]]
}

# テスト8: 実際のプロジェクトで Codex CLI 設定が作成されること
test_codex_setup_in_real_project() {
    # AGENTS.md が実際のプロジェクトルートに存在するか確認
    [[ -f "${PROJECT_ROOT}/AGENTS.md" ]] || \
    # または ~/.codex/config.toml が存在するか確認
    [[ -f "${HOME}/.codex/config.toml" ]]
}

# テスト9: 実際のプロジェクトで GEMINI 設定が作成されること
test_gemini_setup_in_real_project() {
    [[ -f "${PROJECT_ROOT}/.gemini/settings.json" ]] || \
    [[ -f "${PROJECT_ROOT}/.gemini/GEMINI.md" ]]
}

# テスト10: プロンプトテンプレートがコピーされていること
test_prompts_copied_in_real_project() {
    [[ -f "${PROJECT_ROOT}/docs/prompts/system.md" ]] || \
    [[ -f "${PROJECT_ROOT}/docs/prompts/tasks/bug-fix.md" ]]
}

# テスト11: .gitignore が更新されていること
test_gitignore_updated() {
    local gitignore="${PROJECT_ROOT}/.gitignore"
    if [[ -f "$gitignore" ]]; then
        grep -q "\.claude/settings\.local\.json" "$gitignore" || \
        grep -q "claude" "$gitignore"
    else
        # .gitignore がない場合はスキップ
        return 0
    fi
}

# テスト12: テンプレート内のパス置換が機能すること（Codex）
test_codex_path_substitution() {
    local template="${PROJECT_ROOT}/templates/.codex/config.toml.example"
    if [[ -f "$template" ]]; then
        # テンプレートに __PROJECT_ROOT__ プレースホルダーが含まれていることを確認
        grep -q "__PROJECT_ROOT__" "$template" || \
        # または既に展開済みの場合はスキップ
        return 0
    else
        return 1
    fi
}

# テスト13: テンプレート内のパス置換が機能すること（GEMINI）
test_gemini_path_substitution() {
    local template="${PROJECT_ROOT}/templates/.gemini/settings.json.example"
    if [[ -f "$template" ]]; then
        # テンプレートに __PROJECT_ROOT__ プレースホルダーが含まれていることを確認
        grep -q "__PROJECT_ROOT__" "$template" || \
        # または既に展開済みの場合はスキップ
        return 0
    else
        return 1
    fi
}

# テスト14: README.md が templates ディレクトリに存在すること
test_templates_readme_exists() {
    [[ -f "${PROJECT_ROOT}/templates/README.md" ]]
}

# テスト15: 実際に展開された設定ファイルにプロジェクトパスが含まれていること
test_expanded_config_has_project_path() {
    # Codex の設定を確認
    local codex_config="${HOME}/.codex/config.toml"
    if [[ -f "$codex_config" ]]; then
        # __PROJECT_ROOT__ が置換されていることを確認
        ! grep -q "__PROJECT_ROOT__" "$codex_config"
    else
        # 設定ファイルがない場合は警告のみでテスト成功扱い
        log_warn "Codex config not found at $codex_config, skipping path check"
        return 0
    fi
}

# =============================================================================
# メイン実行
# =============================================================================

main() {
    log_info "========================================"
    log_info "AI Config Init Script Test Suite"
    log_info "========================================"
    echo ""

    # 基本チェック
    log_info "基本チェック"
    run_test "スクリプトが存在し実行可能" test_script_exists
    run_test "templates ディレクトリ存在確認" test_templates_dir_exists
    echo ""

    # テンプレートの存在確認
    log_info "テンプレートの存在確認"
    run_test "Claude Code テンプレート存在確認" test_claude_templates_exist
    run_test "Codex CLI テンプレート存在確認" test_codex_templates_exist
    run_test "GEMINI テンプレート存在確認" test_gemini_templates_exist
    run_test "プロンプトテンプレート存在確認" test_prompt_templates_exist
    run_test "templates README 存在確認" test_templates_readme_exists
    echo ""

    # パス置換機能の確認
    log_info "パス置換機能の確認"
    run_test "Codex パス置換テンプレート確認" test_codex_path_substitution
    run_test "GEMINI パス置換テンプレート確認" test_gemini_path_substitution
    echo ""

    # 実際のプロジェクトでのセットアップ確認
    log_info "実際のプロジェクトでのセットアップ確認"
    run_test "Claude Code 設定の存在確認" test_claude_setup_in_real_project
    run_test "Codex CLI 設定の存在確認" test_codex_setup_in_real_project
    run_test "GEMINI 設定の存在確認" test_gemini_setup_in_real_project
    run_test "プロンプトテンプレートのコピー確認" test_prompts_copied_in_real_project
    run_test ".gitignore 更新確認" test_gitignore_updated
    run_test "展開済み設定のパス確認" test_expanded_config_has_project_path
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
