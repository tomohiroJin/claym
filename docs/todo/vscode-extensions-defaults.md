# VSCode拡張機能デファクトスタンダード実装 TODO

## ステータス

- ✅ 完了
- 🚧 進行中
- ⏳ 保留中
- ❌ ブロック中

## フェーズ1: 調査・設計 (2025-10-18)

### 調査
- [✅] 既存の `.claude/settings.local.json` の分析
- [✅] 既存の `.gemini/settings.json` の分析
- [✅] 既存の `.devcontainer/devcontainer.json` の VSCode 拡張設定の確認
- [✅] Codex CLI の設定方法の調査
- [✅] MCP サーバーの現状確認

### 仕様書作成
- [✅] `docs/spec/vscode-extensions-defaults.md` の作成
- [✅] `docs/todo/vscode-extensions-defaults.md` (このファイル) の作成

## フェーズ2: テンプレート作成

### 設定ファイルテンプレート
- [⏳] `.claude/settings.local.json.example` の作成
  - 基本権限セット
  - 拡張権限セット (開発用)
  - コメント付きで各権限の説明

- [⏳] `.gemini/settings.json.example` の作成
  - UI設定のデフォルト値
  - MCP サーバー構成
  - 認証設定

- [⏳] `.codex/config.toml.example` の作成
  - 基本構成
  - MCP サーバー設定 (SSE対応)

### プロンプトテンプレート
- [⏳] `docs/prompts/system.md` の作成
  - プロジェクト情報プレースホルダー
  - コーディング規約
  - 作業方針

- [⏳] `docs/prompts/tasks/` の作成
  - `feature-add.md`: 機能追加プロンプト
  - `bug-fix.md`: バグ修正プロンプト
  - `refactor.md`: リファクタリングプロンプト
  - `review.md`: コードレビュープロンプト

## フェーズ3: ツール・スクリプト実装

### 設定生成スクリプト
- [⏳] `scripts/setup/init-ai-configs.sh` の作成
  - 各種設定ディレクトリの作成
  - テンプレートからの設定ファイル生成
  - .gitignore の更新

- [⏳] `scripts/setup/update-permissions.py` の作成
  - Claude Code 権限の追加・削除
  - JSON の整形・バリデーション

- [⏳] `scripts/setup/update-mcp-servers.py` の作成
  - GEMINI, Codex の MCP サーバー設定更新
  - 共通の MCP サーバー構成を反映

### バリデーションツール
- [⏳] `scripts/validate/check-ai-configs.py` の作成
  - 設定ファイルの構文チェック
  - 必須項目の確認
  - セキュリティチェック (APIキーの漏洩確認)

## フェーズ4: ドキュメント整備

### ユーザーガイド
- [⏳] `docs/guides/setup-ai-tools.md` の作成
  - 新規プロジェクトでのセットアップ手順
  - 既存プロジェクトへの適用手順
  - トラブルシューティング

- [⏳] `docs/guides/prompt-engineering.md` の作成
  - 効果的なプロンプトの書き方
  - プロンプトテンプレートの使用方法
  - ベストプラクティス集

### 開発者向けドキュメント
- [⏳] `docs/dev/mcp-server-integration.md` の作成
  - 新しい MCP サーバーの追加方法
  - カスタム MCP サーバーの開発

- [⏳] `docs/dev/permission-management.md` の作成
  - 権限設計の考え方
  - 権限追加のガイドライン

## フェーズ5: 統合とテスト

### 既存プロジェクトへの適用
- [⏳] Claym プロジェクトへの適用
  - 現行設定のバックアップ
  - 新しいテンプレートの適用
  - 動作確認

### テストケース作成
- [⏳] 設定ファイルのテスト
  - JSON/TOML パースのテスト
  - バリデーションのテスト

- [⏳] スクリプトのテスト
  - 設定生成のテスト
  - 更新機能のテスト

## フェーズ6: CI/CD 統合

### GitHub Actions
- [⏳] `.github/workflows/validate-ai-configs.yml` の作成
  - PR時の設定ファイルバリデーション
  - セキュリティチェック

### プリコミットフック
- [⏳] `.pre-commit-config.yaml` の設定
  - 設定ファイルのフォーマットチェック
  - APIキー漏洩チェック

## フェーズ7: リリース準備

### ドキュメント最終レビュー
- [⏳] 仕様書のレビュー
- [⏳] ガイドのレビュー
- [⏳] README の更新

### リリースノート作成
- [⏳] `CHANGELOG.md` の更新
- [⏳] リリースノートの作成

## 次のステップ

1. **フェーズ2の実行**: テンプレート作成から開始
2. **Web調査**: 各ツールの公式ドキュメントで最新のベストプラクティスを確認
3. **実装**: 優先度の高い項目から順次実装

## メモ・課題

### 調査が必要な項目
- [ ] Codex CLI の最新の MCP サーバー対応状況
- [ ] Claude Code の最新の権限設定パターン
- [ ] GEMINI の OAuth 設定のベストプラクティス

### 考慮事項
- 各ツールのバージョン管理方法
- 設定の自動マイグレーション
- マルチプロジェクト環境での設定共有

### 既知の課題
- Codex CLI の設定ファイルフォーマットが変更される可能性
- MCP サーバーの起動パスが環境依存

## 参考リソース

### 公式ドキュメント
- [Claude Code Docs](https://docs.claude.com/claude-code)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [VSCode Extension Guides](https://code.visualstudio.com/api/extension-guides/overview)

### コミュニティリソース
- [MCP Servers Repository](https://github.com/modelcontextprotocol/servers)
- [Claude Code GitHub Issues](https://github.com/anthropics/claude-code/issues)

## 更新履歴

| 日付 | 更新内容 | 担当 |
|------|----------|------|
| 2025-10-18 | 初版作成 | Claude Code |
