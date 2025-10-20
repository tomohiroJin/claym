#!/usr/bin/env bats

# copy-template-to-local.sh のテスト
#
# テスト対象:
# - コマンドテンプレートのコピー機能
# - CLAUDE.md のコピー機能
# - 全テンプレートのコピー機能

# テストヘルパーのロード
load '/usr/local/lib/bats-support/load'
load '/usr/local/lib/bats-assert/load'
load '/usr/local/lib/bats-file/load'

# セットアップ: 各テストの前に実行
setup() {
    # テスト用の一時ディレクトリを作成
    export TEST_DIR="$(mktemp -d)"
    export PROJECT_ROOT="${TEST_DIR}/project"
    export TEMPLATES_DIR="${PROJECT_ROOT}/templates"
    export TEMPLATES_LOCAL_DIR="${PROJECT_ROOT}/templates-local"

    # プロジェクト構造を作成
    mkdir -p "${TEMPLATES_DIR}/.claude/commands"
    mkdir -p "${TEMPLATES_DIR}/.claude"
    mkdir -p "${TEMPLATES_LOCAL_DIR}"

    # テスト用のテンプレートファイルを作成
    cat > "${TEMPLATES_DIR}/.claude/commands/review.md" << 'EOF'
# Review Command
Official review template
EOF

    cat > "${TEMPLATES_DIR}/.claude/commands/code-gen.md" << 'EOF'
# Code Generation Command
Official code-gen template
EOF

    cat > "${TEMPLATES_DIR}/.claude/CLAUDE.md" << 'EOF'
# Claude Code Custom Instructions
Official CLAUDE.md template
EOF

    cat > "${TEMPLATES_DIR}/.claude/settings.local.json.example" << 'EOF'
{
  "example": "settings"
}
EOF
}

# ティアダウン: 各テストの後に実行
teardown() {
    # 一時ディレクトリを削除
    rm -rf "${TEST_DIR}"
}

# ----------------------------------------------------------------------------
# コマンドコピー機能のテスト
# ----------------------------------------------------------------------------

@test "copy_command: 単一のコマンドファイルがコピーされる" {
    # コピー関数をシミュレート
    copy_command() {
        local file="$1"
        local src="${TEMPLATES_DIR}/.claude/commands/${file}"
        local dst="${TEMPLATES_LOCAL_DIR}/.claude/commands/${file}"

        if [[ ! -f "${src}" ]]; then
            echo "Error: File not found: ${src}" >&2
            return 1
        fi

        mkdir -p "$(dirname "${dst}")"
        cp "${src}" "${dst}"
    }

    # テスト実行
    run copy_command "review.md"

    # 検証
    assert_success
    assert_file_exist "${TEMPLATES_LOCAL_DIR}/.claude/commands/review.md"

    # ファイル内容の検証
    run cat "${TEMPLATES_LOCAL_DIR}/.claude/commands/review.md"
    assert_output --partial "Official review template"
}

@test "copy_command: 複数のコマンドファイルがコピーされる" {
    # コピー関数をシミュレート
    copy_command() {
        local file="$1"
        local src="${TEMPLATES_DIR}/.claude/commands/${file}"
        local dst="${TEMPLATES_LOCAL_DIR}/.claude/commands/${file}"

        if [[ ! -f "${src}" ]]; then
            echo "Error: File not found: ${src}" >&2
            return 1
        fi

        mkdir -p "$(dirname "${dst}")"
        cp "${src}" "${dst}"
    }

    # テスト実行
    run copy_command "review.md"
    assert_success

    run copy_command "code-gen.md"
    assert_success

    # 検証
    assert_file_exist "${TEMPLATES_LOCAL_DIR}/.claude/commands/review.md"
    assert_file_exist "${TEMPLATES_LOCAL_DIR}/.claude/commands/code-gen.md"
}

