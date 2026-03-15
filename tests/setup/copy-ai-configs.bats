#!/usr/bin/env bats
# copy-ai-configs.sh のテスト
#
# テスト対象:
# - AI設定のコピー（.claude, .codex, .gemini, AGENTS.md）
# - .claude/settings.local.json の除外
# - .mcp.json の自動生成（パス置換・permissions 除外）
# - --force による上書き
# - --dry-run による確認のみモード
# - 既存ファイルがある場合のスキップ

# ==============================================================================
# テストヘルパーのロード
# ==============================================================================

load '/usr/local/lib/bats-support/load'
load '/usr/local/lib/bats-assert/load'
load '/usr/local/lib/bats-file/load'
load 'test_helper'

# ==============================================================================
# テスト用定数
# ==============================================================================

readonly COPY_SCRIPT="/workspaces/claym/scripts/setup/copy-ai-configs.sh"

# ==============================================================================
# セットアップ/ティアダウン
# ==============================================================================

setup() {
    TEST_DIR="$(mktemp -d)"
    SOURCE_ROOT="${TEST_DIR}/source-root"
    TARGET_ROOT="${TEST_DIR}/target-root"

    # コピー元のディレクトリとファイルを作成
    mkdir -p "${SOURCE_ROOT}/.claude/commands"
    mkdir -p "${SOURCE_ROOT}/.claude/rules"
    mkdir -p "${SOURCE_ROOT}/.codex/prompts"
    mkdir -p "${SOURCE_ROOT}/.gemini/commands"

    echo "# CLAUDE.md" > "${SOURCE_ROOT}/.claude/CLAUDE.md"
    cat > "${SOURCE_ROOT}/.claude/settings.local.json" << 'SETTINGS'
{
  "mcpServers": {
    "serena": {
      "command": "uv",
      "args": ["run", "--project", "${workspaceFolder}"]
    },
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  },
  "permissions": {"allow": ["Read"]}
}
SETTINGS
    echo "# コマンド1" > "${SOURCE_ROOT}/.claude/commands/review.md"
    echo "# ルール1" > "${SOURCE_ROOT}/.claude/rules/coding-style.md"
    echo "# Codex prompt" > "${SOURCE_ROOT}/.codex/prompts/default.md"
    echo "# Gemini コマンド" > "${SOURCE_ROOT}/.gemini/commands/review.md"
    echo '{"gemini": true}' > "${SOURCE_ROOT}/.gemini/settings.json"
    echo "# AGENTS.md" > "${SOURCE_ROOT}/AGENTS.md"

    mkdir -p "${TARGET_ROOT}"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ==============================================================================
# 基本的なコピー動作のテスト
# ==============================================================================

@test "copy-ai-configs.sh: 4項目がコピーされる" {
    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" "${TARGET_ROOT}"
    assert_success

    # ファイルとディレクトリが存在することを確認
    assert_file_exist "${TARGET_ROOT}/AGENTS.md"
    assert_dir_exist "${TARGET_ROOT}/.claude"
    assert_dir_exist "${TARGET_ROOT}/.codex"
    assert_dir_exist "${TARGET_ROOT}/.gemini"

    # コピーであり、シンボリックリンクではないことを確認
    if [[ -L "${TARGET_ROOT}/.claude" ]]; then
        fail ".claude はシンボリックリンクではなくコピーであるべき"
    fi
    if [[ -L "${TARGET_ROOT}/AGENTS.md" ]]; then
        fail "AGENTS.md はシンボリックリンクではなくコピーであるべき"
    fi
}

@test "copy-ai-configs.sh: コピーされたファイルの内容が正しい" {
    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" "${TARGET_ROOT}"
    assert_success

    # AGENTS.md の内容を確認
    run cat "${TARGET_ROOT}/AGENTS.md"
    assert_output "# AGENTS.md"

    # .claude/CLAUDE.md の内容を確認
    run cat "${TARGET_ROOT}/.claude/CLAUDE.md"
    assert_output "# CLAUDE.md"

    # .claude サブディレクトリの内容を確認
    assert_file_exist "${TARGET_ROOT}/.claude/commands/review.md"
    assert_file_exist "${TARGET_ROOT}/.claude/rules/coding-style.md"

    # .codex の内容を確認
    assert_file_exist "${TARGET_ROOT}/.codex/prompts/default.md"

    # .gemini の内容を確認
    assert_file_exist "${TARGET_ROOT}/.gemini/settings.json"
    assert_file_exist "${TARGET_ROOT}/.gemini/commands/review.md"
}

# ==============================================================================
# settings.local.json 除外のテスト
# ==============================================================================

@test "copy-ai-configs.sh: settings.local.json が除外される" {
    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" "${TARGET_ROOT}"
    assert_success

    # settings.local.json はコピーされないことを確認
    assert_file_not_exist "${TARGET_ROOT}/.claude/settings.local.json"

    # 他のファイルはコピーされていることを確認
    assert_file_exist "${TARGET_ROOT}/.claude/CLAUDE.md"
}

# ==============================================================================
# 既存ファイルのスキップテスト
# ==============================================================================

@test "copy-ai-configs.sh: 既存ディレクトリはスキップされる" {
    # 先に .claude を作成
    mkdir -p "${TARGET_ROOT}/.claude"
    echo "# 既存のファイル" > "${TARGET_ROOT}/.claude/CLAUDE.md"

    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" "${TARGET_ROOT}"
    assert_success
    assert_output --partial "既に存在するためスキップしました"

    # 既存の内容が保持されていることを確認
    run cat "${TARGET_ROOT}/.claude/CLAUDE.md"
    assert_output "# 既存のファイル"
}

@test "copy-ai-configs.sh: スキップ件数がサマリに表示される" {
    mkdir -p "${TARGET_ROOT}/.claude"
    mkdir -p "${TARGET_ROOT}/.codex"

    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" "${TARGET_ROOT}"
    assert_success
    assert_output --partial "スキップ: 2 件"
}

# ==============================================================================
# --force オプションのテスト
# ==============================================================================

@test "copy-ai-configs.sh: --force で既存が上書きされる" {
    # 先に古い内容で作成
    mkdir -p "${TARGET_ROOT}/.claude"
    echo "# 古い内容" > "${TARGET_ROOT}/.claude/CLAUDE.md"

    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" --force "${TARGET_ROOT}"
    assert_success

    # 新しい内容に上書きされていることを確認
    run cat "${TARGET_ROOT}/.claude/CLAUDE.md"
    assert_output "# CLAUDE.md"
}

@test "copy-ai-configs.sh: --force でもsettings.local.json は除外される" {
    mkdir -p "${TARGET_ROOT}/.claude"

    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" --force "${TARGET_ROOT}"
    assert_success
    assert_file_not_exist "${TARGET_ROOT}/.claude/settings.local.json"
}

# ==============================================================================
# --dry-run オプションのテスト
# ==============================================================================

@test "copy-ai-configs.sh: --dry-run で実際のコピーは行われない" {
    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" --dry-run "${TARGET_ROOT}"
    assert_success
    assert_output --partial "DRY-RUN"

    # ファイルがコピーされていないことを確認
    assert_file_not_exist "${TARGET_ROOT}/AGENTS.md"
    assert_dir_not_exist "${TARGET_ROOT}/.claude"
    assert_dir_not_exist "${TARGET_ROOT}/.codex"
    assert_dir_not_exist "${TARGET_ROOT}/.gemini"
}

# ==============================================================================
# 複数プロジェクトのテスト
# ==============================================================================

@test "copy-ai-configs.sh: 複数プロジェクトに同時にコピーできる" {
    local target2="${TEST_DIR}/target-root2"
    mkdir -p "${target2}"

    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" "${TARGET_ROOT}" "${target2}"
    assert_success

    # 両方のターゲットにコピーされていることを確認
    assert_file_exist "${TARGET_ROOT}/AGENTS.md"
    assert_file_exist "${target2}/AGENTS.md"
    assert_dir_exist "${TARGET_ROOT}/.claude"
    assert_dir_exist "${target2}/.claude"
}

# ==============================================================================
# エラーケースのテスト
# ==============================================================================

@test "copy-ai-configs.sh: 引数なしでヘルプが表示される" {
    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}"
    assert_failure
    assert_output --partial "Usage:"
}

