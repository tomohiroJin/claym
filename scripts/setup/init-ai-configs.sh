#!/usr/bin/env bash
# AI拡張機能の設定ファイルを自動セットアップするスクリプト
# コンテナ起動時に実行され、各AIツールが利用可能な状態を作成します

set -euo pipefail

# 色付き出力
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# プロジェクトルートを取得
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPLATES_DIR="${PROJECT_ROOT}/templates"

log_info "AI拡張機能の設定を初期化します..."
log_info "プロジェクトルート: ${PROJECT_ROOT}"

# =============================================================================
# Claude Code 設定
# =============================================================================
setup_claude_code() {
    log_info "Claude Code 設定をセットアップ中..."

    local claude_dir="${PROJECT_ROOT}/.claude"
    local settings_file="${claude_dir}/settings.local.json"
    local custom_instructions="${claude_dir}/custom-instructions.md"

    # ディレクトリ作成
    mkdir -p "${claude_dir}"

    # settings.local.json が存在しない場合のみコピー
    if [[ ! -f "${settings_file}" ]]; then
        if [[ -f "${TEMPLATES_DIR}/.claude/settings.local.json.example" ]]; then
            cp "${TEMPLATES_DIR}/.claude/settings.local.json.example" "${settings_file}"
            log_success "Claude Code 設定ファイルを作成しました: ${settings_file}"
        else
            log_warn "Claude Code テンプレートが見つかりません"
        fi
    else
        log_info "Claude Code 設定ファイルは既に存在します（スキップ）"
    fi

    # custom-instructions.md が存在しない場合のみコピー
    if [[ ! -f "${custom_instructions}" ]]; then
        if [[ -f "${TEMPLATES_DIR}/.claude/custom-instructions.md" ]]; then
            cp "${TEMPLATES_DIR}/.claude/custom-instructions.md" "${custom_instructions}"
            log_success "Claude Code カスタム指示を作成しました: ${custom_instructions}"
        fi
    else
        log_info "Claude Code カスタム指示は既に存在します（スキップ）"
    fi
}

# =============================================================================
# Codex CLI 設定
# =============================================================================
setup_codex_cli() {
    log_info "Codex CLI 設定をセットアップ中..."

    local codex_dir="${HOME}/.codex"
    local config_file="${codex_dir}/config.toml"

    # ディレクトリ作成
    mkdir -p "${codex_dir}"

    # config.toml が存在しない場合のみコピーして置換
    if [[ ! -f "${config_file}" ]]; then
        if [[ -f "${TEMPLATES_DIR}/.codex/config.toml.example" ]]; then
            # テンプレートをコピー
            cp "${TEMPLATES_DIR}/.codex/config.toml.example" "${config_file}"

            # YOUR_PROJECT_NAME をプロジェクト名に置換
            local project_name
            project_name="$(basename "${PROJECT_ROOT}")"
            sed -i "s|/workspaces/YOUR_PROJECT_NAME|${PROJECT_ROOT}|g" "${config_file}"

            log_success "Codex CLI 設定ファイルを作成しました: ${config_file}"
            log_info "プロジェクトパスを ${PROJECT_ROOT} に設定しました"
        else
            log_warn "Codex CLI テンプレートが見つかりません"
        fi
    else
        log_info "Codex CLI 設定ファイルは既に存在します（スキップ）"
    fi
}

# =============================================================================
# GEMINI 設定
# =============================================================================
setup_gemini() {
    log_info "GEMINI 設定を確認中..."

    local gemini_dir="${PROJECT_ROOT}/.gemini"
    local settings_file="${gemini_dir}/settings.json"

    # .gemini ディレクトリが存在しない場合のみ作成
    if [[ ! -d "${gemini_dir}" ]]; then
        mkdir -p "${gemini_dir}"
    fi

    # settings.json が存在する場合は確認メッセージのみ
    if [[ -f "${settings_file}" ]]; then
        log_success "GEMINI 設定ファイルは既に存在します: ${settings_file}"
    else
        log_warn "GEMINI 設定ファイルが見つかりません"
        log_info "GEMINI 設定は手動で作成するか、GEMINIの初回起動時に自動生成されます"
    fi
}

# =============================================================================
# プロンプトテンプレート
# =============================================================================
setup_prompt_templates() {
    log_info "プロンプトテンプレートをセットアップ中..."

    local prompts_dir="${PROJECT_ROOT}/docs/prompts"
    local tasks_dir="${prompts_dir}/tasks"

    # ディレクトリ作成
    mkdir -p "${tasks_dir}"

    # system.md をコピー
    if [[ ! -f "${prompts_dir}/system.md" ]]; then
        if [[ -f "${TEMPLATES_DIR}/docs/prompts/system.md" ]]; then
            cp "${TEMPLATES_DIR}/docs/prompts/system.md" "${prompts_dir}/system.md"
            log_success "システムプロンプトテンプレートを作成しました"
        fi
    fi

    # タスクプロンプトをコピー
    local task_files=("feature-add.md" "bug-fix.md" "refactor.md" "review.md")
    for task_file in "${task_files[@]}"; do
        if [[ ! -f "${tasks_dir}/${task_file}" ]]; then
            if [[ -f "${TEMPLATES_DIR}/docs/prompts/tasks/${task_file}" ]]; then
                cp "${TEMPLATES_DIR}/docs/prompts/tasks/${task_file}" "${tasks_dir}/${task_file}"
                log_success "タスクプロンプトを作成しました: ${task_file}"
            fi
        fi
    done
}

# =============================================================================
# .gitignore 更新
# =============================================================================
update_gitignore() {
    log_info ".gitignore を更新中..."

    local gitignore="${PROJECT_ROOT}/.gitignore"
    local entries=(
        ""
        "# AI拡張機能のローカル設定"
        ".claude/settings.local.json"
        ".claude/custom-instructions.md"
        ""
    )

    # .gitignore が存在しない場合は作成
    if [[ ! -f "${gitignore}" ]]; then
        touch "${gitignore}"
    fi

    # 既に追加されているかチェック
    if ! grep -q "# AI拡張機能のローカル設定" "${gitignore}"; then
        for entry in "${entries[@]}"; do
            echo "${entry}" >> "${gitignore}"
        done
        log_success ".gitignore を更新しました"
    else
        log_info ".gitignore は既に更新されています（スキップ）"
    fi
}

# =============================================================================
# 環境変数の確認
# =============================================================================
check_environment() {
    log_info "環境変数を確認中..."

    local missing_vars=()

    # 各APIキーの存在確認（警告のみ、エラーにはしない）
    [[ -z "${ANTHROPIC_API_KEY:-}" ]] && missing_vars+=("ANTHROPIC_API_KEY")
    [[ -z "${OPENAI_API_KEY:-}" ]] && missing_vars+=("OPENAI_API_KEY")
    [[ -z "${GEMINI_API_KEY:-}" ]] && missing_vars+=("GEMINI_API_KEY")
    [[ -z "${GITHUB_TOKEN:-}" ]] && missing_vars+=("GITHUB_TOKEN")

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_warn "以下の環境変数が設定されていません:"
        for var in "${missing_vars[@]}"; do
            log_warn "  - ${var}"
        done
        log_info "必要に応じて .env ファイルに設定してください"
    else
        log_success "必要な環境変数が設定されています"
    fi
}

# =============================================================================
# メイン処理
# =============================================================================
main() {
    echo "========================================"
    echo "  AI Extensions Configuration Setup"
    echo "========================================"
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

    echo "========================================"
    log_success "セットアップが完了しました！"
    echo "========================================"
    echo ""
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
