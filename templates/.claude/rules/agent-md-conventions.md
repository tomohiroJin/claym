---
description: Agent.md 設計規約（CLAUDE.md/AGENTS.md/GEMINI.md の設計時に適用）
alwaysApply: false
paths: **/{CLAUDE,AGENTS,GEMINI}.md, .claude/**, .codex/**, .gemini/**, templates/**
---

# Agent.md 設計規約

AI CLI（Claude Code / Codex CLI / Gemini CLI）のコンテキストファイル設計時に常に適用する規約。

---

## 1. サイズ制限

- [ ] 各ファイルは **200行以内**（LLM の指示遵守率が低下する閾値）
- [ ] 1行目にプロジェクト名 + 技術スタックを凝縮
- [ ] 末尾に禁止事項（Never do）を配置（LLM は冒頭と末尾を重視）

---

## 2. 書くべきこと

- **暗黙知**: リンター/フォーマッターでカバーできないチーム固有のルール
- **実行コマンド**: ビルド・テスト・リント・デプロイの正確なコマンド（バッククォート内）
- **地雷マップ**: 技術的負債、特殊な実装、「触るな」領域
- **権限の三層構造**: Always do / Ask first / Never do
- **アーキテクチャの意図**: なぜこの構造になったかの非自明な経緯
- **Git ワークフロー**: コミット規約、ブランチ戦略、PR テンプレート

---

## 3. 書いてはいけないこと（アンチパターン）

- **自明な情報**: 「TypeScript プロジェクトです」→ エージェントがコードを読めば分かる
- **汎用ペルソナ**: 「あなたは親切なアシスタントです」→ コーディング業務に効果なし
- **リンターで代替可能なルール**: ESLint/Prettier/Biome で強制できるものは Agent.md に書かない
- **曖昧な指示**: 「適切に対応してください」→ 具体的な手順に置換
- **機密情報**: API キー、パスワード、トークンを絶対に含めない
- **/init の出力そのまま**: トークンコスト20%以上のインフレ原因

---

## 4. 統一管理の原則

- **AGENTS.md を正本**とし、各 CLI の読み込み方式に応じて参照する
  - Claude Code: プロジェクトルートに `CLAUDE.md → AGENTS.md` の symlink を配置
  - Codex CLI: `AGENTS.md` を直接読み込み（`project_doc_fallback_filenames` で設定）
  - Gemini CLI: `GEMINI.md` 内で `@AGENTS.md` インポート（symlink は非対応）
- CLI 固有の差分は `.claude/CLAUDE.md`, `.gemini/GEMINI.md` に分離
- `.gemini/settings.json` の `context.fileName` に `["AGENTS.md", ".gemini/GEMINI.md"]` を設定

---

## 5. モジュール化（モノレポ / 大規模プロジェクト）

- ルートの Agent.md は **普遍的なルールのみ**（300行以内）
- サブディレクトリに固有のルールを配置（各 CLI の階層探索を活用）
- Claude Code: `.claude/rules/*.md` でパスベースのスコーピング
- Gemini CLI: JIT コンテキストが自動的にサブディレクトリを読み込む
- Codex CLI: 深い階層のファイルがプロンプト末尾に配置され優先される

---

## 6. メンテナンス

- Agent.md は **生きたドキュメント**。アーキテクチャ変更時に必ず更新
- 「同じ訂正を2回したら Agent.md に追加すべきシグナル」
- 定期的に `/audit-agent-md` で品質を監査
- package.json のバージョンと Agent.md の記載が矛盾していないか確認
