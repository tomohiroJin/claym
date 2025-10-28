#!/usr/bin/env bats
# init-ai-configs.sh のテスト
#
# テスト対象:
# - merge_templates() 関数
# - Claude Code コマンドのセットアップ
# - テンプレートのマージ動作
#
# リファクタリング適用パターン:
# - Extract Function: 共通ロジックをヘルパー関数に抽出
# - Extract Variable: マジックリテラルを定数化
# - Test Data Builder: テストデータ構築を分離

# ==============================================================================
# テストヘルパーのロード
# ==============================================================================

load '/usr/local/lib/bats-support/load'
load '/usr/local/lib/bats-assert/load'
load '/usr/local/lib/bats-file/load'
load 'test_helper'

# ==============================================================================
# セットアップ/ティアダウン
# ==============================================================================

# セットアップ: 各テストの前に実行
setup() {
    create_standard_test_directories
    create_official_template_files
}

# ティアダウン: 各テストの後に実行
teardown() {
    cleanup_test_directory
}

# ==============================================================================
# merge_templates() 関数のテスト
# ==============================================================================

@test "merge_templates: 公式テンプレートのみの場合、正しくコピーされる" {
    # Arrange (準備)
    define_merge_templates_function

    # Act (実行)
    run merge_templates ".claude/commands"

    # Assert (検証)
    assert_success
    assert_official_template_files_exist
    assert_official_template_content "${PROJECT_ROOT}/.claude/commands/test1.md"
}

@test "merge_templates: ローカルテンプレートで上書きされる" {
    # Arrange
    create_local_override_template
    define_merge_templates_function

    # Act
    run merge_templates ".claude/commands"

    # Assert
    assert_success
    assert_local_template_content "${PROJECT_ROOT}/.claude/commands/test1.md"
    assert_official_template_content "${PROJECT_ROOT}/.claude/commands/test2.md"
}

@test "merge_templates: ローカル独自のファイルも追加される" {
    # Arrange
    create_custom_local_template
    define_merge_templates_function

    # Act
    run merge_templates ".claude/commands"

    # Assert
    assert_success
    assert_official_template_files_exist
    assert_file_exist "${PROJECT_ROOT}/.claude/commands/custom.md"
    assert_custom_template_content "${PROJECT_ROOT}/.claude/commands/custom.md"
}

@test "merge_templates: 公式テンプレートが存在しない場合でもエラーにならない" {
    # Arrange
    define_merge_templates_function

    # Act
    run merge_templates ".nonexistent/path"

    # Assert
    assert_success
}

@test "merge_templates: ローカルテンプレートが存在しない場合でもエラーにならない" {
    # Arrange
    rm -rf "${TEMPLATES_LOCAL_DIR}/.claude"
    define_merge_templates_function

    # Act
    run merge_templates ".claude/commands"

    # Assert
    assert_success
    assert_official_template_files_exist
}

# ==============================================================================
# init-ai-configs.sh スクリプト全体のテスト
# ==============================================================================

@test "init-ai-configs.sh: スクリプトが正常に実行できる" {
    # スクリプトのシンタックスチェック
    run bash -n /workspaces/claym/scripts/setup/init-ai-configs.sh
    assert_success
}

@test "init-ai-configs.sh: 必須の関数が定義されている" {
    # スクリプトをソースして関数の存在を確認
    source /workspaces/claym/scripts/setup/init-ai-configs.sh 2>/dev/null || true

    # 各関数が定義されていることを確認
    run type merge_templates
    assert_success

    run type setup_claude_code
    assert_success

    run type setup_claude_commands
    assert_success

    run type setup_claude_agents
    assert_success

    run type setup_codex_cli
    assert_success

    run type setup_gemini
    assert_success
}

# ==============================================================================
# setup_claude_agents() 関数のテスト
# ==============================================================================

@test "setup_claude_agents: エージェントテンプレートが正しくコピーされる" {
    # Arrange
    create_agent_template_files
    define_setup_claude_agents_function

    # Act
    run setup_claude_agents "${PROJECT_ROOT}/.claude/agents"

    # Assert
    assert_success
    assert_agent_files_exist "${PROJECT_ROOT}/.claude/agents"
}

@test "setup_claude_agents: 3つのエージェントファイルがすべてコピーされる" {
    # Arrange
    create_agent_template_files
    define_setup_claude_agents_function

    # Act
    run setup_claude_agents "${PROJECT_ROOT}/.claude/agents"

    # Assert
    assert_success

    # ファイル数を確認
    local agent_count
    agent_count=$(find "${PROJECT_ROOT}/.claude/agents" -name "*.yaml" -type f | wc -l)
    [ "${agent_count}" -eq 3 ]
}

@test "setup_claude_agents: 既に存在する場合はスキップされる" {
    # Arrange
    create_agent_template_files
    define_setup_claude_agents_function
    mkdir -p "${PROJECT_ROOT}/.claude/agents"

    # Act
    run setup_claude_agents "${PROJECT_ROOT}/.claude/agents"

    # Assert
    assert_success
    assert_output --partial "既に存在します"
}

@test "setup_claude_agents: テンプレートディレクトリが存在しない場合でもエラーにならない" {
    # Arrange
    define_setup_claude_agents_function
    # テンプレートディレクトリを作成しない

    # Act
    run setup_claude_agents "${PROJECT_ROOT}/.claude/agents"

    # Assert
    assert_success
}

@test "setup_claude_agents: YAMLファイルの内容が正しくコピーされる" {
    # Arrange
    create_agent_template_files
    define_setup_claude_agents_function

    # Act
    run setup_claude_agents "${PROJECT_ROOT}/.claude/agents"

    # Assert
    assert_success

    # code-reviewer.yaml の内容を確認
    run grep 'name: "code-reviewer"' "${PROJECT_ROOT}/.claude/agents/code-reviewer.yaml"
    assert_success

    # test-generator.yaml の内容を確認
    run grep 'name: "test-generator"' "${PROJECT_ROOT}/.claude/agents/test-generator.yaml"
    assert_success

    # documentation-writer.yaml の内容を確認
    run grep 'name: "documentation-writer"' "${PROJECT_ROOT}/.claude/agents/documentation-writer.yaml"
    assert_success
}
