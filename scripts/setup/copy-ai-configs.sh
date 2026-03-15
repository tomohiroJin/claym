#!/usr/bin/env bash
# =============================================================================
# サブプロジェクトに AI 設定をコピーするスクリプト
# =============================================================================
#
# 使用例:
#   bash scripts/setup/copy-ai-configs.sh path/to/project1 path/to/project2
#   bash scripts/setup/copy-ai-configs.sh --force path/to/project1
#   bash scripts/setup/copy-ai-configs.sh --dry-run path/to/project1
#
# 目的:
#   Git ルートが分かれたサブプロジェクトに、
#   親プロジェクトの AI 設定（Claude/Codex/Gemini）をコピーで配布します。
#   シンボリックリンク方式（link-ai-configs.sh）で設定を読み込めない場合の代替手段です。
#
# コピー対象:
#   - .claude/（.claude/settings.local.json を除く）
#   - .codex/
#   - .gemini/
#   - AGENTS.md
#   - .mcp.json（settings.local.json から自動生成）
#
# 除外:
#   - .claude/settings.local.json（ローカル専用の許可ルールを含むため）
#
# 備考:
#   既に同名のファイル/ディレクトリがある場合はスキップし、警告を出します。
#   --force を指定すると既存を上書きします。
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

# コピー対象のアイテム一覧
readonly -a AI_CONFIG_ITEMS=(".claude" ".codex" ".gemini" "AGENTS.md")

# .claude ディレクトリからコピー除外するファイル（相対パス）
readonly -a CLAUDE_EXCLUSIONS=("settings.local.json")

# .mcp.json の生成元となる設定ファイル（相対パス）
readonly MCP_SOURCE_FILE=".claude/settings.local.json"

# フラグ
FORCE=false
DRY_RUN=false

# カウンター
COPY_COUNT=0
SKIP_COUNT=0

# =============================================================================
# ヘルパー関数
# =============================================================================

