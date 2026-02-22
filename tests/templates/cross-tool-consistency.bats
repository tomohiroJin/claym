#!/usr/bin/env bats
# =============================================================================
# cross-tool-consistency.bats
# Claude / Codex / Gemini 3ツール間の一貫性検証テスト
# =============================================================================
#
# 3つの AI ツール（Claude Code, Codex CLI, Gemini CLI）で共通の
# コマンドが存在し、目的が一致しているかを検証。
#
# テスト数: 8

# ==============================================================================
# テストヘルパーのロード
# ==============================================================================

load '/usr/local/lib/bats-support/load'
load '/usr/local/lib/bats-assert/load'
load '/usr/local/lib/bats-file/load'
load 'template_test_helper'

# ==============================================================================
# ヘルパー関数
# ==============================================================================

# 指定コマンドが3ツール全てに存在するか確認
check_common_command_exists() {
    local cmd="$1"
    local all_exist=true

    if [[ ! -f "${CLAUDE_COMMANDS_DIR}/${cmd}.md" ]]; then
        echo "# Claude: ${cmd}.md が見つかりません" >&3
        all_exist=false
    fi
    if [[ ! -f "${CODEX_PROMPTS_DIR}/${cmd}.md" ]]; then
        echo "# Codex: ${cmd}.md が見つかりません" >&3
        all_exist=false
    fi
    if [[ ! -f "${GEMINI_COMMANDS_DIR}/${cmd}.md" ]]; then
        echo "# Gemini: ${cmd}.md が見つかりません" >&3
        all_exist=false
    fi

    [[ "$all_exist" == "true" ]]
}

# コマンドが期待されるキーワードを3ツール全てで含むか確認
check_keyword_in_all_tools() {
    local cmd="$1"
    local keyword="$2"
    local all_contain=true

    local files=(
        "${CLAUDE_COMMANDS_DIR}/${cmd}.md"
        "${CODEX_PROMPTS_DIR}/${cmd}.md"
        "${GEMINI_COMMANDS_DIR}/${cmd}.md"
    )
    local labels=("Claude" "Codex" "Gemini")

    for i in "${!files[@]}"; do
        if [[ -f "${files[$i]}" ]]; then
            if ! grep -qi "${keyword}" "${files[$i]}" 2>/dev/null; then
                echo "# ${labels[$i]}: '${keyword}' が見つかりません (${cmd}.md)" >&3
                all_contain=false
            fi
        fi
    done

    [[ "$all_contain" == "true" ]]
}

# ==============================================================================
# 共通コマンド存在確認
# ==============================================================================

@test "plan が3ツール全てに存在する" {
    check_common_command_exists "plan"
}

@test "build-fix が3ツール全てに存在する" {
    check_common_command_exists "build-fix"
}

@test "refactor が3ツール全てに存在する" {
    check_common_command_exists "refactor"
}

@test "review が3ツール全てに存在する" {
    check_common_command_exists "review"
}

# ==============================================================================
# 目的キーワードの一貫性
# ==============================================================================

@test "plan に「計画」キーワードが含まれる" {
    check_keyword_in_all_tools "plan" "計画"
}

@test "build-fix に「ビルド」キーワードが含まれる" {
    check_keyword_in_all_tools "build-fix" "ビルド"
}

@test "refactor に「リファクタ」キーワードが含まれる" {
    check_keyword_in_all_tools "refactor" "リファクタ"
}

@test "review に「レビュー」キーワードが含まれる" {
    check_keyword_in_all_tools "review" "レビュー"
}
