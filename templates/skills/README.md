# Agent Skills テンプレート

## 概要

[Agent Skills](https://agentskills.io/) は、AI エージェントに専門的な能力を付与するオープンスタンダードです。
27 以上の AI ツール（Claude Code、Codex CLI、Gemini CLI 等）で採用されています。

このディレクトリには、プロジェクト共通で利用できるスキルテンプレートが格納されています。

## ディスカバリーパス

init スクリプトにより、以下のパスにスキルがコピーされます:

| ツール | パス | 形式 |
|--------|------|------|
| Claude Code | `.claude/skills/<name>/SKILL.md` | YAML フロントマター付き Markdown |
| Codex CLI | `.codex/prompts/<name>.md` | フロントマター除去済み Markdown |
| Gemini CLI | `.gemini/commands/<name>.md` | フロントマター除去済み Markdown |

## 収録スキル一覧

| スキル名 | 概要 |
|----------|------|
| `tdd-workflow` | Red-Green-Refactor の TDD サイクル |
| `code-review` | 構造化されたコードレビュー手順 |
| `security-review` | セキュリティ脆弱性の検出・OWASP 観点レビュー |
| `search-first` | 実装前にコードベースの既存パターンを調査 |
| `verification-loop` | 変更後のビルド・テスト・lint 検証サイクル |
| `api-design` | REST API 設計のベストプラクティス |
| `refactor-safely` | 安全なリファクタリング手順 |
| `debug-systematically` | 体系的デバッグ手法 |
| `documentation-first` | ドキュメント駆動開発 |
| `git-workflow` | コミット・ブランチ・PR のベストプラクティス |
| `generate-agent-md` | プロジェクト解析 → CLAUDE.md / AGENTS.md / GEMINI.md 一括生成 |
| `audit-agent-md` | 既存 Agent.md の品質監査・改善提案 |
| `design-review` | UI/UX デザインレビュー（ゲシュタルト原則・WCAG・配色） |
| `design-system` | デザインシステム構築（カラートークン・タイポグラフィ・CSS変数） |
| `deep-research` | 体系的リサーチ（SIFT・CRAAP・多段階調査） |
| `summarize` | 構造化された要約生成（Map-Reduce・反復洗練・RAPTOR） |
| `scenario-review` | ゲームシナリオ品質検証（フラグ矛盾・分岐到達可能性） |
| `scenario-write` | ゲームシナリオ執筆支援（マクロ設計→ミクロ執筆） |
| `seo-audit` | SEO 監査（18アンチパターン・Googleスパムポリシー） |
| `seo-content` | SEO コンテンツ最適化（検索意図分析・E-E-A-T） |
| `market-check` | 日次マーケットチェック（主要指標・ニュースソース） |
| `stock-analysis` | 銘柄分析（ファンダメンタルズ・テクニカル・行動バイアス） |

## SKILL.md フォーマット

各スキルは [Agent Skills 仕様](https://agentskills.io/specification) に準拠しています:

```yaml
---
name: skill-name
description: スキルの説明（1024文字以内）
---

# スキル名

## 手順
...
```

### 必須フィールド

| フィールド | 制約 |
|-----------|------|
| `name` | 1-64文字、小文字英数字とハイフンのみ、ディレクトリ名と一致 |
| `description` | 1-1024文字、スキルの目的と利用場面を記述 |

## カスタマイズ

### ローカルオーバーライド

`templates-local/skills/` にスキルを配置すると、同名の公式テンプレートを上書きできます:

```
templates-local/
  skills/
    tdd-workflow/SKILL.md    # 公式テンプレートを上書き
    my-custom-skill/SKILL.md # 独自スキルを追加
```

### 新規スキルの追加

1. `templates/skills/<name>/SKILL.md` を作成
2. YAML フロントマターに `name` と `description` を記述
3. Markdown 本文にスキルの手順を記述
4. `name` がディレクトリ名と一致することを確認

## 参考リンク

- [Agent Skills 仕様](https://agentskills.io/specification)
- [Agent Skills GitHub](https://github.com/agentskills/agentskills)
