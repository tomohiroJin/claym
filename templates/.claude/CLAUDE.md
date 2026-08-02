# <プロジェクト名> — Claude Code カスタム指示

> 共通コンテキストは `AGENTS.md`（プロジェクトルート）を参照。
> 詳細規約は `rules/` 配下を参照。ここでは Claude Code 固有の指示のみ記載。
> 言語設定はグローバル `~/.claude/CLAUDE.md` から継承されます。

## プロジェクト固有の差分

<!-- ここに AGENTS.md や rules/ でカバーできない、このプロジェクト固有の暗黙知を記載 -->
<!-- 例: 特定のモジュールの扱い方、テスト実行の注意点、環境固有の制約 -->

## MCP ツール詳細手順

### serena（シンボリック操作）
- コード構造理解: `get_symbols_overview` → `find_symbol` の順
- シンボル編集: `replace_symbol_body` を優先
- 参照追跡: `find_referencing_symbols` を使用

### context7（ドキュメント参照）
- `resolve-library-id` → `query-docs` でライブラリ仕様を確認
- 既知のライブラリでも最新ドキュメントを確認

## スキル・コマンド・エージェント

- **スキル**: `.claude/skills/` — `/<スキル名>` で呼び出し可能
- **コマンド**: `.claude/commands/` — `/<コマンド名>` で呼び出し可能
- **エージェント**: `.claude/agents/` — エージェント定義（YAML）
