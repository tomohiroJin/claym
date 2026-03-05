#!/usr/bin/env bats
# =============================================================================
# template-existence.bats
# AI CLI テンプレートファイルの存在確認テスト
# =============================================================================
#
# feature/brush_up_overall ブランチで追加された全テンプレートファイルの
# 存在を確認するテスト。
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
# ディレクトリ存在確認
# ==============================================================================

@test "Claude agents ディレクトリが存在する" {
    assert_dir_exist "${CLAUDE_AGENTS_DIR}"
}

@test "Claude commands ディレクトリが存在する" {
    assert_dir_exist "${CLAUDE_COMMANDS_DIR}"
}

@test "Claude rules ディレクトリが存在する" {
    assert_dir_exist "${CLAUDE_RULES_DIR}"
}

@test "Codex prompts ディレクトリが存在する" {
    assert_dir_exist "${CODEX_PROMPTS_DIR}"
}

@test "Gemini commands ディレクトリが存在する" {
    assert_dir_exist "${GEMINI_COMMANDS_DIR}"
}

# ==============================================================================
# ファイル群の存在確認
# ==============================================================================

@test "Claude エージェント4個が存在する" {
    local agents=("architect" "planner" "build-error-resolver" "security-reviewer")
    check_files_exist "${CLAUDE_AGENTS_DIR}" ".yaml" "${agents[@]}"
}

@test "Claude コマンド6個が存在する" {
    local commands=("plan" "build-fix" "refactor" "checkpoint" "tdd" "test-coverage")
    check_files_exist "${CLAUDE_COMMANDS_DIR}" ".md" "${commands[@]}"
}

@test "Claude ルール4個が存在する" {
    local rules=("coding-style" "git-workflow" "testing" "security")
    check_files_exist "${CLAUDE_RULES_DIR}" ".md" "${rules[@]}"
}

@test "Codex プロンプト16個が存在する" {
    local prompts=(
        "plan" "build-fix" "review" "refactor" "yfinance"
        "test" "code-gen" "docs" "checkpoint" "tdd" "test-coverage"
        "agent-architect" "agent-docs-writer" "agent-security" "agent-test-gen"
        "skill"
    )
    check_files_exist "${CODEX_PROMPTS_DIR}" ".md" "${prompts[@]}"
}

@test "Codex instructions ディレクトリが存在する" {
    assert_dir_exist "${CODEX_INSTRUCTIONS_DIR}"
}

@test "Codex インストラクション4個が存在する" {
    local instructions=("coding-style" "git-workflow" "security" "testing")
    check_files_exist "${CODEX_INSTRUCTIONS_DIR}" ".md" "${instructions[@]}"
}

@test "Gemini コマンド16個が存在する" {
    local commands=(
        "plan" "build-fix" "review" "refactor" "test" "yfinance"
        "code-gen" "docs" "checkpoint" "tdd" "test-coverage"
        "agent-architect" "agent-docs-writer" "agent-security" "agent-test-gen"
        "skill"
    )
    check_files_exist "${GEMINI_COMMANDS_DIR}" ".md" "${commands[@]}"
}

@test "Gemini rules ディレクトリが存在する" {
    assert_dir_exist "${GEMINI_RULES_DIR}"
}

@test "Gemini ルール4個が存在する" {
    local rules=("coding-style" "git-workflow" "security" "testing")
    check_files_exist "${GEMINI_RULES_DIR}" ".md" "${rules[@]}"
}

# ==============================================================================
# Agent Skills の存在確認
# ==============================================================================

@test "skills ディレクトリが存在する" {
    assert_dir_exist "${SKILLS_DIR}"
}

@test "Agent Skills 10個が存在する" {
    local skills=(
        "tdd-workflow" "code-review" "security-review" "search-first"
        "verification-loop" "api-design" "refactor-safely"
        "debug-systematically" "documentation-first" "git-workflow"
    )
    for skill in "${skills[@]}"; do
        assert_file_exist "${SKILLS_DIR}/${skill}/SKILL.md"
    done
}

# ==============================================================================
# メイン設定ファイルの存在確認
# ==============================================================================

@test "CLAUDE.md が存在する" {
    assert_file_exist "${CLAUDE_MD}"
}

@test "AGENTS.md が存在する" {
    assert_file_exist "${CODEX_MD}"
}

@test "GEMINI.md が存在する" {
    assert_file_exist "${GEMINI_MD}"
}
