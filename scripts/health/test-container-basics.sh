#!/usr/bin/env bash
# test-container-basics.sh
# コンテナの基本機能（新規追加されたCLIツール等）をテストするスクリプト
#
# 使い方:
#   bash scripts/health/test-container-basics.sh

set -euo pipefail

# スクリプトのパス
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly SCRIPTS_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

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

# ベーシックエディタ・ページャ
test_vim_installed() {
    command -v vim >/dev/null 2>&1
}

test_less_installed() {
    command -v less >/dev/null 2>&1
}

test_nano_installed() {
    command -v nano >/dev/null 2>&1
}

# ベーシックシステムユーティリティ
test_bash_completion_installed() {
    [[ -f /usr/share/bash-completion/bash_completion ]]
}

test_file_installed() {
    command -v file >/dev/null 2>&1
}

test_man_installed() {
    command -v man >/dev/null 2>&1
}

test_net_tools_installed() {
    command -v ifconfig >/dev/null 2>&1 || command -v netstat >/dev/null 2>&1
}

test_ssh_client_installed() {
    command -v ssh >/dev/null 2>&1
}

test_rsync_installed() {
    command -v rsync >/dev/null 2>&1
}

test_zip_installed() {
    command -v zip >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1
}

# モダンCLIツール
test_zoxide_installed() {
    command -v zoxide >/dev/null 2>&1
}

test_eza_installed() {
    command -v eza >/dev/null 2>&1
}

test_tldr_installed() {
    command -v tldr >/dev/null 2>&1
}

test_delta_installed() {
    command -v delta >/dev/null 2>&1
}

test_btop_installed() {
    command -v btop >/dev/null 2>&1
}

test_hyperfine_installed() {
    command -v hyperfine >/dev/null 2>&1
}

test_ripgrep_installed() {
    command -v rg >/dev/null 2>&1
}

test_fd_installed() {
    command -v fd >/dev/null 2>&1
}

# シェル環境
test_zshrc_exists() {
    [[ -f /home/vscode/.zshrc ]]
}

test_zsh_aliases_configured() {
    local zshrc="/home/vscode/.zshrc"
    [[ -f "$zshrc" ]] && \
    grep -q "alias ll=" "$zshrc" && \
    grep -q "alias ls=" "$zshrc" && \
    grep -q "zoxide init" "$zshrc"
}

# Git設定
test_git_delta_pager() {
    local pager
    pager=$(git config --global core.pager 2>/dev/null || true)
    [[ "$pager" == "delta" ]]
}

test_git_delta_navigate() {
    local navigate
    navigate=$(git config --global delta.navigate 2>/dev/null || true)
    [[ "$navigate" == "true" ]]
}

test_git_safe_directory() {
    # safe.directory が設定されていることを確認
    git config --global --get-all safe.directory >/dev/null 2>&1
}

# Python MCP環境
test_mcp_venv_exists() {
    local venv="${VIRTUAL_ENV:-/opt/mcp-venv}"
    [[ -d "$venv" ]] && [[ -x "$venv/bin/python" ]]
}

test_markitdown_mcp_command() {
    command -v markitdown-mcp >/dev/null 2>&1
}

test_imagesorcery_mcp_command() {
    command -v imagesorcery-mcp >/dev/null 2>&1
}

test_mcp_github_command() {
    command -v mcp-github >/dev/null 2>&1
}

# AI CLI ツール
test_claude_cli_installed() {
    command -v claude >/dev/null 2>&1
}

test_codex_cli_installed() {
    command -v codex >/dev/null 2>&1
}

test_gemini_cli_installed() {
    command -v gemini >/dev/null 2>&1
}

# Node.js 環境
test_npx_installed() {
    command -v npx >/dev/null 2>&1
}

test_npm_installed() {
    command -v npm >/dev/null 2>&1
}

# UV (Python パッケージマネージャー)
test_uv_installed() {
    command -v uv >/dev/null 2>&1
}

# =============================================================================
# メイン実行
# =============================================================================

main() {
    log_info "========================================"
    log_info "Container Basics Test Suite"
    log_info "========================================"
    echo ""

    # ベーシックエディタ・ページャ
    log_info "ベーシックエディタ・ページャ"
    run_test "vim インストール確認" test_vim_installed
    run_test "less インストール確認" test_less_installed
    run_test "nano インストール確認" test_nano_installed
    echo ""

    # ベーシックシステムユーティリティ
    log_info "ベーシックシステムユーティリティ"
    run_test "bash-completion インストール確認" test_bash_completion_installed
    run_test "file コマンド確認" test_file_installed
    run_test "man コマンド確認" test_man_installed
    run_test "net-tools 確認" test_net_tools_installed
    run_test "ssh クライアント確認" test_ssh_client_installed
    run_test "rsync 確認" test_rsync_installed
    run_test "zip/unzip 確認" test_zip_installed
    echo ""

    # モダンCLIツール
    log_info "モダンCLIツール"
    run_test "zoxide インストール確認" test_zoxide_installed
    run_test "eza インストール確認" test_eza_installed
    run_test "tldr インストール確認" test_tldr_installed
    run_test "delta インストール確認" test_delta_installed
    run_test "btop インストール確認" test_btop_installed
    run_test "hyperfine インストール確認" test_hyperfine_installed
    run_test "ripgrep インストール確認" test_ripgrep_installed
    run_test "fd インストール確認" test_fd_installed
    echo ""

    # シェル環境
    log_info "シェル環境"
    run_test ".zshrc 存在確認" test_zshrc_exists
    run_test "zsh エイリアス設定確認" test_zsh_aliases_configured
    echo ""

    # Git設定
    log_info "Git設定"
    run_test "Git delta pager 設定" test_git_delta_pager
    run_test "Git delta navigate 設定" test_git_delta_navigate
    run_test "Git safe.directory 設定" test_git_safe_directory
    echo ""

    # Python MCP環境
    log_info "Python MCP環境"
    run_test "MCP仮想環境の存在確認" test_mcp_venv_exists
    run_test "markitdown-mcp コマンド確認" test_markitdown_mcp_command
    run_test "imagesorcery-mcp コマンド確認" test_imagesorcery_mcp_command
    run_test "mcp-github コマンド確認" test_mcp_github_command
    echo ""

    # AI CLI ツール
    log_info "AI CLI ツール"
    run_test "claude CLI インストール確認" test_claude_cli_installed
    run_test "codex CLI インストール確認" test_codex_cli_installed
    run_test "gemini CLI インストール確認" test_gemini_cli_installed
    echo ""

    # その他必須ツール
    log_info "その他必須ツール"
    run_test "npx インストール確認" test_npx_installed
    run_test "npm インストール確認" test_npm_installed
    run_test "uv インストール確認" test_uv_installed
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
