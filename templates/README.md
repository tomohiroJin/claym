# AI CLI 設定テンプレート

Claude Code / Codex CLI / Gemini CLI の設定・スキル・ルールのテンプレート集。
`AGENTS.md` を正本とした 3CLI 統一管理を実現します。

## ディレクトリ構造

```
templates/
├── .claude/
│   ├── CLAUDE.md                    # 差分のみ（親の AGENTS.md を継承）
│   ├── agents/                      # エージェント定義（13 YAML）
│   │   ├── architect.yaml
│   │   ├── build-error-resolver.yaml
│   │   ├── code-reviewer.yaml
│   │   ├── context-engineer.yaml
│   │   ├── design-reviewer.yaml
│   │   ├── documentation-writer.yaml
│   │   ├── investment-analyst.yaml
│   │   ├── planner.yaml
│   │   ├── researcher.yaml
│   │   ├── scenario-assistant.yaml
│   │   ├── security-reviewer.yaml
│   │   ├── seo-analyst.yaml
│   │   └── test-generator.yaml
│   ├── commands/                    # カスタムコマンド（11 ファイル）
│   └── rules/                       # ルールファイル（10 ファイル）
├── .codex/
│   ├── AGENTS.md                    # 自己完結型（全コンテキスト内包）
│   ├── instructions/                # ルールファイル（10 ファイル）
│   └── prompts/                     # スラッシュコマンド（34 ファイル）
├── .gemini/
│   ├── GEMINI.md                    # 自己完結型 + @AGENTS.md 参照
│   ├── rules/                       # ルールファイル（10 ファイル）
│   └── commands/                    # スラッシュコマンド（34 ファイル）
├── skills/                          # Agent Skills テンプレート（22 スキル）
└── README.md
```

## 3CLI 統合戦略

### AGENTS.md を正本とする設計

```
AGENTS.md（プロジェクトルート） ← 正本。全 CLI が参照
    │
    ├── .claude/CLAUDE.md     → symlink or 差分のみ記載
    │                           親の AGENTS.md を自動継承
    │
    ├── .codex/AGENTS.md      → 自己完結型コピー
    │                           Codex CLI は階層探索するため全文を内包
    │
    └── .gemini/GEMINI.md     → @AGENTS.md で参照
                                Gemini 固有の差分 + インポート指示
```

### テンプレートの 2 層構造

| CLI | 方式 | 理由 |
|-----|------|------|
| Claude Code | **差分のみ** | `.claude/CLAUDE.md` は MCP 手順等の差分だけ。AGENTS.md + rules/ から自動継承 |
| Codex CLI | **自己完結型** | 階層探索で深い位置が優先されるため、全コンテキストを内包 |
| Gemini CLI | **自己完結型 + @参照** | `@AGENTS.md` インポート + Gemini 固有設定 |

## デプロイ方法

### 自動セットアップ（推奨）

devcontainer 起動時に `scripts/setup/init-ai-configs.sh` が自動実行されます:

- `templates/` から `.claude/`, `.codex/`, `.gemini/` へコピー
- スキルを各 CLI のディスカバリーパスに配置
- `.gitignore` の更新

### 手動セットアップ

```bash
bash scripts/setup/init-ai-configs.sh
```

### テンプレートの再生成

既存設定を上書きしたい場合:

```bash
bash scripts/setup/reinit-ai-configs.sh
```

## スキル一覧（22 スキル）

### コア（開発支援）— 10 スキル

| スキル | 概要 |
|--------|------|
| `search-first` | 実装前にコードベースの既存パターンを調査 |
| `tdd-workflow` | Red-Green-Refactor の TDD サイクル |
| `code-review` | 構造化されたコードレビュー手順 |
| `refactor-safely` | 安全なリファクタリング手順 |
| `verification-loop` | 変更後のビルド・テスト・lint 検証サイクル |
| `debug-systematically` | 体系的デバッグ手法 |
| `security-review` | セキュリティ脆弱性の検出 |
| `api-design` | REST API 設計のベストプラクティス |
| `documentation-first` | ドキュメント駆動開発 |
| `git-workflow` | コミット・ブランチ・PR のベストプラクティス |