@test "copy-ai-configs.sh: 存在しないディレクトリが指定された場合エラーになる" {
    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" "${TEST_DIR}/nonexistent"
    assert_failure
    assert_output --partial "存在しません"
}

@test "copy-ai-configs.sh: ソースルートと同一のパスはスキップされる" {
    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" "${SOURCE_ROOT}"
    assert_success
    assert_output --partial "ソースルートと同一のためスキップ"
}

@test "copy-ai-configs.sh: --help でヘルプが表示される" {
    run bash "${COPY_SCRIPT}" --help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "--force"
    assert_output --partial "--dry-run"
}

# ==============================================================================
# .mcp.json 生成のテスト
# ==============================================================================

@test "copy-ai-configs.sh: .mcp.json が生成される" {
    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" "${TARGET_ROOT}"
    assert_success

    assert_file_exist "${TARGET_ROOT}/.mcp.json"
}

@test "copy-ai-configs.sh: .mcp.json の \${workspaceFolder} がターゲットパスに置換される" {
    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" "${TARGET_ROOT}"
    assert_success

    # ${workspaceFolder} が残っていないことを確認
    run grep -c 'workspaceFolder' "${TARGET_ROOT}/.mcp.json"
    assert_output "0"

    # ターゲットの絶対パスが含まれていることを確認
    run grep -c "${TARGET_ROOT}" "${TARGET_ROOT}/.mcp.json"
    # serena の args に1箇所
    [[ "${output}" -ge 1 ]]
}

