# ADR-0001: AGENTS.md を 3CLI コンテキストの正本とする

- **Status**: Accepted
- **Date**: 2026-07-04（決定自体は 2026-03-29 の symlink 統一 9272f77 に遡る）
- **Owner**: tomohiro
- **Superseded by**: なし

## 決定

1. プロジェクト共通コンテキストの正本は `AGENTS.md`（プロジェクトルート）とする。
   - Claude Code: `CLAUDE.md → AGENTS.md` の symlink で読み込む
   - Codex CLI: `.codex/config.toml` の `project_doc_fallback_filenames = ["AGENTS.md", "CLAUDE.md"]`
   - Gemini CLI: `.gemini/GEMINI.md` が `@../AGENTS.md` を import（**2026-07 時点で Gemini は利用停止。`.gemini/` は残置のみ**）
2. CLI 固有の差分は `.claude/CLAUDE.md` / `.gemini/GEMINI.md` に分離する。
3. ルールファイルは `.claude/rules/`（frontmatter の `paths` で条件ロード）を基準に、`.codex/instructions/` へ同期する。共有正本は `templates/` に置く。
4. サブエージェント定義の YAML（旧 `.claude/agents/*.yaml`）は Claude Code に読み込まれない形式だったため、2026-07-04 の監査でローカルから削除した。テンプレート正本は `templates/.claude/agents/` に、Codex/Gemini 向け変換物は `templates/.codex/prompts/` / `templates/.gemini/commands/` に残る。

## 理由

- 3 CLI で同一内容を三重管理するとドリフトが必発（実際に kamishibai / translation ルールの配置非対称が発生した）。
- symlink + import + fallback 設定なら、1 ファイルの編集が全 CLI に伝播する。

## 実装

- `AGENTS.md`, ルート `CLAUDE.md`(symlink), `.codex/config.toml`, `.gemini/settings.json` の `context.fileName: ["AGENTS.md", ".gemini/GEMINI.md"]`
- 規約本文: `.claude/rules/agent-config-agent-md-conventions.md` §4
- 解説: `docs/3cli-hierarchy-guide.md`