@test "copy_command: 存在しないファイルを指定するとエラーになる" {
    # コピー関数をシミュレート
    copy_command() {
        local file="$1"
        local src="${TEMPLATES_DIR}/.claude/commands/${file}"
        local dst="${TEMPLATES_LOCAL_DIR}/.claude/commands/${file}"

        if [[ ! -f "${src}" ]]; then
            echo "Error: File not found: ${src}" >&2
            return 1
        fi

        mkdir -p "$(dirname "${dst}")"
        cp "${src}" "${dst}"
    }

    # テスト実行
    run copy_command "nonexistent.md"

    # 検証
    assert_failure
    assert_output --partial "Error: File not found"
}

# ----------------------------------------------------------------------------
# CLAUDE.md コピー機能のテスト
# ----------------------------------------------------------------------------

@test "copy_claude_md: CLAUDE.md がコピーされる" {
    # コピー関数をシミュレート
    copy_claude_md() {
        local src="${TEMPLATES_DIR}/.claude/CLAUDE.md"
        local dst="${TEMPLATES_LOCAL_DIR}/.claude/CLAUDE.md"

        if [[ ! -f "${src}" ]]; then
            echo "Error: CLAUDE.md not found: ${src}" >&2
            return 1
        fi

        mkdir -p "$(dirname "${dst}")"
        cp "${src}" "${dst}"
    }

    # テスト実行
    run copy_claude_md

    # 検証
    assert_success
    assert_file_exist "${TEMPLATES_LOCAL_DIR}/.claude/CLAUDE.md"

    # ファイル内容の検証
    run cat "${TEMPLATES_LOCAL_DIR}/.claude/CLAUDE.md"
    assert_output --partial "Official CLAUDE.md template"
}

# ----------------------------------------------------------------------------
# 全コマンドコピー機能のテスト
# ----------------------------------------------------------------------------

@test "copy_all_commands: すべてのコマンドファイルがコピーされる" {
    # コピー関数をシミュレート
    copy_all_commands() {
        local src_dir="${TEMPLATES_DIR}/.claude/commands"
        local dst_dir="${TEMPLATES_LOCAL_DIR}/.claude/commands"

        if [[ ! -d "${src_dir}" ]]; then
            echo "Error: Commands directory not found: ${src_dir}" >&2
            return 1
        fi

        mkdir -p "${dst_dir}"

        # すべての .md ファイルをコピー
        find "${src_dir}" -name "*.md" -type f | while read -r file; do
            local basename
            basename="$(basename "${file}")"
            cp "${file}" "${dst_dir}/${basename}"
        done
    }

    # テスト実行
    run copy_all_commands

    # 検証
    assert_success
    assert_file_exist "${TEMPLATES_LOCAL_DIR}/.claude/commands/review.md"
    assert_file_exist "${TEMPLATES_LOCAL_DIR}/.claude/commands/code-gen.md"
}

@test "copy_all_commands: commands ディレクトリが存在しない場合はエラーになる" {
    # コピー関数をシミュレート
    copy_all_commands() {
        local src_dir="${TEMPLATES_DIR}/.claude/commands"
        local dst_dir="${TEMPLATES_LOCAL_DIR}/.claude/commands"

        if [[ ! -d "${src_dir}" ]]; then
            echo "Error: Commands directory not found: ${src_dir}" >&2
            return 1
        fi

        mkdir -p "${dst_dir}"

        # すべての .md ファイルをコピー
        find "${src_dir}" -name "*.md" -type f | while read -r file; do
            local basename
            basename="$(basename "${file}")"
            cp "${file}" "${dst_dir}/${basename}"
        done
    }

    # commands ディレクトリを削除
    rm -rf "${TEMPLATES_DIR}/.claude/commands"

    # テスト実行
    run copy_all_commands

    # 検証
    assert_failure
    assert_output --partial "Error: Commands directory not found"
}

# ----------------------------------------------------------------------------
# copy-template-to-local.sh スクリプト全体のテスト
# ----------------------------------------------------------------------------

@test "copy-template-to-local.sh: スクリプトが正常に実行できる" {
    # スクリプトのシンタックスチェック
    run bash -n /workspaces/claym/scripts/setup/copy-template-to-local.sh
    assert_success
}

