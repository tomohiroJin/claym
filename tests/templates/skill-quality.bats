#!/usr/bin/env bats
# =============================================================================
# skill-quality.bats
# Agent Skills テンプレートの品質テスト
# =============================================================================
#
# SKILL.md が Agent Skills オープンスタンダード（agentskills.io）に
# 準拠していることを検証するテスト。
#
# テスト数: 11

# ==============================================================================
# テストヘルパーのロード
# ==============================================================================

load '/usr/local/lib/bats-support/load'
load '/usr/local/lib/bats-assert/load'
load '/usr/local/lib/bats-file/load'
load 'template_test_helper'

# ==============================================================================
# 定数
# ==============================================================================

# 期待されるスキル一覧
#
# コア（開発支援）
EXPECTED_SKILLS=(
    "tdd-workflow" "code-review" "security-review" "search-first"
    "verification-loop" "api-design" "refactor-safely"
    "debug-systematically" "documentation-first" "git-workflow"
    # agent-config ドメイン
    "generate-agent-md" "audit-agent-md"
    # design ドメイン
    "design-review" "design-system"
    # research ドメイン
    "deep-research" "summarize"
    # scenario ドメイン
    "scenario-review" "scenario-write"
    # seo ドメイン
    "seo-audit" "seo-content"
    # stock ドメイン
    "market-check" "stock-analysis"
)

# ==============================================================================
# ディレクトリ・ファイル存在テスト
# ==============================================================================

@test "skills ディレクトリが存在する" {
    assert_dir_exist "${SKILLS_DIR}"
}

@test "全スキルに SKILL.md が存在する" {
    for skill in "${EXPECTED_SKILLS[@]}"; do
        assert_file_exist "${SKILLS_DIR}/${skill}/SKILL.md"
    done
}

@test "全 SKILL.md が非空である" {
    for skill in "${EXPECTED_SKILLS[@]}"; do
        local file="${SKILLS_DIR}/${skill}/SKILL.md"
        assert_file_not_empty "${file}"
    done
}

# ==============================================================================
# YAML フロントマターテスト
# ==============================================================================

@test "全 SKILL.md に YAML フロントマターが存在する" {
    for skill in "${EXPECTED_SKILLS[@]}"; do
        local file="${SKILLS_DIR}/${skill}/SKILL.md"
        # ファイルの先頭が --- で始まること
        run head -1 "${file}"
        assert_output "---"
    done
}

@test "全 SKILL.md に name フィールドが存在する" {
    for skill in "${EXPECTED_SKILLS[@]}"; do
        local file="${SKILLS_DIR}/${skill}/SKILL.md"
        run grep -c "^name:" "${file}"
        assert_output "1"
    done
}

@test "全 SKILL.md に description フィールドが存在する" {
    for skill in "${EXPECTED_SKILLS[@]}"; do
        local file="${SKILLS_DIR}/${skill}/SKILL.md"
        run grep -c "^description:" "${file}"
        assert_output "1"
    done
}

@test "name がディレクトリ名と一致する" {
    for skill in "${EXPECTED_SKILLS[@]}"; do
        local file="${SKILLS_DIR}/${skill}/SKILL.md"
        # YAML フロントマターから name を抽出
        local name_value
        name_value=$(grep "^name:" "${file}" | sed 's/^name: *//')
        if [[ "${name_value}" != "${skill}" ]]; then
            echo "# 不一致: name='${name_value}' != dir='${skill}'" >&3
            return 1
        fi
    done
}

# ==============================================================================
# コンテンツ品質テスト
# ==============================================================================

@test "全 SKILL.md に h1 見出しが存在する" {
    for skill in "${EXPECTED_SKILLS[@]}"; do
        local file="${SKILLS_DIR}/${skill}/SKILL.md"
        run grep -c "^# " "${file}"
        # h1 見出しが1つ以上存在すること
        assert [ "${output}" -ge 1 ]
    done
}

@test "description が1024文字以内である" {
    for skill in "${EXPECTED_SKILLS[@]}"; do
        local file="${SKILLS_DIR}/${skill}/SKILL.md"
        # YAML フロントマターから description を抽出
        local desc
        desc=$(grep "^description:" "${file}" | sed 's/^description: *//')
        local desc_len=${#desc}
        if [[ ${desc_len} -gt 1024 ]]; then
            echo "# description が長すぎます: ${skill} (${desc_len}文字)" >&3
            return 1
        fi
    done
}

@test "実在するスキル数が期待一覧と一致する" {
    # 固定値ではなく EXPECTED_SKILLS と突き合わせる。
    # スキル追加時にテストの更新漏れ（一覧への未登録）を検出できる。
    local count=0
    for dir in "${SKILLS_DIR}"/*/; do
        if [[ -f "${dir}SKILL.md" ]]; then
            count=$((count + 1))
        fi
    done
    assert_equal "${count}" "${#EXPECTED_SKILLS[@]}"
}

@test "README の収録スキル一覧が実態と一致する" {
    # README の一覧に載っていないスキル、および実体の無い一覧行を検出する。
    local readme="${SKILLS_DIR}/README.md"
    local missing_in_readme=()
    local skill

    for skill in "${EXPECTED_SKILLS[@]}"; do
        if ! grep -q "^| \`${skill}\` |" "$readme"; then
            missing_in_readme+=("$skill")
        fi
    done

    if [[ ${#missing_in_readme[@]} -gt 0 ]]; then
        echo "# README に未記載のスキル: ${missing_in_readme[*]}" >&3
        false
    fi

    # 「## 収録スキル一覧」セクション内の行のみを数える
    # （後続の SKILL.md フォーマット表にも同形式の行があるため）
    local readme_count
    readme_count=$(sed -n '/^## 収録スキル一覧$/,/^## /p' "$readme" \
        | grep -cE '^\| `[a-z-]+` \|')
    assert_equal "${readme_count}" "${#EXPECTED_SKILLS[@]}"
}
