#!/usr/bin/env bash
# =============================================================================
# サブプロジェクトに AI 設定をシンボリックリンクするスクリプト
# =============================================================================
#
# 使用例:
#   bash scripts/setup/link-ai-configs.sh path/to/project1 path/to/project2
#
# 目的:
#   Git ルートが分かれたサブプロジェクトでも、
#   親プロジェクトの AI 設定（Claude/Codex/Gemini）を共有します。
#
# 共有対象:
#   - .claude/
#   - .codex/
#   - .gemini/
#   - AGENTS.md
#
# 備考:
#   既に同名のファイル/ディレクトリがある場合はスキップし、警告を出します。
#
# =============================================================================

set -euo pipefail

# =============================================================================
# 共通ヘルパーの読み込み
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# 定数と設定
# =============================================================================

readonly PROJECT_ROOT="$(get_project_root "${SCRIPT_DIR}")"
readonly DEFAULT_SOURCE_ROOT="${PROJECT_ROOT}"

# テストやカスタム運用用にソースルートを上書きできるようにする
SOURCE_ROOT="${AI_CONFIGS_SOURCE_ROOT:-${DEFAULT_SOURCE_ROOT}}"

# =============================================================================
# ヘルパー関数
# =============================================================================

show_usage() {
    cat << 'EOF'
Usage: bash scripts/setup/link-ai-configs.sh <project_path...>

指定したプロジェクトルートに AI 設定のシンボリックリンクを作成します。

対象:
  - .claude/
  - .codex/
  - .gemini/
  - AGENTS.md

Options:
  -h, --help    このヘルプを表示

Environment:
  AI_CONFIGS_SOURCE_ROOT    リンク元ルート（デフォルト: プロジェクトルート）

Examples:
  bash scripts/setup/link-ai-configs.sh local/project-a local/project-b
EOF
}

resolve_absolute_path() {
    local input="$1"
    if [[ -d "${input}" ]]; then
        (cd "${input}" && pwd)
    else
        echo "${input}"
    fi
}

link_item() {
    local target_root="$1"
    local rel_path="$2"

    local source_path="${SOURCE_ROOT}/${rel_path}"
    local target_path="${target_root}/${rel_path}"

    if [[ -e "${target_path}" || -L "${target_path}" ]]; then
        log_warn "既に存在するためスキップしました: ${target_path}"
        return 0
    fi

    if [[ ! -e "${source_path}" ]]; then
        log_warn "リンク元が存在しないためスキップしました: ${source_path}"
        return 0
    fi

    ln -s "${source_path}" "${target_path}"
    log_success "リンクを作成しました: ${target_path}"
}

link_ai_configs() {
    local target_root="$1"

    if [[ ! -d "${target_root}" ]]; then
        log_error "指定したディレクトリが存在しません: ${target_root}"
        return 1
    fi

    if [[ "${target_root}" == "${SOURCE_ROOT}" ]]; then
        log_info "ソースルートと同一のためスキップします: ${target_root}"
        return 0
    fi

    link_item "${target_root}" ".claude"
    link_item "${target_root}" ".codex"
    link_item "${target_root}" ".gemini"
    link_item "${target_root}" "AGENTS.md"
}

# =============================================================================
# メイン処理
# =============================================================================

main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    local target_paths=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                target_paths+=("$1")
                shift
                ;;
        esac
    done

    SOURCE_ROOT="$(resolve_absolute_path "${SOURCE_ROOT}")"

    log_info "リンク元ルート: ${SOURCE_ROOT}"

    local target
    for target in "${target_paths[@]}"; do
        local target_root
        target_root="$(resolve_absolute_path "${target}")"
        log_step "対象プロジェクト: ${target_root}"
        link_ai_configs "${target_root}"
    done
}

main "$@"
