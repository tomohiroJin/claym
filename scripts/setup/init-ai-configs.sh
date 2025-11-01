#!/usr/bin/env bash
# =============================================================================
# AI拡張機能の設定ファイルを自動セットアップするスクリプト
# =============================================================================
#
# コンテナ起動時に実行され、各AIツールが利用可能な状態を作成します。
#
# リファクタリング適用パターン:
# - Extract Function: 共通ロジックを common.sh に抽出
# - Replace Magic Number/String: 定数化
# - Compose Method: 複雑な関数を小さな関数に分解
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
# テンプレートマージ関数
# =============================================================================

# 公式テンプレートとローカルテンプレートをマージ
#
# 引数:
#   $1: マージ対象のディレクトリ（例: .claude/commands）
#
merge_templates() {
    local target_subdir="$1"

    log_info "テンプレートをマージ中: ${target_subdir}"

    merge_template_directories \
        "${target_subdir}" \
        "${TEMPLATES_DIR}" \
        "${TEMPLATES_LOCAL_DIR}" \
        "${PROJECT_ROOT}"
}

# テンプレートの実体を templates-local 優先で解決
#
# 引数:
#   $1: テンプレートの相対パス（例: .codex/CODEX.md）
#
# 戻り値:
#   標準出力に選択されたテンプレートのパスを出力
#
resolve_template_source() {
    local relative_path="$1"
    local local_template="${TEMPLATES_LOCAL_DIR}/${relative_path}"
    local official_template="${TEMPLATES_DIR}/${relative_path}"

    if [[ -f "${local_template}" ]]; then
        echo "${local_template}"
    else
        echo "${official_template}"
    fi
}

# =============================================================================
# Claude Code 設定
# =============================================================================

# Claude Code の設定ファイルをセットアップ
#
setup_claude_code() {
    log_info "Claude Code 設定をセットアップ中..."

    local claude_dir="${PROJECT_ROOT}/.claude"
    local settings_file="${claude_dir}/settings.local.json"
    local custom_instructions="${claude_dir}/CLAUDE.md"
    local commands_dir="${claude_dir}/commands"
    local agents_dir="${claude_dir}/agents"

    # ディレクトリ作成
    mkdir -p "${claude_dir}"

    # settings.local.json をコピー
    copy_file_if_not_exists \
        "${TEMPLATES_DIR}/.claude/settings.local.json.example" \
        "${settings_file}" \
        "Claude Code 設定ファイル"

    # CLAUDE.md をコピー
    copy_file_if_not_exists \
        "${TEMPLATES_DIR}/.claude/CLAUDE.md" \
        "${custom_instructions}" \
        "Claude Code カスタム指示"

    # commands ディレクトリのマージ処理
    setup_claude_commands "${commands_dir}"

    # agents ディレクトリのセットアップ
    setup_claude_agents "${agents_dir}"
}

# Claude Code のコマンドディレクトリをセットアップ
#
# 引数:
#   $1: コマンドディレクトリパス
#
setup_claude_commands() {
    local commands_dir="$1"

    if [[ ! -d "${commands_dir}" ]]; then
        merge_templates ".claude/commands"
        log_success "Claude Code カスタムコマンドを作成しました: ${commands_dir}"

        # 利用可能なコマンド数を表示
        local cmd_count
        cmd_count=$(count_files_in_directory "${commands_dir}" "*.md")
        log_info "利用可能なコマンド: ${cmd_count} 個"
    else
        log_info "Claude Code カスタムコマンドは既に存在します（スキップ）"
    fi
}

# Claude Code のサブエージェントディレクトリをセットアップ
#
# 引数:
#   $1: エージェントディレクトリパス
#
setup_claude_agents() {
    local agents_dir="$1"

    if [[ ! -d "${agents_dir}" ]]; then
        # templates からシンプルにコピー（マージ不要）
        if [[ -d "${TEMPLATES_DIR}/.claude/agents" ]]; then
            mkdir -p "${agents_dir}"
            # YAML ファイルをコピー
            if cp "${TEMPLATES_DIR}/.claude/agents/"*.yaml "${agents_dir}/" 2>/dev/null; then
                log_success "Claude Code サブエージェントを作成しました: ${agents_dir}"

                # 利用可能なエージェント数を表示
                local agent_count
                agent_count=$(count_files_in_directory "${agents_dir}" "*.yaml")
                log_info "利用可能なサブエージェント: ${agent_count} 個"
            else
                log_debug "コピーするエージェント定義が見つかりませんでした"
            fi
        else
            log_debug "サブエージェントテンプレートディレクトリが見つかりません（スキップ）"
        fi
    else
        log_info "Claude Code サブエージェントは既に存在します（スキップ）"
    fi
}

