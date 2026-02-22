#!/usr/bin/env bats
# =============================================================================
# template-quality.bats
# AI CLI テンプレートの品質検証テスト
# =============================================================================
#
# テンプレートファイルの品質を検証:
# - 非空チェック（全ファイル）
# - YAML 必須フィールド（エージェント）
# - Markdown 構造（コマンド・ルール）
# - 共通原則の一貫性（メイン設定ファイル間）
#
# テスト数: 15

# ==============================================================================
# テストヘルパーのロード
# ==============================================================================

load '/usr/local/lib/bats-support/load'
load '/usr/local/lib/bats-assert/load'
load '/usr/local/lib/bats-file/load'
load 'template_test_helper'

# ==============================================================================
# 非空チェック
# ==============================================================================

@test "Claude エージェント（YAML）が非空である" {
    check_files_non_empty "${CLAUDE_AGENTS_DIR}" "*.yaml"
}

@test "Claude コマンド（MD）が非空である" {
    check_files_non_empty "${CLAUDE_COMMANDS_DIR}" "*.md"
}

@test "Claude ルール（MD）が非空である" {
    check_files_non_empty "${CLAUDE_RULES_DIR}" "*.md"
}

@test "Codex プロンプト（MD）が非空である" {
    check_files_non_empty "${CODEX_PROMPTS_DIR}" "*.md"
}

@test "Gemini コマンド（MD）が非空である" {
    check_files_non_empty "${GEMINI_COMMANDS_DIR}" "*.md"
}

@test "メイン設定ファイルが非空である" {
    [[ -s "${CLAUDE_MD}" ]]
    [[ -s "${CODEX_MD}" ]]
    [[ -s "${GEMINI_MD}" ]]
}

# ==============================================================================
# YAML 必須フィールド
# ==============================================================================

@test "architect.yaml に name と prompt フィールドが存在する" {
    check_yaml_required_fields "${CLAUDE_AGENTS_DIR}/architect.yaml" "name" "prompt"
}

@test "planner.yaml に name と prompt フィールドが存在する" {
    check_yaml_required_fields "${CLAUDE_AGENTS_DIR}/planner.yaml" "name" "prompt"
}

@test "build-error-resolver.yaml に name と prompt フィールドが存在する" {
    check_yaml_required_fields "${CLAUDE_AGENTS_DIR}/build-error-resolver.yaml" "name" "prompt"
}

@test "security-reviewer.yaml に name と prompt フィールドが存在する" {
    check_yaml_required_fields "${CLAUDE_AGENTS_DIR}/security-reviewer.yaml" "name" "prompt"
}

# ==============================================================================
# Markdown 見出し構造
# ==============================================================================

@test "Claude コマンドが正しい Markdown 構造を持つ" {
    local commands=("plan" "build-fix" "refactor" "checkpoint" "tdd" "test-coverage")
    local all_valid=true

    for cmd in "${commands[@]}"; do
        local file="${CLAUDE_COMMANDS_DIR}/${cmd}.md"
        if [[ -f "$file" ]]; then
            if ! check_markdown_has_headings "$file"; then
                all_valid=false
            fi
        else
            echo "# ファイルが見つかりません: ${file}" >&3
            all_valid=false
        fi
    done

    [[ "$all_valid" == "true" ]]
}

@test "Claude ルールが正しい Markdown 構造を持つ" {
    local rules=("coding-style" "git-workflow" "testing" "security")
    local all_valid=true

    for rule in "${rules[@]}"; do
        local file="${CLAUDE_RULES_DIR}/${rule}.md"
        if [[ -f "$file" ]]; then
            if ! check_markdown_has_headings "$file"; then
                all_valid=false
            fi
        else
            echo "# ファイルが見つかりません: ${file}" >&3
            all_valid=false
        fi
    done

    [[ "$all_valid" == "true" ]]
}

@test "メイン設定ファイルが正しい Markdown 構造を持つ" {
    local all_valid=true
    local files=("${CLAUDE_MD}" "${CODEX_MD}" "${GEMINI_MD}")

    for file in "${files[@]}"; do
        if ! check_markdown_has_headings "$file"; then
            all_valid=false
        fi
    done

    [[ "$all_valid" == "true" ]]
}

# ==============================================================================
# 共通原則の一貫性
# ==============================================================================

@test "共通原則が各ファイルで6項目である" {
    local claude_count codex_count gemini_count

    claude_count=$(extract_common_principles "${CLAUDE_MD}" | wc -l)
    codex_count=$(extract_common_principles "${CODEX_MD}" | wc -l)
    gemini_count=$(extract_common_principles "${GEMINI_MD}" | wc -l)

    if [[ "$claude_count" -ne 6 ]]; then
        echo "# CLAUDE.md の共通原則: ${claude_count}項目（期待: 6）" >&3
        false
    fi
    if [[ "$codex_count" -ne 6 ]]; then
        echo "# AGENTS.md の共通原則: ${codex_count}項目（期待: 6）" >&3
        false
    fi
    if [[ "$gemini_count" -ne 6 ]]; then
        echo "# GEMINI.md の共通原則: ${gemini_count}項目（期待: 6）" >&3
        false
    fi
}

@test "3ファイルの共通原則が同一内容である" {
    local claude_content codex_content gemini_content

    claude_content=$(extract_common_principles "${CLAUDE_MD}")
    codex_content=$(extract_common_principles "${CODEX_MD}")
    gemini_content=$(extract_common_principles "${GEMINI_MD}")

    if [[ "$claude_content" != "$codex_content" ]]; then
        echo "# CLAUDE.md と AGENTS.md の共通原則が一致しません" >&3
        false
    fi
    if [[ "$claude_content" != "$gemini_content" ]]; then
        echo "# CLAUDE.md と GEMINI.md の共通原則が一致しません" >&3
        false
    fi
}
