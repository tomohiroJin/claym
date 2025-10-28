#!/usr/bin/env bash
# 共通テストヘルパー関数
#
# このファイルは、セットアップスクリプトのテストで使用される
# 共通のヘルパー関数を提供します。

# ==============================================================================
# 定数定義
# ==============================================================================

# テストコンテンツ定数
readonly TEST_OFFICIAL_TEMPLATE_CONTENT="# Test Command 1
Official template content"

readonly TEST_OFFICIAL_TEMPLATE2_CONTENT="# Test Command 2
Official template content"

readonly TEST_LOCAL_TEMPLATE_CONTENT="# Test Command 1
Local template content (overridden)"

readonly TEST_CUSTOM_TEMPLATE_CONTENT="# Custom Command
This is a custom local template"

readonly TEST_RESTORED_CONTENT="# Restored Command
Restored content"

readonly TEST_RESTORED_CUSTOM_CONTENT="# Restored Custom Command
Restored custom content"

# ==============================================================================
# ディレクトリ構築ヘルパー
# ==============================================================================

# 標準的なテストディレクトリ構造を作成
#
# グローバル変数:
#   TEST_DIR, PROJECT_ROOT, TEMPLATES_DIR, TEMPLATES_LOCAL_DIR
#
create_standard_test_directories() {
    export TEST_DIR="$(mktemp -d)"
    export PROJECT_ROOT="${TEST_DIR}/project"
    export TEMPLATES_DIR="${PROJECT_ROOT}/templates"
    export TEMPLATES_LOCAL_DIR="${PROJECT_ROOT}/templates-local"

    mkdir -p "${PROJECT_ROOT}"
    mkdir -p "${TEMPLATES_DIR}/.claude/commands"
    mkdir -p "${TEMPLATES_LOCAL_DIR}/.claude/commands"
}

# バックアップ用のテストディレクトリ構造を作成
#
# グローバル変数:
#   TEST_DIR, PROJECT_ROOT, BACKUP_DIR
#
create_backup_test_directories() {
    export TEST_DIR="$(mktemp -d)"
    export PROJECT_ROOT="${TEST_DIR}/project"
    export BACKUP_DIR="${TEST_DIR}/backup"

    mkdir -p "${PROJECT_ROOT}/.claude/commands"
    mkdir -p "${PROJECT_ROOT}/templates-local/.claude/commands"
}

# ==============================================================================
# ファイル作成ヘルパー
# ==============================================================================

# 公式テンプレートファイルを作成
#
# 引数:
#   $1 - ベースディレクトリ（デフォルト: TEMPLATES_DIR）
#
create_official_template_files() {
    local base_dir="${1:-${TEMPLATES_DIR}}"

    cat > "${base_dir}/.claude/commands/test1.md" <<EOF
${TEST_OFFICIAL_TEMPLATE_CONTENT}
EOF

    cat > "${base_dir}/.claude/commands/test2.md" <<EOF
${TEST_OFFICIAL_TEMPLATE2_CONTENT}
EOF
}

# ローカルテンプレートファイルを作成（上書き用）
#
# 引数:
#   $1 - ベースディレクトリ（デフォルト: TEMPLATES_LOCAL_DIR）
#
create_local_override_template() {
    local base_dir="${1:-${TEMPLATES_LOCAL_DIR}}"

    cat > "${base_dir}/.claude/commands/test1.md" <<EOF
${TEST_LOCAL_TEMPLATE_CONTENT}
EOF
}

# カスタムローカルテンプレートファイルを作成
#
# 引数:
#   $1 - ベースディレクトリ（デフォルト: TEMPLATES_LOCAL_DIR）
#
create_custom_local_template() {
    local base_dir="${1:-${TEMPLATES_LOCAL_DIR}}"

    cat > "${base_dir}/.claude/commands/custom.md" <<EOF
${TEST_CUSTOM_TEMPLATE_CONTENT}
EOF
}

