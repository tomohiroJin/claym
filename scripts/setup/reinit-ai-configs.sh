#!/usr/bin/env bash
# =============================================================================
# AI拡張機能の設定ファイルを再生成するスクリプト
# =============================================================================
#
# バックアップ機能付きで安全に設定を更新できます。
#
# 使い方:
#   bash scripts/setup/reinit-ai-configs.sh           # 対話モード
#   bash scripts/setup/reinit-ai-configs.sh -y        # 自動実行
#   bash scripts/setup/reinit-ai-configs.sh --backup-only   # バックアップのみ
#   bash scripts/setup/reinit-ai-configs.sh --restore 20251019_153000  # 復元
#
# リファクタリング適用パターン:
# - Extract Function: 共通ログ関数を common.sh に抽出
# - Replace Magic Number/String: 定数化
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
# 定数・グローバル変数
# =============================================================================

# プロジェクトルート
readonly PROJECT_ROOT="$(get_project_root "${SCRIPT_DIR}")"
readonly TEMPLATES_DIR="${PROJECT_ROOT}/templates"

# バックアップディレクトリ
readonly BACKUP_ROOT="${HOME}/.config/claym-backups"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"

# フラグ
AUTO_YES=false
BACKUP_ONLY=false
RESTORE_MODE=false
RESTORE_TIMESTAMP=""
DRY_RUN=false
VERBOSE=false

# ログ関数は common.sh で定義されています

# =============================================================================
# ヘルプ表示
# =============================================================================

show_help() {
    cat <<EOF
AI拡張機能 設定再生成スクリプト

使い方:
  $(basename "$0") [OPTIONS]

オプション:
  -y, --yes              確認プロンプトをスキップ（自動実行）
  --backup-only          バックアップのみ実行（再生成しない）
  --restore TIMESTAMP    指定したバックアップから復元
  --list-backups         利用可能なバックアップ一覧を表示
  --dry-run             実際には変更せず、実行内容を表示
  -v, --verbose         詳細ログを出力
  -h, --help            このヘルプを表示

バックアップ対象:
  - .claude/settings.local.json
  - .claude/CLAUDE.md
  - ~/.codex/config.toml
  - .codex/prompts/
  - ~/.codex/prompts/
  - AGENTS.md（プロジェクトルート、チーム共有）
  - ~/.codex/AGENTS.md（個人設定、優先度高）
  - .gemini/settings.json
  - .gemini/GEMINI.md

使用例:
  # 対話モードで再生成
  $(basename "$0")

  # 自動実行（確認なし）
  $(basename "$0") -y

  # バックアップのみ
  $(basename "$0") --backup-only

  # バックアップから復元
  $(basename "$0") --restore 20251019_153000

  # バックアップ一覧を表示
  $(basename "$0") --list-backups

詳細は docs/scripts-setup-tools.md を参照してください。
EOF
}

# =============================================================================
# バックアップ一覧表示
# =============================================================================