show_usage() {
    cat << 'EOF'
Usage: bash scripts/setup/copy-ai-configs.sh [--force] [--dry-run] <project_path...>

指定したプロジェクトルートに AI 設定をコピーします。

対象:
  - .claude/（settings.local.json を除く）
  - .codex/
  - .gemini/
  - AGENTS.md
  - .mcp.json（settings.local.json から自動生成）

Options:
  --force       既存があっても上書きする（デフォルトはスキップ＆警告）
  --dry-run     実際にはコピーせずログのみ表示
  -h, --help    このヘルプを表示

Environment:
  AI_CONFIGS_SOURCE_ROOT    コピー元ルート（デフォルト: プロジェクトルート）

Examples:
  # ドライランで確認
  bash scripts/setup/copy-ai-configs.sh --dry-run local/project-a

  # 複数プロジェクトにコピー
  bash scripts/setup/copy-ai-configs.sh local/project-a local/project-b

  # 既存を上書き
  bash scripts/setup/copy-ai-configs.sh --force local/project-a
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

# 除外ファイルを考慮してディレクトリをコピー
#
# 引数:
#   $1: コピー元ディレクトリパス
#   $2: コピー先ディレクトリパス
#   $3: 除外パターン配列名（nameref）
#
copy_directory_with_exclusions() {
    local source_dir="$1"
    local target_dir="$2"
    local -n exclusions_ref="$3"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] ディレクトリをコピー: ${source_dir} -> ${target_dir}"
        if [[ ${#exclusions_ref[@]} -gt 0 ]]; then
            log_info "[DRY-RUN] 除外: ${exclusions_ref[*]}"
        fi
        return 0
    fi

    mkdir -p "${target_dir}"

    # rsync が使える場合は rsync を使用、なければ cp + rm で対応
    if command -v rsync &>/dev/null; then
        local rsync_excludes=()
        for pattern in "${exclusions_ref[@]}"; do
            rsync_excludes+=("--exclude=${pattern}")
        done
        rsync -a "${rsync_excludes[@]}" "${source_dir}/" "${target_dir}/"
    else
        # rsync がない場合: まず全コピーしてから除外ファイルを削除
        shopt -s dotglob
        cp -r "${source_dir}/"* "${target_dir}/" 2>/dev/null || true
        shopt -u dotglob
        for pattern in "${exclusions_ref[@]}"; do
            local exclude_path="${target_dir}/${pattern}"
            if [[ -e "${exclude_path}" ]]; then
                rm -f "${exclude_path}"
                log_debug "除外ファイルを削除: ${exclude_path}"
            fi
        done
    fi
}

# 個別アイテムのコピー
#
# 引数:
#   $1: コピー先ルートディレクトリ
#   $2: アイテムの相対パス（例: .claude, AGENTS.md）
#
copy_item() {
    local target_root="$1"
    local rel_path="$2"

    local source_path="${SOURCE_ROOT}/${rel_path}"
    local target_path="${target_root}/${rel_path}"

    # コピー元が存在しない場合はスキップ
    if [[ ! -e "${source_path}" ]]; then
        log_warn "コピー元が存在しないためスキップしました: ${source_path}"
        return 0
    fi

    # 既存チェック（--force でない場合）
    if [[ -e "${target_path}" || -L "${target_path}" ]]; then
        if [[ "${FORCE}" == "true" ]]; then
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "[DRY-RUN] 上書き: ${target_path}"
            else
                # 既存のシンボリックリンクまたはファイル/ディレクトリを削除
                rm -rf "${target_path}"
                log_debug "既存を削除しました: ${target_path}"
            fi
        else
            log_warn "既に存在するためスキップしました: ${target_path}"
            SKIP_COUNT=$((SKIP_COUNT + 1))
            return 0
        fi
    fi

    # ディレクトリかファイルかで処理を分岐
    if [[ -d "${source_path}" ]]; then
        # .claude ディレクトリは除外ファイルを考慮
        if [[ "${rel_path}" == ".claude" ]]; then
            copy_directory_with_exclusions "${source_path}" "${target_path}" CLAUDE_EXCLUSIONS
        else
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "[DRY-RUN] ディレクトリをコピー: ${target_path}"
            else
                mkdir -p "$(dirname "${target_path}")"
                cp -r "${source_path}" "${target_path}"
            fi
        fi
    else
        if [[ "${DRY_RUN}" == "true" ]]; then
            log_info "[DRY-RUN] ファイルをコピー: ${target_path}"
        else
            mkdir -p "$(dirname "${target_path}")"
            cp "${source_path}" "${target_path}"
        fi
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_success "[DRY-RUN] コピー対象: ${target_path}"
    else
        log_success "コピーしました: ${target_path}"
    fi
    COPY_COUNT=$((COPY_COUNT + 1))
}

# .mcp.json を生成してコピー先に配置
#
# ソースの .claude/settings.local.json から mcpServers を抽出し、
# ${workspaceFolder} をターゲットの絶対パスに置換して .mcp.json を生成する。
#
# 引数:
#   $1: コピー先ルートディレクトリ（絶対パス）
#
generate_mcp_json() {
    local target_root="$1"
    local source_file="${SOURCE_ROOT}/${MCP_SOURCE_FILE}"
    local target_file="${target_root}/.mcp.json"

    # 生成元が存在しない場合はスキップ
    if [[ ! -f "${source_file}" ]]; then
        log_debug ".mcp.json の生成元が見つかりません: ${source_file}"
        return 0
    fi

    # jq が必要
    if ! command -v jq &>/dev/null; then
        log_warn "jq が見つからないため .mcp.json の生成をスキップします"
        return 0
    fi

    # 既存チェック（--force でない場合）
    if [[ -e "${target_file}" ]]; then
        if [[ "${FORCE}" == "true" ]]; then
            if [[ "${DRY_RUN}" != "true" ]]; then
                rm -f "${target_file}"
                log_debug "既存を削除しました: ${target_file}"
            fi
        else
            log_warn "既に存在するためスキップしました: ${target_file}"
            SKIP_COUNT=$((SKIP_COUNT + 1))
            return 0
        fi
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_success "[DRY-RUN] コピー対象: ${target_file}"
        COPY_COUNT=$((COPY_COUNT + 1))
        return 0
    fi

    # mcpServers を抽出し、${workspaceFolder} を置換、各サーバーに env:{} を追加
    jq --arg target "${target_root}" \
        '{ mcpServers: (.mcpServers | to_entries | map(
            .value.args = [.value.args[] | gsub("\\$\\{workspaceFolder\\}"; $target)]
            | .value.env = (.value.env // {})
        ) | from_entries) }' \
        "${source_file}" > "${target_file}"

    log_success ".mcp.json を生成しました: ${target_file}"
    COPY_COUNT=$((COPY_COUNT + 1))
}

# 4アイテムをループしてコピー
#
# 引数:
#   $1: コピー先ルートディレクトリ
#
copy_ai_configs() {
    local target_root="$1"

    if [[ ! -d "${target_root}" ]]; then
        log_error "指定したディレクトリが存在しません: ${target_root}"
        return 1
    fi

    if [[ "${target_root}" == "${SOURCE_ROOT}" ]]; then
        log_info "ソースルートと同一のためスキップします: ${target_root}"
        return 0
    fi

    for item in "${AI_CONFIG_ITEMS[@]}"; do
        copy_item "${target_root}" "${item}"
    done

    # .mcp.json の生成
    generate_mcp_json "${target_root}"
}

# コピー結果サマリの表示
show_copy_summary() {
    echo ""
    log_step "コピー結果サマリ"
    log_info "コピー成功: ${COPY_COUNT} 件"
    if [[ ${SKIP_COUNT} -gt 0 ]]; then
        log_warn "スキップ: ${SKIP_COUNT} 件（既存あり。--force で上書き可能）"
    fi
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warn "※ DRY-RUN モードのため実際のコピーは行われていません"
    fi
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

    # 引数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                FORCE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                log_error "不明なオプション: $1"
                show_usage
                exit 1
                ;;
            *)
                target_paths+=("$1")
                shift
                ;;
        esac
    done

    if [[ ${#target_paths[@]} -eq 0 ]]; then
        log_error "コピー先のプロジェクトパスを指定してください"
        show_usage
        exit 1
    fi

    SOURCE_ROOT="$(resolve_absolute_path "${SOURCE_ROOT}")"

    show_header "AI Config Copy"
    log_info "コピー元ルート: ${SOURCE_ROOT}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warn "DRY-RUN モード（実際には変更しません）"
    fi

    if [[ "${FORCE}" == "true" ]]; then
        log_warn "FORCE モード（既存を上書きします）"
    fi

    local target
    for target in "${target_paths[@]}"; do
        local target_root
        target_root="$(resolve_absolute_path "${target}")"
        log_step "対象プロジェクト: ${target_root}"
        copy_ai_configs "${target_root}"
    done

    show_copy_summary

    show_footer "AI 設定のコピーが完了しました"
}

main "$@"
