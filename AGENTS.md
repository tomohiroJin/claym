# claym — MCP 駆動の個人開発サンドボックス（Bash/Python/TypeScript）

## プロジェクトの性格

**実験・プロトタイピング用のワークベンチ。** 単一のプロダクトではない。
MCP サーバーと AI CLI（Claude Code / Codex CLI / Gemini CLI）を駆使して、
新しいツール・技術の試行、スキル開発、ドキュメント管理を行うプラットフォーム。

- 本格的な開発は `local/` 配下の個別プロジェクトで実施
- ルートでは試行錯誤・テンプレート管理・AI 拡張の整備が中心

## ディレクトリ構造（意味論）

```
claym/
├── local/              # gitignore。個別プロジェクト群（各自の CLAUDE.md を持つ）
│   ├── AI/             # スキル・ルール・エージェントの拡張キット（6ドメイン）
│   │   ├── agent-config/  # Agent.md 生成・監査スキル
│   │   ├── design/        # UI/UX デザインレビュー・デザインシステム
│   │   ├── research/      # 体系的リサーチ・要約
│   │   ├── scenario/      # ゲームシナリオ執筆・レビュー
│   │   ├── seo/           # SEO 監査・コンテンツ最適化
│   │   └── stock/         # 市場分析・銘柄分析
│   └── <各種実験プロジェクト>/
├── templates/          # git 追跡。3 CLI 設定のテンプレート（共有用）
│   ├── .claude/        # Claude Code テンプレート
│   ├── .codex/         # Codex CLI テンプレート
│   ├── .gemini/        # Gemini CLI テンプレート
│   └── skills/         # スキルテンプレート
├── scripts/            # ユーティリティスクリプト
├── docs/               # プロジェクトドキュメント
├── .docs/              # 内部ドキュメント管理
└── tests/              # テスト
```

**重要**: `.claude/`, `.codex/`, `.gemini/`, `local/` は gitignore 対象。
共有したい設定は `templates/` に配置し、ローカルにコピーまたは symlink する。

## テンプレート → ローカル デプロイの流れ

1. `templates/` で共有テンプレートを作成・更新
2. `local/AI/` のドメイン別スキルを開発
3. `.claude/skills/` 等へ symlink で接続（例: `ln -s /workspaces/claym/local/AI/stock/skills/market-check`）
4. `.claude/rules/`, `.codex/instructions/`, `.gemini/rules/` にルールを配置

## MCP サーバー一覧と用途

| MCP サーバー | 用途 | 使い分け |
|-------------|------|---------|
| **serena** | シンボリックコード操作 | 構造理解・シンボル単位の編集に優先使用 |
| **context7** | ライブラリドキュメント参照 | API 仕様が不明な場合に必ず使用 |
| **filesystem** | ファイル・ディレクトリ操作 | 非コードファイルの読み書き |
| **playwright** | ブラウザ自動操作 | Web アプリのテスト・スクリーンショット |
| **markitdown** | ドキュメント変換 | PDF/Office → Markdown 変換 |
| **imagesorcery** | 画像処理 | リサイズ・OCR・メタ情報取得 |
| **github** | GitHub API 操作 | Issue/PR の操作 |
| **git** | Git 操作 | リポジトリの状態確認・操作 |
| **memory** | 知識グラフ | セッション横断の情報保持 |
| **sequential-thinking** | 段階的推論 | 複雑な問題の分解 |
| **fetch** | HTTP リクエスト | 外部 API・Web ページの取得 |

## コーディング規約

**詳細は `rules/` を参照。** ここでは rules/ に書けない暗黙知のみ記載:

- このリポジトリは多言語（Bash/Python/TypeScript）— 各サブプロジェクトの言語に合わせる
- `local/` 配下は独立プロジェクト。ルートの規約を強制しない
- テンプレートファイルは汎用性を保つ（特定プロジェクト固有のロジックを入れない）
- スキル定義（`skills/*/SKILL.md`）は他プロジェクトでも再利用可能な形で書く

## 権限の三層構造

### Always do（常に実行）
- 変更前に既存コードを読んで理解する
- `rules/` の該当規約を確認してから作業する
- MCP ツールの中で最適なものを選択して使用する

### Ask first（確認してから実行）
- `templates/` 配下の共有テンプレートの変更
- 新しいスキル・ルールファイルの追加
- `.gitignore` パターンの変更
- symlink の作成・変更

### Never do（絶対禁止）
- `local/` 配下のプロジェクトを git 追跡に含めない
- API キー・トークン等の機密情報をコミットしない
- `main` への `--force` プッシュ
- 他人の `local/` ディレクトリ構造を前提としたコードを書かない

## 地雷マップ

- `'Log file: '` — 名前にスペースを含むディレクトリが存在（過去の事故の産物）。触らない
- `tmux-*.log` — 大容量ログ（数百KB〜1MB）。読み込み禁止

## ルールファイル一覧

CLI ごとのパス: `.claude/rules/` / `.codex/instructions/`（Gemini は利用停止。`.gemini/rules/` は残置のみ）

### 共通ルール（Claude / Codex に同期）

| ファイル | 内容 |
|---------|------|
| `coding-style.md` | 命名規則・TypeScript/React 規約 |
| `git-workflow.md` | コミット・ブランチ・PR 規約 |
| `security.md` | 入力検証・機密情報管理・通信セキュリティ |
| `testing.md` | テストパターン・カバレッジ目標 |
| `agent-config-agent-md-conventions.md` | Agent.md 設計規約 |

### ドメイン拡張ルール（Claude / Codex に同期）

| ファイル | 内容 |
|---------|------|
| `design-ui-ux-principles.md` | UI/UX デザイン原則 |
| `research-research-methodology.md` | 体系的リサーチ手法 |
| `scenario-scenario-conventions.md` | ゲームシナリオ執筆規約 |
| `seo-seo-best-practices.md` | SEO ベストプラクティス |
| `stock-investment-discipline.md` | 投資分析の規律 |
| `translation-translation-principles.md` | 英日翻訳の原則 |

### プロジェクト限定ルール（Claude のみ・`local/` スコープ）

| ファイル | 内容 |
|---------|------|
| `kamishibai-presentation.md` | 紙芝居動画の見せ方・掴みの鉄則 |
| `kamishibai-production.md` | 紙芝居動画制作の必須ゲート |