@test "copy-ai-configs.sh: .mcp.json に permissions が含まれない" {
    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" "${TARGET_ROOT}"
    assert_success

    run grep -c 'permissions' "${TARGET_ROOT}/.mcp.json"
    assert_output "0"
}

@test "copy-ai-configs.sh: .mcp.json の各サーバーに env が付与される" {
    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" "${TARGET_ROOT}"
    assert_success

    # "env" キーがサーバー数（2つ）分あることを確認
    run grep -c '"env"' "${TARGET_ROOT}/.mcp.json"
    assert_output "2"
}

@test "copy-ai-configs.sh: 既存の .mcp.json はスキップされる" {
    echo '{"existing": true}' > "${TARGET_ROOT}/.mcp.json"

    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" "${TARGET_ROOT}"
    assert_success
    assert_output --partial "既に存在するためスキップしました"

    # 既存の内容が保持されている
    run grep -c 'existing' "${TARGET_ROOT}/.mcp.json"
    assert_output "1"
}

@test "copy-ai-configs.sh: --force で .mcp.json も上書きされる" {
    echo '{"existing": true}' > "${TARGET_ROOT}/.mcp.json"

    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" --force "${TARGET_ROOT}"
    assert_success

    # 新しい内容に上書きされている
    run grep -c 'mcpServers' "${TARGET_ROOT}/.mcp.json"
    assert_output "1"
    run grep -c 'existing' "${TARGET_ROOT}/.mcp.json"
    assert_output "0"
}

@test "copy-ai-configs.sh: --dry-run で .mcp.json は生成されない" {
    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" --dry-run "${TARGET_ROOT}"
    assert_success

    assert_file_not_exist "${TARGET_ROOT}/.mcp.json"
}

@test "copy-ai-configs.sh: settings.local.json がない場合 .mcp.json 生成をスキップする" {
    rm "${SOURCE_ROOT}/.claude/settings.local.json"

    run env AI_CONFIGS_SOURCE_ROOT="${SOURCE_ROOT}" bash "${COPY_SCRIPT}" "${TARGET_ROOT}"
    assert_success

    assert_file_not_exist "${TARGET_ROOT}/.mcp.json"
}

# ==============================================================================
# その他
# ==============================================================================

@test "copy-ai-configs.sh: シンタックスエラーがない" {
    run bash -n "${COPY_SCRIPT}"
    assert_success
}
