
# Agent.md 一括生成スキル

プロジェクトを解析し、Claude Code / Codex CLI / Gemini CLI の3つの AI CLI に対応した設定ファイルを生成します。

> `/init` の自動生成を超える、暗黙知を含んだ高品質な Agent.md を目指します。


## 1. プロジェクト解析フェーズ

以下の順序でプロジェクトの情報を収集する。

### 1.1 基本構造の特定

```
1. Glob でプロジェクトルートのファイル一覧を取得
2. 以下のファイルを優先的に Read する:
   - package.json / Cargo.toml / go.mod / pyproject.toml / Gemfile（言語・依存関係）
   - Makefile / Justfile / Taskfile.yml（ビルドコマンド）
   - Dockerfile / docker-compose.yml（実行環境）
   - .github/workflows/*.yml（CI/CD）
   - tsconfig.json / .eslintrc* / .prettierrc*（コード規約）
   - .env.example（環境変数）
3. Grep でテストフレームワーク（jest, vitest, pytest, go test 等）を特定
4. ディレクトリ構造の意味論的な役割を推定
```

### 1.2 暗黙知の抽出（/init では取れない情報）

ユーザーに以下を確認する（$ARGUMENTS で渡されていなければ質問する）:

- **アーキテクチャの特殊事情**: モノレポ構成か、マイクロサービスか、特殊な依存関係はあるか
- **触ってはいけないファイル/ディレクトリ**: レガシーコード、自動生成ファイル、ロック対象
- **チーム固有の規約**: リンターでカバーできない暗黙のルール
- **技術的負債の地雷**: 「このファイルはこういう事情で特殊な実装になっている」
- **Git ワークフロー**: ブランチ戦略、コミットメッセージ規約、PR テンプレート
- **セキュリティ境界**: 機密ファイル、API キーの管理方法、認証の仕組み

### 1.3 既存設定の確認

```
1. .claude/ ディレクトリの有無と内容
2. .codex/ ディレクトリの有無と内容
3. .gemini/ ディレクトリの有無と内容
4. 既存の CLAUDE.md / AGENTS.md / GEMINI.md の有無
5. 既存の rules/ や skills/ の内容
```


## 2. 生成フェーズ

### 2.1 共通コンテンツの設計

3つの CLI で共通するコンテンツを先に設計する。以下の構成要素を含む:

| セクション | 内容 | 行数目安 |
|-----------|------|---------|
| プロジェクト概要 | 名前、目的、技術スタック（1行目に凝縮） | 3-5行 |
| ディレクトリ構造 | 意味論的な役割の説明（自明な構造は省略） | 10-15行 |
| ビルド・テスト・リント | 正確なコマンドをバッククォートで記載 | 10-15行 |
| コーディング規約 | リンターでカバーできない暗黙のルールのみ | 10-20行 |
| アーキテクチャ制約 | 依存関係の方向、モジュール分割の方針 | 5-10行 |
| Git ワークフロー | コミット規約、ブランチ戦略、PR ルール | 5-10行 |
| 禁止事項（ガードレール） | Never do リスト（セキュリティ・破壊的操作） | 5-10行 |
| 地雷マップ | 技術的負債、特殊な実装、触るな領域 | 必要に応じて |

**合計: 200行以内を目標**（毎セッション読み込まれるため、長いほど個々の指示が埋もれる）

### 2.2 各 CLI 向けファイルの生成

#### CLAUDE.md（Claude Code 用）

```markdown
# プロジェクト名 — 技術スタック概要（1行目に凝縮）

## ビルド・テスト
- `npm install` — 依存関係のインストール
- `npm run build` — ビルド
- `npm test` — テスト実行
- `npm run lint` — リント

## コーディング規約
[リンターでカバーできないルールのみ]

## アーキテクチャ
[ディレクトリ構造と依存関係の方向]

## Git ワークフロー
[コミット規約、ブランチ戦略]

## 禁止事項
- **絶対禁止**: [機密情報のコミット、本番DBの直接操作 等]
- **確認必須**: [破壊的変更、公開APIの変更 等]

## 地雷マップ
[特殊な実装、技術的負債の注意点]
```

#### AGENTS.md（Codex CLI 用）

CLAUDE.md と同一の内容をベースに、以下を調整:
- Codex 固有の機能（`/plan`, `/edit`）への言及を追加
- `config.toml` の推奨設定を末尾に付記

#### GEMINI.md（Gemini CLI 用）

CLAUDE.md と同一の内容をベースに、以下を調整:
- `@import` 構文で rules/ を参照する形式に
- `.geminiignore` の推奨内容を付記

### 2.3 統一管理の設定

3つのファイルを個別にメンテナンスするのではなく、**AGENTS.md を正本として symlink で統一**する方法を推奨:

```bash
# AGENTS.md を正本として作成
# CLAUDE.md と GEMINI.md は symlink
ln -s AGENTS.md CLAUDE.md
ln -s AGENTS.md GEMINI.md

# Gemini CLI の設定で AGENTS.md を読むように変更
# .gemini/settings.json
{
  "context": {
    "fileName": ["AGENTS.md", ".gemini/GEMINI.md"]
  }
}

# Codex CLI の設定で CLAUDE.md もフォールバックに
# ~/.codex/config.toml
project_doc_fallback_filenames = ["CLAUDE.md", "GEMINI.md"]
```


## 3. 検証フェーズ

生成したファイルを以下の基準でセルフチェックする。

### 品質チェックリスト

- [ ] **200行以内を目安**に収まっているか（超える場合は、自明な情報が混ざっていないかを先に確認する）
- [ ] **1行目**にプロジェクト名と技術スタックが凝縮されているか
- [ ] **自明な情報**（「これは TypeScript プロジェクトです」等）が含まれていないか
- [ ] **ビルド・テストコマンド**がバッククォートで正確に記載されているか
- [ ] **暗黙知**（リンターでカバーできないルール）が含まれているか
- [ ] **禁止事項**が具体的に列挙されているか
- [ ] **機密情報**（API キー等）が含まれていないか
- [ ] 3つの CLI で**互換性**があるか（symlink 運用が可能か）


## 4. 出力

以下のファイルを生成・配置する:

```
<project-root>/
├── AGENTS.md          # 正本（3 CLI 共通のコンテキスト）
├── CLAUDE.md          # → AGENTS.md への symlink
├── GEMINI.md          # → AGENTS.md への symlink
└── .gemini/
    └── settings.json  # context.fileName に AGENTS.md を追加
```

必要に応じて追加:
- `.claude/rules/*.md` — パスベースのルールファイル
- `.codex/config.toml` — フォールバック設定
- `.geminiignore` — 除外設定
