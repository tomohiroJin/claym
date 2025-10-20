#!/usr/bin/env bash
# =============================================================================
# 公式テンプレートをローカルテンプレートにコピーするヘルパースクリプト
# =============================================================================
#
# 使い方:
#   ./copy-template-to-local.sh <テンプレート種別> [ファイル名]
#
# 例:
#   ./copy-template-to-local.sh command review.md    # review.md をコピー
#   ./copy-template-to-local.sh command              # すべてのコマンドをコピー
#   ./copy-template-to-local.sh claude-md            # CLAUDE.md をコピー
#   ./copy-template-to-local.sh all                  # すべてをコピー
#
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# 定数定義
# -----------------------------------------------------------------------------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly TEMPLATES_DIR="${PROJECT_ROOT}/templates"
readonly TEMPLATES_LOCAL_DIR="${PROJECT_ROOT}/templates-local"

# -----------------------------------------------------------------------------
# ログ関数
# -----------------------------------------------------------------------------

log_info() {
    echo "ℹ️  $*"
}

log_success() {
    echo "✅ $*"
}

log_error() {
    echo "❌ $*" >&2
}

# -----------------------------------------------------------------------------
# 使い方を表示
# -----------------------------------------------------------------------------

usage() {
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

# -----------------------------------------------------------------------------
# コマンドのコピー
# -----------------------------------------------------------------------------

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
}

# -----------------------------------------------------------------------------
# すべてのコマンドをコピー
# -----------------------------------------------------------------------------

copy_all_commands() {
    log_info "すべてのコマンドをコピー中..."

    local count=0
    for cmd in "${TEMPLATES_DIR}/.claude/commands/"*.md; do
        if [[ -f "${cmd}" ]]; then
            copy_command "$(basename "${cmd}")"
            count=$((count + 1))
        fi
    done

    log_success "${count} 個のコマンドをコピーしました"
}

# -----------------------------------------------------------------------------
# CLAUDE.md のコピー
# -----------------------------------------------------------------------------

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
}

# -----------------------------------------------------------------------------
# settings.local.json.example のコピー
# -----------------------------------------------------------------------------

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
}

# -----------------------------------------------------------------------------
# メイン処理
# -----------------------------------------------------------------------------

main() {
    # 引数チェック
    if [[ $# -eq 0 ]]; then
        usage
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
            log_info "すべてのテンプレートをコピー中..."
            copy_all_commands
            copy_claude_md
            copy_settings
            log_success "すべてのテンプレートをコピーしました"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "不明なテンプレート種別: ${template_type}"
            echo ""
            usage
            exit 1
            ;;
    esac

    # 次のステップを案内
    echo ""
    log_info "次のステップ:"
    echo "  1. ローカルテンプレートを編集:"
    echo "     vim templates-local/.claude/commands/<ファイル名>"
    echo ""
    echo "  2. 設定を再生成:"
    echo "     bash scripts/setup/reinit-ai-configs.sh"
}

# スクリプト実行
main "$@"
