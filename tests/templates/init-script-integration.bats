#!/usr/bin/env bats
# =============================================================================
# init-script-integration.bats
# init-ai-configs.sh の変更検証テスト
# =============================================================================
#
# feature/brush_up_overall ブランチで init-ai-configs.sh に追加された
# 関数・呼び出しが正しく定義されているかを検証。
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
# 前提条件
# ==============================================================================

setup() {
    assert_file_exist "${INIT_SCRIPT}"
}

# ==============================================================================
# setup_claude_rules 関連
# ==============================================================================

@test "setup_claude_rules() 関数が定義されている" {
    grep -q '^setup_claude_rules()' "${INIT_SCRIPT}"
}

@test "setup_claude_rules が呼び出されている" {
    # 定義（1回）+ 呼び出し（1回以上）= 2回以上
    local call_count
    call_count=$(grep -c 'setup_claude_rules' "${INIT_SCRIPT}")
    [[ "$call_count" -ge 2 ]]
}

@test "setup_claude_rules 内で merge_templates を使用している" {
    # 関数本体を抽出して確認
    local func_body
    func_body=$(sed -n '/^setup_claude_rules()/,/^}/p' "${INIT_SCRIPT}")
    echo "$func_body" | grep -q 'merge_templates'
}

@test "rules_dir 変数が定義されている" {
    grep -q 'rules_dir' "${INIT_SCRIPT}"
}

# ==============================================================================
# setup_claude_agents 関連
# ==============================================================================

@test "setup_claude_agents() 関数が定義されている" {
    grep -q '^setup_claude_agents()' "${INIT_SCRIPT}"
}

@test "setup_claude_agents が呼び出されている" {
    local call_count
    call_count=$(grep -c 'setup_claude_agents' "${INIT_SCRIPT}")
    [[ "$call_count" -ge 2 ]]
}

# ==============================================================================
# setup_claude_commands 関連
# ==============================================================================

@test "setup_claude_commands() 関数が定義されている" {
    grep -q '^setup_claude_commands()' "${INIT_SCRIPT}"
}

@test "setup_claude_commands が呼び出されている" {
    local call_count
    call_count=$(grep -c 'setup_claude_commands' "${INIT_SCRIPT}")
    [[ "$call_count" -ge 2 ]]
}