list_backups() {
    log_step "利用可能なバックアップ一覧"

    if [[ ! -d "${BACKUP_ROOT}" ]]; then
        log_warn "バックアップディレクトリが存在しません: ${BACKUP_ROOT}"
        return 0
    fi

    local backups=()
    while IFS= read -r -d '' backup; do
        backups+=("$(basename "$backup")")
    done < <(find "${BACKUP_ROOT}" -maxdepth 1 -type d -name "????????_??????" -print0 | sort -rz)

    if [[ ${#backups[@]} -eq 0 ]]; then
        log_warn "バックアップが見つかりません"
        return 0
    fi

    echo ""
    printf "%-20s %-15s %s\n" "タイムスタンプ" "ファイル数" "パス"
    printf "%-20s %-15s %s\n" "-------------------" "--------------" "----"

    for backup in "${backups[@]}"; do
        local backup_path="${BACKUP_ROOT}/${backup}"
        local file_count=$(find "${backup_path}" -type f | wc -l)
        printf "%-20s %-15s %s\n" "${backup}" "${file_count}" "${backup_path}"
    done
    echo ""
}

# =============================================================================
# バックアップ作成
# =============================================================================

create_backup() {
    log_step "設定ファイルのバックアップを作成中..."

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] バックアップディレクトリ: ${BACKUP_DIR}"
    else
        mkdir -p "${BACKUP_DIR}"
        log_info "バックアップディレクトリ: ${BACKUP_DIR}"
    fi

    local backed_up_count=0
    local manifest="${BACKUP_DIR}/backup-manifest.txt"

    # バックアップ対象のファイルリスト
    local -a backup_targets=(
        "${PROJECT_ROOT}/.claude/settings.local.json"
        "${PROJECT_ROOT}/.claude/CLAUDE.md"
        "${HOME}/.codex/config.toml"
        "${PROJECT_ROOT}/AGENTS.md"
        "${HOME}/.codex/AGENTS.md"
        "${PROJECT_ROOT}/.gemini/settings.json"
        "${PROJECT_ROOT}/.gemini/GEMINI.md"
    )

    # バックアップ対象のディレクトリリスト
    local -a backup_dir_targets=(
        "${PROJECT_ROOT}/.claude/commands"
        "${PROJECT_ROOT}/.claude/agents"
        "${PROJECT_ROOT}/.codex/prompts"
        "${PROJECT_ROOT}/templates-local"
        "${HOME}/.codex/prompts"
    )

    if [[ "${DRY_RUN}" != "true" ]]; then
        {
            echo "# AI拡張機能 設定バックアップ"
            echo "# 作成日時: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "# プロジェクト: ${PROJECT_ROOT}"
            echo ""
        } > "${manifest}"
    fi

    for file in "${backup_targets[@]}"; do
        if [[ -f "${file}" ]]; then
            local rel_path="${file#${PROJECT_ROOT}/}"
            rel_path="${rel_path#${HOME}/}"
            local backup_path="${BACKUP_DIR}/${rel_path}"
            local backup_subdir="$(dirname "${backup_path}")"

            log_debug "バックアップ中: ${file} -> ${backup_path}"

            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "[DRY-RUN] ${rel_path}"
            else
                mkdir -p "${backup_subdir}"
                cp "${file}" "${backup_path}"
                echo "${rel_path}" >> "${manifest}"
                backed_up_count=$((backed_up_count + 1))
            fi
        else
            log_debug "スキップ（ファイルが存在しない）: ${file}"
        fi
    done

    # ディレクトリのバックアップ
    for dir in "${backup_dir_targets[@]}"; do
        if [[ -d "${dir}" ]]; then
            local rel_path="${dir#${PROJECT_ROOT}/}"
            rel_path="${rel_path#${HOME}/}"
            local backup_path="${BACKUP_DIR}/${rel_path}"

            log_debug "ディレクトリをバックアップ中: ${dir} -> ${backup_path}"

            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "[DRY-RUN] ${rel_path}/ (ディレクトリ)"
            else
                mkdir -p "$(dirname "${backup_path}")"
                cp -r "${dir}" "${backup_path}"
                echo "${rel_path}/" >> "${manifest}"
                backed_up_count=$((backed_up_count + 1))
            fi
        else
            log_debug "スキップ（ディレクトリが存在しない）: ${dir}"
        fi
    done

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] ${backed_up_count} 個の項目をバックアップします"
    else
        log_success "${backed_up_count} 個の項目をバックアップしました"
        log_info "バックアップ場所: ${BACKUP_DIR}"
    fi
}

# =============================================================================
# バックアップから復元
# =============================================================================

restore_backup() {
    local restore_from="$1"
    local restore_path="${BACKUP_ROOT}/${restore_from}"

    log_step "バックアップから復元中..."

    if [[ ! -d "${restore_path}" ]]; then
        log_error "バックアップが見つかりません: ${restore_path}"
        exit 1
    fi

    local manifest="${restore_path}/backup-manifest.txt"
    if [[ ! -f "${manifest}" ]]; then
        log_error "マニフェストファイルが見つかりません: ${manifest}"
        exit 1
    fi

    # 現在の設定をバックアップ（復元前の保護）
    if [[ "${DRY_RUN}" != "true" ]]; then
        log_info "復元前に現在の設定をバックアップします..."
        create_backup
    fi

    log_info "復元元: ${restore_path}"

    local restored_count=0
    while IFS= read -r rel_path; do
        # コメント行と空行をスキップ
        [[ "${rel_path}" =~ ^#.*$ || -z "${rel_path}" ]] && continue

        # ディレクトリかファイルかを判定（末尾の / で判断）
        if [[ "${rel_path}" == */ ]]; then
            # ディレクトリの復元
            local rel_path_clean="${rel_path%/}"  # 末尾の / を削除
            local backup_dir="${restore_path}/${rel_path_clean}"
            local target_dir=""

            # パスの復元先を決定
            if [[ "${rel_path_clean}" == .codex/* ]]; then
                target_dir="${HOME}/${rel_path_clean}"
            else
                target_dir="${PROJECT_ROOT}/${rel_path_clean}"
            fi

            if [[ -d "${backup_dir}" ]]; then
                log_debug "ディレクトリを復元中: ${rel_path_clean} -> ${target_dir}"

                if [[ "${DRY_RUN}" == "true" ]]; then
                    log_info "[DRY-RUN] ${rel_path_clean}/ (ディレクトリ)"
                else
                    # 既存ディレクトリがあれば削除
                    [[ -d "${target_dir}" ]] && rm -rf "${target_dir}"
                    mkdir -p "$(dirname "${target_dir}")"
                    cp -r "${backup_dir}" "${target_dir}"
                    restored_count=$((restored_count + 1))
                fi
            else
                log_warn "バックアップディレクトリが見つかりません: ${backup_dir}"
            fi
        else
            # ファイルの復元
            local backup_file="${restore_path}/${rel_path}"
            local target_file=""

            # パスの復元先を決定
            if [[ "${rel_path}" == .codex/* ]]; then
                target_file="${HOME}/${rel_path}"
            else
                target_file="${PROJECT_ROOT}/${rel_path}"
            fi

            if [[ -f "${backup_file}" ]]; then
                local target_dir
                target_dir="$(dirname "${target_file}")"

                log_debug "復元中: ${rel_path} -> ${target_file}"

                if [[ "${DRY_RUN}" == "true" ]]; then
                    log_info "[DRY-RUN] ${rel_path}"
                else
                    mkdir -p "${target_dir}"
                    cp "${backup_file}" "${target_file}"
                    restored_count=$((restored_count + 1))
                fi
            else
                log_warn "バックアップファイルが見つかりません: ${backup_file}"
            fi
        fi
    done < "${manifest}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] ${restored_count} 個の項目を復元します"
    else
        log_success "${restored_count} 個の項目を復元しました"
    fi
}

# =============================================================================
# 設定の再生成
# =============================================================================

regenerate_configs() {
    log_step "設定ファイルを再生成中..."

    # 既存ファイルを削除
    local -a config_files=(
        "${PROJECT_ROOT}/.claude/settings.local.json"
        "${PROJECT_ROOT}/.claude/CLAUDE.md"
        "${HOME}/.codex/config.toml"
        "${PROJECT_ROOT}/AGENTS.md"
        "${HOME}/.codex/AGENTS.md"
        "${PROJECT_ROOT}/.gemini/settings.json"
        "${PROJECT_ROOT}/.gemini/GEMINI.md"
    )

    # 既存ディレクトリを削除
    local -a config_dirs=(
        "${PROJECT_ROOT}/.claude/commands"
        "${PROJECT_ROOT}/.claude/agents"
        "${PROJECT_ROOT}/.codex/prompts"
        "${HOME}/.codex/prompts"
    )

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] 既存設定ファイルを削除します"
        for file in "${config_files[@]}"; do
            [[ -f "${file}" ]] && log_debug "[DRY-RUN] 削除: ${file}"
        done
        for dir in "${config_dirs[@]}"; do
            [[ -d "${dir}" ]] && log_debug "[DRY-RUN] 削除: ${dir}/"
        done
    else
        log_info "既存の設定ファイルを削除中..."
        for file in "${config_files[@]}"; do
            if [[ -f "${file}" ]]; then
                log_debug "削除: ${file}"
                rm -f "${file}"
            fi
        done
        for dir in "${config_dirs[@]}"; do
            if [[ -d "${dir}" ]]; then
                log_debug "削除: ${dir}/"
                rm -rf "${dir}"
            fi
        done
    fi

    # init-ai-configs.sh を実行
    local init_script="${SCRIPT_DIR}/init-ai-configs.sh"

    if [[ ! -f "${init_script}" ]]; then
        log_error "初期化スクリプトが見つかりません: ${init_script}"
        exit 1
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] ${init_script} を実行します"
    else
        log_info "初期化スクリプトを実行中..."
        echo ""
        bash "${init_script}"
        echo ""
        log_success "設定ファイルの再生成が完了しました"
    fi
}

# =============================================================================
# 確認プロンプト
# =============================================================================

confirm() {
    local message="$1"

    if [[ "${AUTO_YES}" == "true" ]]; then
        return 0
    fi

    echo ""
    echo -e "${YELLOW}${message}${NC}"
    read -p "続行しますか？ (y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "キャンセルされました"
        exit 0
    fi
}

# =============================================================================
# メイン処理
# =============================================================================

main() {
    # ヘッダー
    show_header "AI Extensions Configuration Reset"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warn "DRY-RUN モード（実際には変更しません）"
        echo ""
    fi

    # 復元モード
    if [[ "${RESTORE_MODE}" == "true" ]]; then
        confirm "バックアップ ${RESTORE_TIMESTAMP} から設定を復元します。"
        restore_backup "${RESTORE_TIMESTAMP}"
        log_step "復元が完了しました！"
        return 0
    fi

    # バックアップのみモード
    if [[ "${BACKUP_ONLY}" == "true" ]]; then
        create_backup
        log_step "バックアップが完了しました！"
        return 0
    fi

    # 通常モード（バックアップ + 再生成）
    confirm "既存の設定をバックアップしてから、テンプレートから再生成します。"

    # バックアップ作成
    create_backup

    # 再生成
    regenerate_configs

    # 完了メッセージ
    show_footer "$(log_success "すべての処理が完了しました！")"
    log_info "次のステップ:"
    echo "  1. .claude/settings.local.json で権限をカスタマイズ"
    echo "  2. ~/.codex/config.toml でモデルを選択"
    echo "  3. 各AI CLIを再起動して設定を反映"
    echo ""
    log_info "バックアップ: ${BACKUP_DIR}"
    log_info "復元する場合: bash $0 --restore ${TIMESTAMP}"
}

# =============================================================================
# 引数解析
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes)
                AUTO_YES=true
                shift
                ;;
            --backup-only)
                BACKUP_ONLY=true
                shift
                ;;
            --restore)
                RESTORE_MODE=true
                RESTORE_TIMESTAMP="$2"
                shift 2
                ;;
            --list-backups)
                list_backups
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "不明なオプション: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# スクリプト実行
# =============================================================================

parse_args "$@"
main
