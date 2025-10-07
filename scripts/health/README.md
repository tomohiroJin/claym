# Claym ヘルスチェック スクリプト

このディレクトリには、Claym の開発コンテナをビルド直後や起動直後に検証するためのヘルスチェックがまとまっています。

ヘルスチェックはモジュール構成になっており、`lib/` に実行基盤と共通ヘルパー、`checks/` に個別の診断（システム、ツールチェーン、MCP など）を配置しています。新しいチェックを追加したい場合は、`checks/` にファイルを作成して `register_check` を呼び出すだけで組み込めます。

## check-environment.sh

ルート README で説明している前提条件を低コストで検証します。

- Ubuntu 24.04 ベースとタイムゾーン設定の確認
- ワークスペースおよび ImageSorcery ログディレクトリが `vscode` ユーザー所有であることの確認
- 主要 CLI (`claude`, `codex`, `gemini`, `uv`, `npx`, `npm`, `rg` など) と Python MCP コマンド (`markitdown-mcp`, `imagesorcery-mcp`, `mcp-github`) の存在チェック
- CLI バージョン取得によるドリフト検知
- Claude / Codex / Gemini に対する既定 MCP 登録の有無確認
- Serena・Playwright・Python 仮想環境で管理される MCP 資産のスポットチェック
- コンテナにエクスポートされている API キー一覧の表示
- `safe.directory` 設定と ImageSorcery ログの参照可否の確認

### 使い方

```bash
# フルチェック（既定）
bash scripts/health/check-environment.sh

# 起動後の簡易チェック
bash scripts/health/check-environment.sh --quick

# JSON 形式のサマリ出力
bash scripts/health/check-environment.sh --json

# チェックID一覧を表示
bash scripts/health/check-environment.sh --list-checks

# 既知の失敗チェックをスキップ
bash scripts/health/check-environment.sh --skip serena-ready
```

終了コードの意味:

- `0`: クリティカルチェックがすべて成功
- `1`: クリティカルチェックに失敗あり
- `2`: 致命的ではない警告のみ

オプションは併用可能です（例: `--quick --json`）。CI や devcontainer フックに組み込むほか、手動診断にも利用できます。