# =============================================================================
# Codex CLI 設定
# =============================================================================

# Codex CLI の設定ファイルをセットアップ
#
setup_codex_cli() {
    log_info "Codex CLI 設定をセットアップ中..."

    local codex_dir="${HOME}/.codex"
    local codex_project_dir="${PROJECT_ROOT}/.codex"
    local config_file="${codex_dir}/config.toml"
    local agents_md_home="${codex_dir}/AGENTS.md"
    local agents_md_project="${PROJECT_ROOT}/AGENTS.md"

    # ディレクトリ作成
    mkdir -p "${codex_dir}"
    mkdir -p "${codex_project_dir}"

    # config.toml をセットアップ
    setup_codex_config "${config_file}"

    # AGENTS.md をプロジェクトルートにコピー（チーム共有設定）
    copy_file_if_not_exists \
        "${TEMPLATES_DIR}/.codex/AGENTS.md" \
        "${agents_md_project}" \
        "Codex CLI エージェント指示（チーム共有）"

    # AGENTS.md を ~/.codex/ にもコピー（個人設定、優先度高）
    copy_file_if_not_exists \
        "${TEMPLATES_DIR}/.codex/AGENTS.md" \
        "${agents_md_home}" \
        "Codex CLI エージェント指示（個人設定）"

    # カスタムプロンプトをセットアップ
    setup_codex_prompt "${codex_dir}" "${codex_project_dir}"
}

# Codex CLI の設定ファイルを作成してプロジェクトパスを置換
#
# 引数:
#   $1: 設定ファイルパス
#
setup_codex_config() {
    local config_file="$1"

    if [[ ! -f "${config_file}" ]]; then
        if [[ -f "${TEMPLATES_DIR}/.codex/config.toml.example" ]]; then
            # テンプレートをコピー
            cp "${TEMPLATES_DIR}/.codex/config.toml.example" "${config_file}"

            # YOUR_PROJECT_NAME をプロジェクトパスに置換
            replace_in_file \
                "${config_file}" \
                "/workspaces/YOUR_PROJECT_NAME" \
                "${PROJECT_ROOT}"

            log_success "Codex CLI 設定ファイルを作成しました: ${config_file}"
            log_info "プロジェクトパスを ${PROJECT_ROOT} に設定しました"
        else
            log_warn "Codex CLI テンプレートが見つかりません"
        fi
    else
        log_info "Codex CLI 設定ファイルは既に存在します（スキップ）"
    fi
}