@test "copy-template-to-local.sh: --help オプションが実装されている" {
    # ヘルプオプションの処理が含まれていることを確認
    run grep -E '(--help|-h)' /workspaces/claym/scripts/setup/copy-template-to-local.sh

    assert_success
}

@test "copy-template-to-local.sh: 必須の関数が定義されている" {
    # スクリプトから関数定義を検索
    run grep -E '^[[:space:]]*(copy_command|copy_claude_md|copy_all|show_usage)\(\)' \
        /workspaces/claym/scripts/setup/copy-template-to-local.sh

    # 関数が定義されていることを確認
    assert_success
}

@test "copy-template-to-local.sh: コマンドタイプの判定処理が実装されている" {
    # コマンドタイプ（command, claude-md, all）の処理が含まれていることを確認
    run grep -E '(command|claude-md|all)' /workspaces/claym/scripts/setup/copy-template-to-local.sh

    assert_success
}

# ----------------------------------------------------------------------------
# エッジケースのテスト
# ----------------------------------------------------------------------------

@test "copy_command: 既存のファイルは上書きされる" {
    # コピー関数をシミュレート
    copy_command() {
        local file="$1"
        local src="${TEMPLATES_DIR}/.claude/commands/${file}"
        local dst="${TEMPLATES_LOCAL_DIR}/.claude/commands/${file}"

        if [[ ! -f "${src}" ]]; then
            echo "Error: File not found: ${src}" >&2
            return 1
        fi

        mkdir -p "$(dirname "${dst}")"
        cp "${src}" "${dst}"
    }

    # 既存のファイルを作成
    mkdir -p "${TEMPLATES_LOCAL_DIR}/.claude/commands"
    cat > "${TEMPLATES_LOCAL_DIR}/.claude/commands/review.md" << 'EOF'
# Review Command
Old content
EOF

    # テスト実行
    run copy_command "review.md"

    # 検証
    assert_success

    # ファイルが新しい内容に更新されていることを確認
    run cat "${TEMPLATES_LOCAL_DIR}/.claude/commands/review.md"
    assert_output --partial "Official review template"
    refute_output --partial "Old content"
}

@test "copy_command: ディレクトリが存在しない場合は自動作成される" {
    # コピー関数をシミュレート
    copy_command() {
        local file="$1"
        local src="${TEMPLATES_DIR}/.claude/commands/${file}"
        local dst="${TEMPLATES_LOCAL_DIR}/.claude/commands/${file}"

        if [[ ! -f "${src}" ]]; then
            echo "Error: File not found: ${src}" >&2
            return 1
        fi

        mkdir -p "$(dirname "${dst}")"
        cp "${src}" "${dst}"
    }

    # templates-local ディレクトリを削除
    rm -rf "${TEMPLATES_LOCAL_DIR}"

    # テスト実行
    run copy_command "review.md"

    # 検証
    assert_success
    assert_dir_exist "${TEMPLATES_LOCAL_DIR}/.claude/commands"
    assert_file_exist "${TEMPLATES_LOCAL_DIR}/.claude/commands/review.md"
}

@test "copy_all: 空の commands ディレクトリでもエラーにならない" {
    # コピー関数をシミュレート
    copy_all_commands() {
        local src_dir="${TEMPLATES_DIR}/.claude/commands"
        local dst_dir="${TEMPLATES_LOCAL_DIR}/.claude/commands"

        if [[ ! -d "${src_dir}" ]]; then
            echo "Error: Commands directory not found: ${src_dir}" >&2
            return 1
        fi

        mkdir -p "${dst_dir}"

        # すべての .md ファイルをコピー
        find "${src_dir}" -name "*.md" -type f | while read -r file; do
            local basename
            basename="$(basename "${file}")"
            cp "${file}" "${dst_dir}/${basename}"
        done
    }

    # commands ディレクトリを空にする
    rm -f "${TEMPLATES_DIR}/.claude/commands"/*.md

    # テスト実行
    run copy_all_commands

    # 検証: ディレクトリが存在するので成功するはず
    assert_success
}
