# 3CLI 階層構造と境界動作ガイド

Claude Code / Codex CLI / Gemini CLI がコンテキストファイルをどのように発見・読み込むかの
詳細ガイド。local/ サブプロジェクトのセットアップ手順を含む。

---

## 1. 各 CLI の境界動作

### Claude Code

**探索方式**: CWD から **ファイルシステムルート `/` まで** 無条件に上方走査。

- `.git` 境界は **無視される**（[#16600](https://github.com/anthropics/claude-code/issues/16600)）
- 全ての祖先ディレクトリの `CLAUDE.md` と `.claude/rules/*.md` を連結読み込み
- サブディレクトリの `CLAUDE.md` はオンデマンド（ファイル操作時）に読み込み

```
/workspaces/claym/local/foo/ で起動した場合の読み込み順:

1. ~/.claude/CLAUDE.md                      ← グローバル（言語設定）
2. ~/.claude/rules/*.md                     ← グローバルルール
3. /workspaces/claym/CLAUDE.md              ← symlink → AGENTS.md（正本）
4. /workspaces/claym/.claude/CLAUDE.md      ← claym 固有差分（MCP詳細）
5. /workspaces/claym/.claude/rules/*.md     ← claym ルール（10ファイル）
6. /workspaces/claym/local/foo/CLAUDE.md    ← サブプロジェクト（あれば）
7. /workspaces/claym/local/foo/.claude/CLAUDE.md  ← サブプロジェクト固有
8. /workspaces/claym/local/foo/.claude/rules/*.md ← サブプロジェクトルール
```

**結論**: local/ サブプロジェクトに `.git` があっても、claym の全設定が自動継承される。
サブプロジェクトの CLAUDE.md は**差分のみ**で良い。rules/ のコピーも不要（claym のものが継承される）。

> **出典**: [Claude Code Memory ドキュメント](https://code.claude.com/docs/en/memory),
> [Issue #26944](https://github.com/anthropics/claude-code/issues/26944),
> [Issue #34209](https://github.com/anthropics/claude-code/issues/34209)

---

### Codex CLI

**探索方式**: CWD から上方向に `.git` を探し、そこを **project root** とする。
project root から CWD まで下方向に各ディレクトリ1ファイルずつ連結。

- `.git` が project root の境界（**最初に見つかった `.git` で停止**）
- 各ディレクトリで `AGENTS.override.md` > `AGENTS.md` > フォールバック名 の順で1つだけ選択
- 32 KiB（デフォルト）の累積サイズ制限あり
- `~/.codex/AGENTS.md` はグローバルレベルとして別途読み込み

```
/workspaces/claym/local/foo/ (.git あり) で起動した場合:

project root = /workspaces/claym/local/foo/ （ここに .git があるため）

読み込み:
1. ~/.codex/AGENTS.md                       ← グローバル
2. /workspaces/claym/local/foo/AGENTS.md    ← project root（唯一の候補）

※ /workspaces/claym/AGENTS.md は探索範囲外！
```

**結論**: `.git` 境界により claym の AGENTS.md は**継承されない**。
サブプロジェクトの AGENTS.md は**自己完結型**（全コンテキスト内包）が必要。

> **出典**: [Codex AGENTS.md ガイド](https://developers.openai.com/codex/guides/agents-md),
> ソースコード `codex-rs/core/src/project_doc.rs`,
> [Issue #12128](https://github.com/openai/codex/issues/12128)

---

### Gemini CLI

**探索方式**: CWD から上方向に `.git` を探し、そこを project root とする。
初回ロードは **project root の1つ上のディレクトリまで** 探索。JIT は project root で停止。

- `context.memoryBoundaryMarkers`（デフォルト: `[".git"]`）で境界を制御
- `context.fileName`（デフォルト: `"GEMINI.md"`）で探索するファイル名を設定
- `@ファイル名` インポート構文は **GEMINI.md の所在ディレクトリ基準** で解決
- symlink は**フォローしない**（[#11547](https://github.com/google-gemini/gemini-cli/issues/11547)）

```
/workspaces/claym/local/foo/ (.git あり) で起動した場合:

project root = /workspaces/claym/local/foo/
ultimateStopDir = /workspaces/claym/local/  （project root の親）

初回ロード探索範囲:
  /workspaces/claym/local/foo/ → /workspaces/claym/local/
  ※ /workspaces/claym/ には到達しない

読み込み:
1. ~/.gemini/GEMINI.md                      ← グローバル
2. /workspaces/claym/local/foo/GEMINI.md    ← サブプロジェクト
   （@AGENTS.md があれば foo/AGENTS.md をインポート）

※ /workspaces/claym/GEMINI.md は探索範囲外！
```

**結論**: `.git` 境界により claym の設定は**継承されない**。
サブプロジェクトは `GEMINI.md` + `@AGENTS.md`（ローカルの AGENTS.md をインポート）で自己完結させる。

> **出典**: ソースコード `packages/core/src/utils/memoryDiscovery.ts`,
> [Issue #11547](https://github.com/google-gemini/gemini-cli/issues/11547)

---

## 2. 境界動作の比較表

| 項目 | Claude Code | Codex CLI | Gemini CLI |
|------|:----------:|:---------:|:----------:|
| **上方走査の境界** | なし（`/` まで） | 最初の `.git` | `.git` の1つ上まで |
| **`.git` を跨ぐか** | **跨ぐ** | 跨がない | 跨がない |
| **親の設定を継承するか** | **常に継承** | `.git` がなければ継承 | `.git` がなければ継承 |
| **サイズ制限** | なし | 32 KiB | なし |
| **symlink 対応** | 対応 | 対応 | **非対応** |
| **ファイル名設定** | 固定 (`CLAUDE.md`) | `project_doc_fallback_filenames` | `context.fileName` |
| **境界カスタマイズ** | `claudeMdExcludes` | `project_root_markers` | `memoryBoundaryMarkers` |

---

## 3. claym 環境での動作まとめ

### CLAYM ルートで起動（`/workspaces/claym/`）

全 CLI が完結動作。特別な設定は不要。

| CLI | 読み込まれるコンテキスト |
|-----|----------------------|
| Claude Code | `~/.claude/CLAUDE.md` + `CLAUDE.md`(→AGENTS.md) + `.claude/CLAUDE.md` + `.claude/rules/*` |
| Codex CLI | `~/.codex/AGENTS.md` + `AGENTS.md` |
| Gemini CLI | `~/.gemini/GEMINI.md` + `AGENTS.md`(settings.json) + `.gemini/GEMINI.md`(@AGENTS.md) |

### local/ サブプロジェクトで起動（`.git` あり）

| CLI | claym 設定の継承 | 必要な対応 |
|-----|:--------------:|----------|
| **Claude Code** | **自動継承** | サブプロジェクトの `.claude/CLAUDE.md` に差分のみ記載 |
| **Codex CLI** | **継承されない** | `AGENTS.md` を自己完結型で配置 |
| **Gemini CLI** | **継承されない** | `GEMINI.md`（`@AGENTS.md` インポート付き）を配置 |

---

## 4. local/ サブプロジェクトのセットアップ手順

### 前提

- サブプロジェクトは `local/<project>/` に作成
- 独自の `.git` を持つ（`git init` 済み）
- claym のテンプレート（`templates/`）を元に設定

### 手順

#### Step 1: テンプレートから設定をコピー

```bash
cd /workspaces/claym/local/<project>

# Codex CLI 用: AGENTS.md をプロジェクトルートに配置（自己完結型）
cp /workspaces/claym/templates/.codex/AGENTS.md ./AGENTS.md
# → プレースホルダー（<プロジェクト名> 等）を書き換え

# Claude Code 用: 差分のみの CLAUDE.md
mkdir -p .claude
cp /workspaces/claym/templates/.claude/CLAUDE.md .claude/CLAUDE.md
# → プロジェクト固有の差分を記載（claym の設定は自動継承される）

# Gemini CLI 用: GEMINI.md + @AGENTS.md インポート
mkdir -p .gemini
cp /workspaces/claym/templates/.gemini/GEMINI.md .gemini/GEMINI.md
# → 冒頭に @AGENTS.md を追加（ローカルの AGENTS.md をインポート）
```

#### Step 2: Gemini CLI の GEMINI.md に @AGENTS.md インポートを追加

```markdown
# <プロジェクト名> — Gemini CLI 固有指示

@AGENTS.md

> 上記で AGENTS.md をインポート済み。以下は Gemini CLI 固有の指示のみ。
...
```

#### Step 3: CLAUDE.md symlink の作成（任意）

Claude Code は親の AGENTS.md を自動継承するため、サブプロジェクトルートの
CLAUDE.md symlink は**任意**。Codex CLI が AGENTS.md を読むので、
Claude Code 用に CLAUDE.md → AGENTS.md の symlink を張ると統一感が出る。

```bash
ln -s AGENTS.md CLAUDE.md
```

#### Step 4: ルールファイルのコピー

```bash
# Claude Code: 親から自動継承されるためコピー不要
# ただし、サブプロジェクト固有のルールを追加する場合は:
cp -r /workspaces/claym/templates/.claude/rules .claude/rules

# Codex CLI: 必要に応じて
mkdir -p .codex/instructions
cp /workspaces/claym/templates/.codex/instructions/*.md .codex/instructions/

# Gemini CLI: 必要に応じて
mkdir -p .gemini/rules
cp /workspaces/claym/templates/.gemini/rules/*.md .gemini/rules/
```

#### Step 5: Gemini CLI の settings.json 設定

```bash
cat > .gemini/settings.json << 'EOF'
{
  "context": {
    "fileName": ["AGENTS.md", ".gemini/GEMINI.md"]
  }
}
EOF
```

#### Step 6: AGENTS.md のカスタマイズ

コピーした `AGENTS.md` のプレースホルダーを書き換え:

```markdown
# <プロジェクト名> — <技術スタック概要>

## プロジェクトの性格
<プロジェクトの一言説明>

## ディレクトリ構造（意味論）
<実際のディレクトリ構造>
...
```

MCP一覧・権限三層構造・ルールファイル一覧は claym 共通値がテンプレートに固定されている。

---

## 5. テンプレートの設計思想

### なぜ Claude Code テンプレートは差分のみか

Claude Code は `.git` 境界を無視して親ディレクトリを全て走査する。
local/ サブプロジェクトから起動しても、claym の AGENTS.md（symlink 経由）と
`.claude/rules/*.md` が自動的に読み込まれる。

そのため、テンプレートにはサブプロジェクト固有の差分（MCP 詳細手順、スキル参照）のみ記載。

### なぜ Codex / Gemini テンプレートは自己完結型か

Codex CLI と Gemini CLI は `.git` 境界で探索を停止する。
local/ サブプロジェクトに `.git` がある場合、claym の AGENTS.md は見えない。

そのため、テンプレートには全コンテキスト（言語設定、MCP一覧、権限構造等）を内包。

### なぜ Gemini は @AGENTS.md インポートを使うか

Gemini CLI は GEMINI.md の symlink をフォローしない（セキュリティ上の制約）。
代わりに `@AGENTS.md` インポート構文で同ディレクトリの AGENTS.md を参照し、
GEMINI.md 自体には Gemini 固有の差分のみ記載する。

---

## 6. 注意事項

### Claude Code の親ディレクトリ走査

Claude Code は親の全ルールを継承するため、claym に 10 個のルールファイルがある場合、
サブプロジェクトでも全て読み込まれる。不要なルールが多い場合は `claudeMdExcludes` で除外可能:

```json
{
  "claudeMdExcludes": [
    "/workspaces/claym/.claude/rules/stock-*",
    "/workspaces/claym/.claude/rules/scenario-*"
  ]
}
```

### Codex CLI の 32 KiB 制限

Codex CLI は全ドキュメントの合計が 32 KiB（デフォルト）を超えると切り捨てる。
`~/.codex/AGENTS.md`（201行）+ サブプロジェクトの `AGENTS.md` が合計で収まるよう注意。

### Gemini CLI の symlink 非対応

Gemini CLI は GEMINI.md や AGENTS.md が symlink の場合、読み込まない。
必ず実ファイルまたは `@` インポート構文を使用すること。