# バックアップ用のテストファイルを作成
#
create_backup_test_files() {
    cat > "${PROJECT_ROOT}/.claude/commands/test.md" <<EOF
# Test Command
Test content
EOF

    cat > "${PROJECT_ROOT}/templates-local/.claude/commands/custom.md" <<EOF
# Custom Command
Custom content
EOF
}

# リストア用のバックアップファイルを作成
#
# 引数:
#   $1 - バックアップディレクトリ
#
create_restore_backup_files() {
    local backup_dir="$1"

    mkdir -p "${backup_dir}/.claude/commands"
    cat > "${backup_dir}/.claude/commands/restored.md" <<EOF
${TEST_RESTORED_CONTENT}
EOF
}

# リストア用のカスタムバックアップファイルを作成
#
# 引数:
#   $1 - バックアップディレクトリ
#
create_restore_custom_backup_files() {
    local backup_dir="$1"

    mkdir -p "${backup_dir}/templates-local/.claude/commands"
    cat > "${backup_dir}/templates-local/.claude/commands/restored-custom.md" <<EOF
${TEST_RESTORED_CUSTOM_CONTENT}
EOF
}

# ==============================================================================
# 関数定義ヘルパー（テスト対象関数のシミュレーション）
# ==============================================================================

# merge_templates 関数を定義
#
# この関数は init-ai-configs.sh の merge_templates 関数を
# テスト用にシミュレートします。
#
define_merge_templates_function() {
    merge_templates() {
        local target_subdir="$1"
        local official_template="${TEMPLATES_DIR}/${target_subdir}"
        local local_template="${TEMPLATES_LOCAL_DIR}/${target_subdir}"
        local destination="${PROJECT_ROOT}/${target_subdir}"

        # 1. 公式テンプレートをコピー
        if [[ -d "${official_template}" ]]; then
            mkdir -p "${destination}"
            shopt -s dotglob
            cp -r "${official_template}/"* "${destination}/" 2>/dev/null || true
            shopt -u dotglob
        fi

        # 2. ローカルテンプレートで上書き（存在する場合）
        if [[ -d "${local_template}" ]]; then
            shopt -s dotglob
            cp -r "${local_template}/"* "${destination}/" 2>/dev/null || true
            shopt -u dotglob
        fi
    }
}

# restore_directory 関数を定義
#
# この関数は reinit-ai-configs.sh の restore_directory 関数を
# テスト用にシミュレートします。
#
define_restore_directory_function() {
    restore_directory() {
        local src="$1"
        local dst="$2"

        if [[ -d "${src}" ]]; then
            mkdir -p "${dst}"
            shopt -s dotglob
            cp -r "${src}/"* "${dst}/" 2>/dev/null || true
            shopt -u dotglob
        fi
    }
}

# backup_directory 関数を定義
#
# この関数はバックアップ機能をテスト用にシミュレートします。
#
define_backup_directory_function() {
    backup_directory() {
        local src="$1"
        local dst="$2"

        if [[ -d "${src}" ]]; then
            mkdir -p "$(dirname "${dst}")"
            cp -r "${src}" "${dst}"
        fi
    }
}

# backup_files 関数を定義
#
# この関数はバックアップディレクトリ作成をシミュレートします。
#
define_backup_files_function() {
    backup_files() {
        local backup_base="$1"
        mkdir -p "${backup_base}"
    }
}

# ==============================================================================
# アサーションヘルパー
# ==============================================================================

# 公式テンプレートファイルが存在することを検証
#
assert_official_template_files_exist() {
    assert_file_exist "${PROJECT_ROOT}/.claude/commands/test1.md"
    assert_file_exist "${PROJECT_ROOT}/.claude/commands/test2.md"
}

# 公式テンプレートの内容を検証
#
assert_official_template_content() {
    local file="$1"
    run cat "${file}"
    assert_output --partial "Official template content"
}

# ローカルテンプレートの内容を検証
#
assert_local_template_content() {
    local file="$1"
    run cat "${file}"
    assert_output --partial "Local template content (overridden)"
    refute_output --partial "Official template content"
}