# Codex CLI のカスタムプロンプトをセットアップ
#
# 引数:
#   $1: ホームディレクトリ側の Codex ルート
#   $2: プロジェクトルート側の Codex ルート
#
setup_codex_prompt() {
    local codex_home_dir="$1"
    local codex_project_dir="$2"
    local relative_path=".codex/CODEX.md"
    local template_source

    template_source="$(resolve_template_source "${relative_path}")"

    if [[ ! -f "${template_source}" ]]; then
        log_warn "Codex CLI カスタムプロンプトのテンプレートが見つかりません: ${relative_path}"
        return 0
    fi

    if [[ "${template_source}" == "${TEMPLATES_LOCAL_DIR}"/* ]]; then
        log_info "templates-local 版の Codex プロンプトを使用します: ${template_source}"
    fi

    local project_prompt="${codex_project_dir}/CODEX.md"
    local home_prompt="${codex_home_dir}/CODEX.md"

    copy_file_if_not_exists \
        "${template_source}" \
        "${project_prompt}" \
        "Codex CLI カスタムプロンプト（プロジェクト共有）"

    copy_file_if_not_exists \
        "${template_source}" \
        "${home_prompt}" \
        "Codex CLI カスタムプロンプト（個人設定）"
}

# =============================================================================
# GEMINI 設定
# =============================================================================

# GEMINI の設定ファイルをセットアップ
#
setup_gemini() {
    log_info "GEMINI 設定をセットアップ中..."

    local gemini_dir="${PROJECT_ROOT}/.gemini"
    local settings_file="${gemini_dir}/settings.json"
    local gemini_md="${gemini_dir}/GEMINI.md"

    # ディレクトリ作成
    mkdir -p "${gemini_dir}"

    # settings.json をセットアップ
    setup_gemini_settings "${settings_file}"

    # GEMINI.md をコピー
    copy_file_if_not_exists \
        "${TEMPLATES_DIR}/.gemini/GEMINI.md" \
        "${gemini_md}" \
        "GEMINI カスタム指示"
}

# GEMINI の設定ファイルを作成してプレースホルダーを置換
#
# 引数:
#   $1: 設定ファイルパス
#
setup_gemini_settings() {
    local settings_file="$1"

    if [[ ! -f "${settings_file}" ]]; then
        if [[ -f "${TEMPLATES_DIR}/.gemini/settings.json.example" ]]; then
            cp "${TEMPLATES_DIR}/.gemini/settings.json.example" "${settings_file}"

            # ${workspaceFolder} をプロジェクトルートに置換
            replace_in_file \
                "${settings_file}" \
                "\${workspaceFolder}" \
                "${PROJECT_ROOT}"

            log_success "GEMINI 設定ファイルを作成しました: ${settings_file}"
        else
            log_warn "GEMINI settings.json テンプレートが見つかりません"
        fi
    else
        log_info "GEMINI 設定ファイルは既に存在します（スキップ）"
    fi
}

# =============================================================================
# プロンプトテンプレート設定
# =============================================================================

# プロンプトテンプレートをセットアップ
#
setup_prompt_templates() {
    log_info "プロンプトテンプレートをセットアップ中..."

    local prompts_dir="${PROJECT_ROOT}/docs/prompts"
    local tasks_dir="${prompts_dir}/tasks"

    # ディレクトリ作成
    mkdir -p "${tasks_dir}"

    # system.md をコピー
    copy_file_if_not_exists \
        "${TEMPLATES_DIR}/docs/prompts/system.md" \
        "${prompts_dir}/system.md" \
        "システムプロンプトテンプレート"

    # タスクプロンプトをコピー
    setup_task_prompts "${tasks_dir}"
}

# タスクプロンプトテンプレートをコピー
#
# 引数:
#   $1: タスクディレクトリパス
#
setup_task_prompts() {
    local tasks_dir="$1"
    local task_files=("feature-add.md" "bug-fix.md" "refactor.md" "review.md")

    for task_file in "${task_files[@]}"; do
        copy_file_if_not_exists \
            "${TEMPLATES_DIR}/docs/prompts/tasks/${task_file}" \
            "${tasks_dir}/${task_file}" \
            "タスクプロンプト (${task_file})"
    done
}

# =============================================================================
# .gitignore 更新
# =============================================================================

# .gitignore にAI拡張機能の除外設定を追加
#
update_gitignore() {
    log_info ".gitignore を更新中..."

    local gitignore="${PROJECT_ROOT}/.gitignore"
    local -a entries=(
        ""
        "# AI拡張機能のローカル設定"
        ".claude/settings.local.json"
        ".claude/custom-instructions.md"
        ""
    )

    update_gitignore_safe \
        "${gitignore}" \
        "# AI拡張機能のローカル設定" \
        "${entries[@]}"
}

# =============================================================================
# 環境変数の確認
# =============================================================================

# APIキーの環境変数をチェック
#
check_environment() {
    log_info "環境変数を確認中..."

    check_api_keys \
        "ANTHROPIC_API_KEY" \
        "OPENAI_API_KEY" \
        "GEMINI_API_KEY" \
        "GITHUB_TOKEN"
}

# =============================================================================
# メイン処理
# =============================================================================

# セットアップのメイン処理
#
main() {
    show_header "AI Extensions Configuration Setup"

    log_info "AI拡張機能の設定を初期化します..."
    log_info "プロジェクトルート: ${PROJECT_ROOT}"
    echo ""

    # 各セットアップを実行
    setup_claude_code
    echo ""

    setup_codex_cli
    echo ""

    setup_gemini
    echo ""

    setup_prompt_templates
    echo ""

    update_gitignore
    echo ""

    check_environment
    echo ""

    show_footer "$(log_success "セットアップが完了しました！")"

    log_info "次のステップ:"
    echo "  1. 環境変数を設定（.env ファイル）"
    echo "  2. .claude/settings.local.json で権限をカスタマイズ"
    echo "  3. ~/.codex/config.toml でモデルを選択"
    echo "  4. docs/prompts/system.md をプロジェクトに合わせて編集"
    echo ""
    log_info "詳細は templates/README.md を参照してください"
}

# スクリプト実行
main "$@"