### ドメイン拡張 — 6 カテゴリ 12 スキル

| カテゴリ | スキル | 概要 |
|----------|--------|------|
| agent-config | `generate-agent-md` | CLAUDE.md / AGENTS.md / GEMINI.md 一括生成 |
| agent-config | `audit-agent-md` | 既存 Agent.md の品質監査 |
| design | `design-review` | UI/UX デザインレビュー |
| design | `design-system` | デザインシステム構築 |
| research | `deep-research` | 体系的リサーチ（SIFT・CRAAP） |
| research | `summarize` | 構造化された要約生成 |
| scenario | `scenario-review` | ゲームシナリオ品質検証 |
| scenario | `scenario-write` | ゲームシナリオ執筆支援 |
| seo | `seo-audit` | SEO 監査 |
| seo | `seo-content` | SEO コンテンツ最適化 |
| stock | `market-check` | 日次マーケットチェック |
| stock | `stock-analysis` | 銘柄分析 |

### スキルの配置先

| ツール | パス | 呼び出し方 |
|--------|------|-----------|
| Claude Code | `.claude/skills/<name>/SKILL.md` | `/<name>` |
| Codex CLI | `.codex/prompts/<name>.md` | `/prompts:<name>` |
| Gemini CLI | `.gemini/commands/<name>.md` | `/prompts:<name>` |

## エージェント（13 定義、6 ドメイン）

| ドメイン | エージェント |
|----------|-------------|
| コア開発 | `architect`, `code-reviewer`, `test-generator`, `documentation-writer`, `build-error-resolver`, `planner`, `security-reviewer` |
| agent-config | `context-engineer` |
| design | `design-reviewer` |
| research | `researcher` |
| scenario | `scenario-assistant` |
| seo | `seo-analyst` |
| stock | `investment-analyst` |

## ルールファイル（10 ファイル、全 CLI 共通）

### 共通ルール（5 ファイル）

| ファイル | 内容 |
|---------|------|
| `coding-style.md` | 命名規則・TypeScript/React 規約 |
| `git-workflow.md` | コミット・ブランチ・PR 規約 |
| `security.md` | 入力検証・機密情報管理 |
| `testing.md` | テストパターン・カバレッジ目標 |
| `agent-md-conventions.md` | Agent.md 設計規約 |

### ドメイン拡張ルール（5 ファイル）

| ファイル | 内容 |
|---------|------|
| `design-ui-ux-principles.md` | UI/UX デザイン原則 |
| `research-research-methodology.md` | リサーチ方法論 |
| `scenario-scenario-conventions.md` | シナリオ設計規約 |
| `seo-seo-best-practices.md` | SEO ベストプラクティス |
| `stock-investment-discipline.md` | 投資規律 |

## テンプレートのカスタマイズ

### templates-local/ によるオーバーライド

`templates-local/` に同名ファイルを配置すると、公式テンプレートを上書きできます。
`templates-local/` は gitignore 対象のため、個人設定を安全に管理できます。

```
templates-local/
├── .codex/prompts/my-custom.md    # 個人用プロンプト追加
└── .gemini/commands/my-custom.md  # 個人用コマンド追加
```

### local/AI/ によるドメイン拡張

`local/AI/` 配下でドメイン別のスキル・ルール・エージェントを開発し、
symlink で `.claude/skills/` 等に接続します。

```bash
# 例: stock ドメインのスキルを接続
ln -s /workspaces/claym/local/AI/stock/skills/market-check .claude/skills/market-check
```

## テスト

```bash
# テンプレート品質テストのみ実行
bash scripts/test/run-setup-tests.sh templates

# セットアップテストも含む全テスト実行
bash scripts/test/run-setup-tests.sh all
```

テンプレートファイルを追加・変更した場合は、必ずテストを実行してください。

## 参考ドキュメント

- [3CLI 階層構造と境界動作ガイド](../docs/3cli-hierarchy-guide.md) — 各 CLI の境界動作、local/ サブプロジェクトのセットアップ手順