# カスタムテンプレートの内容を検証
#
assert_custom_template_content() {
    local file="$1"
    run cat "${file}"
    assert_output --partial "This is a custom local template"
}

# ==============================================================================
# copy-template-to-local 用のヘルパー
# ==============================================================================

# copy-template-to-local 用のディレクトリ構造を作成
#
create_copy_template_test_directories() {
    export TEST_DIR="$(mktemp -d)"
    export PROJECT_ROOT="${TEST_DIR}/project"
    export TEMPLATES_DIR="${PROJECT_ROOT}/templates"
    export TEMPLATES_LOCAL_DIR="${PROJECT_ROOT}/templates-local"

    mkdir -p "${TEMPLATES_DIR}/.claude/commands"
    mkdir -p "${TEMPLATES_DIR}/.claude"
    mkdir -p "${TEMPLATES_LOCAL_DIR}"
}

# copy-template-to-local 用のテンプレートファイルを作成
#
create_copy_template_files() {
    cat > "${TEMPLATES_DIR}/.claude/commands/review.md" <<'EOF'
# Review Command
Official review template
EOF

    cat > "${TEMPLATES_DIR}/.claude/commands/code-gen.md" <<'EOF'
# Code Generation Command
Official code-gen template
EOF

    cat > "${TEMPLATES_DIR}/.claude/CLAUDE.md" <<'EOF'
# Claude Code Custom Instructions
Official CLAUDE.md template
EOF

    cat > "${TEMPLATES_DIR}/.claude/settings.local.json.example" <<'EOF'
{
  "example": "settings"
}
EOF
}

# copy_command 関数を定義
#
define_copy_command_function() {
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
}

# copy_claude_md 関数を定義
#
define_copy_claude_md_function() {
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
}

# copy_all_commands 関数を定義
#
define_copy_all_commands_function() {
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
}

# ==============================================================================
# エージェント関連ヘルパー
# ==============================================================================

# エージェントテンプレートファイルを作成
#
# 引数:
#   $1 - ベースディレクトリ（デフォルト: TEMPLATES_DIR）
#
create_agent_template_files() {
    local base_dir="${1:-${TEMPLATES_DIR}}"

    mkdir -p "${base_dir}/.claude/agents"

    # code-reviewer.yaml
    cat > "${base_dir}/.claude/agents/code-reviewer.yaml" <<'EOF'
name: "code-reviewer"
description: "Test code reviewer"
version: "1.0"
prompt: |
  Test prompt
tools:
  - Read
mode: "thorough"
EOF

    # test-generator.yaml
    cat > "${base_dir}/.claude/agents/test-generator.yaml" <<'EOF'
name: "test-generator"
description: "Test generator"
version: "1.0"
prompt: |
  Test prompt
tools:
  - Write
mode: "balanced"
EOF

    # documentation-writer.yaml
    cat > "${base_dir}/.claude/agents/documentation-writer.yaml" <<'EOF'
name: "documentation-writer"
description: "Test documentation writer"
version: "1.0"
prompt: |
  Test prompt
tools:
  - Edit
mode: "comprehensive"
EOF
}

# setup_claude_agents 関数を定義（テスト用）
#
define_setup_claude_agents_function() {
    # common.sh から必要な関数を読み込み
    source /workspaces/claym/scripts/setup/common.sh

    # setup_claude_agents 関数を定義
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
}

# エージェントファイルの存在を検証
#
assert_agent_files_exist() {
    local agents_dir="$1"

    assert_file_exist "${agents_dir}/code-reviewer.yaml"
    assert_file_exist "${agents_dir}/test-generator.yaml"
    assert_file_exist "${agents_dir}/documentation-writer.yaml"
}

# ==============================================================================
# クリーンアップヘルパー
# ==============================================================================

# 標準的なクリーンアップ処理
#
cleanup_test_directory() {
    rm -rf "${TEST_DIR}"
}
