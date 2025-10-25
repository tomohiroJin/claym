#!/usr/bin/env bash
# =============================================================================
# 公式テンプレートをローカルテンプレートにコピーするヘルパースクリプト
# =============================================================================
#
# 使い方:
#   ./copy-template-to-local.sh <テンプレート種別> [ファイル名]
#
# リファクタリング適用パターン:
# - Extract Function: 共通ロジックを common.sh に抽出
# - Replace Duplication: 繰り返し処理を統一
# - Introduce Explaining Variable: 意図を明確にする変数名
#
# =============================================================================

set -euo pipefail

# =============================================================================
# 共通ヘルパーの読み込み
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# 共通ヘルパー関数を読み込み
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# プロジェクト固有の定数
# =============================================================================

readonly PROJECT_ROOT="$(get_project_root "${SCRIPT_DIR}")"
readonly TEMPLATES_DIR="${PROJECT_ROOT}/templates"
readonly TEMPLATES_LOCAL_DIR="${PROJECT_ROOT}/templates-local"

# =============================================================================
# 使い方を表示
# =============================================================================

show_usage() {
    cat <<EOF
使い方: $0 <テンプレート種別> [ファイル名]

テンプレート種別:
  command     - カスタムコマンド
  claude-md   - CLAUDE.md
  settings    - settings.local.json.example
  all         - すべて

例:
  $0 command review.md    # review.md をローカルにコピー
  $0 command              # すべてのコマンドをコピー
  $0 claude-md            # CLAUDE.md をコピー
  $0 settings             # settings.local.json.example をコピー
  $0 all                  # すべてをコピー

説明:
  このスクリプトは、公式テンプレート（templates/）をローカルテンプレート
  （templates-local/）にコピーします。コピー後、ローカルテンプレートを
  編集することで、公式テンプレートを変更せずにカスタマイズできます。

  reinit-ai-configs.sh 実行時、公式テンプレートがまずコピーされ、
  その後ローカルテンプレートで上書きされます。

注意:
  - templates-local/ は gitignore 対象です
  - 既にファイルが存在する場合は上書きされます
  - バックアップは reinit-ai-configs.sh で自動的に取られます
EOF
}

# =============================================================================
# コマンドのコピー
# =============================================================================

# 単一のコマンドファイルをコピー
#
# 引数:
#   $1: コピー対象のファイル名
#
# 戻り値:
#   0: コピー成功
#   1: ファイルが見つからない
#
copy_command() {
    local file="$1"
    local src="${TEMPLATES_DIR}/.claude/commands/${file}"
    local dst="${TEMPLATES_LOCAL_DIR}/.claude/commands/${file}"

    if [[ ! -f "${src}" ]]; then
        log_error "ファイルが見つかりません: ${src}"
        return 1
    fi

    mkdir -p "$(dirname "${dst}")"
    cp "${src}" "${dst}"
    log_success "${file} をコピーしました: ${dst}"
    return 0
}

# すべてのコマンドファイルをコピー
#
# 戻り値:
#   0: コピー成功
#
copy_all_commands() {
    log_info "すべてのコマンドをコピー中..."

    local count=0
    local src_dir="${TEMPLATES_DIR}/.claude/commands"

    if [[ ! -d "${src_dir}" ]]; then
        log_error "コマンドディレクトリが見つかりません: ${src_dir}"
        return 1
    fi

    for cmd in "${src_dir}/"*.md; do
        if [[ -f "${cmd}" ]]; then
            copy_command "$(basename "${cmd}")"
            count=$((count + 1))
        fi
    done

    log_success "${count} 個のコマンドをコピーしました"
    return 0
}

# =============================================================================
# CLAUDE.md のコピー
# =============================================================================

# CLAUDE.md をローカルテンプレートにコピー
#
# 戻り値:
#   0: コピー成功
#   1: ファイルが見つからない
#
copy_claude_md() {
    local src="${TEMPLATES_DIR}/.claude/CLAUDE.md"
    local dst="${TEMPLATES_LOCAL_DIR}/.claude/CLAUDE.md"

    if [[ ! -f "${src}" ]]; then
        log_error "ファイルが見つかりません: ${src}"
        return 1
    fi

    mkdir -p "$(dirname "${dst}")"
    cp "${src}" "${dst}"
    log_success "CLAUDE.md をコピーしました: ${dst}"
    return 0
}

# =============================================================================
# settings.local.json.example のコピー
# =============================================================================

# settings.local.json.example をローカルテンプレートにコピー
#
# 戻り値:
#   0: コピー成功
#   1: ファイルが見つからない
#
copy_settings() {
    local src="${TEMPLATES_DIR}/.claude/settings.local.json.example"
    local dst="${TEMPLATES_LOCAL_DIR}/.claude/settings.local.json.example"

    if [[ ! -f "${src}" ]]; then
        log_error "ファイルが見つかりません: ${src}"
        return 1
    fi

    mkdir -p "$(dirname "${dst}")"
    cp "${src}" "${dst}"
    log_success "settings.local.json.example をコピーしました: ${dst}"
    return 0
}

# =============================================================================
# すべてのテンプレートをコピー
# =============================================================================

# すべてのテンプレートをローカルテンプレートにコピー
#
# 戻り値:
#   0: コピー成功
#   1: 一部またはすべて失敗
#
copy_all() {
    log_info "すべてのテンプレートをコピー中..."

    local success=0
    local failed=0

    copy_all_commands || ((failed++))
    copy_claude_md || ((failed++))
    copy_settings || ((failed++))

    if [[ ${failed} -eq 0 ]]; then
        log_success "すべてのテンプレートをコピーしました"
        return 0
    else
        log_warn "${failed} 個のテンプレートのコピーに失敗しました"
        return 1
    fi
}

# =============================================================================
# 次のステップ案内
# =============================================================================

# ユーザーに次のステップを案内
#
show_next_steps() {
    echo ""
    log_info "次のステップ:"
    echo "  1. ローカルテンプレートを編集:"
    echo "     vim templates-local/.claude/commands/<ファイル名>"
    echo ""
    echo "  2. 設定を再生成:"
    echo "     bash scripts/setup/reinit-ai-configs.sh"
}

# =============================================================================
# メイン処理
# =============================================================================

# メイン処理
#
# 引数:
#   $@: コマンドライン引数
#
main() {
    # 引数チェック
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    local template_type="$1"
    local file_name="${2:-}"

    case "${template_type}" in
        command)
            if [[ -n "${file_name}" ]]; then
                copy_command "${file_name}"
            else
                copy_all_commands
            fi
            ;;
        claude-md)
            copy_claude_md
            ;;
        settings)
            copy_settings
            ;;
        all)
            copy_all
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            log_error "不明なテンプレート種別: ${template_type}"
            echo ""
            show_usage
            exit 1
            ;;
    esac

    # 次のステップを案内
    show_next_steps
}

# スクリプト実行
main "$@"
