# Codex CLI エージェント指示

このファイルは Codex CLI エージェントに対する永続的な指示を提供します。
プロジェクト固有のガイドライン、コーディング規約、アーキテクチャの決定事項などを記載してください。

## 言語設定

**日本語を基本言語として使用してください。**

- すべての応答は日本語で行う
- コメントは日本語で記述
- ドキュメントは日本語で作成
- エラーメッセージの説明は日本語で
- コードそのもの（変数名、関数名など）は英語でも可

## 開発環境

### パッケージ管理
- Poetry を使用（Python プロジェクト）
- npm を使用（Node.js プロジェクト）

### 依存関係のインストール
```bash
# Python
poetry install

# Node.js
npm install
```

### 環境変数
- `.env` ファイルを使用
- `.env.example` をテンプレートとして提供

## テスト

### テストの実行
```bash
# Python
poetry run pytest tests/

# 特定のテストファイル
poetry run pytest tests/test_example.py

# カバレッジ付き
poetry run pytest --cov=src tests/
```

### テストカバレッジ
- 新機能には必ずテストを含める
- カバレッジは80%以上を目標
- 重要なロジックは100%を目指す

### テスト規約
- テストファイル名: `test_*.py` または `*_test.py`
- テスト関数名: `test_` で開始
- アサーションは明確に（期待値と実際値を分離）

## コーディング規約

### Python
- **フォーマッター**: Black
- **リンター**: Pylint, Ruff
- **型チェック**: mypy
- **docstring**: Google スタイル、日本語で記述

```python
def calculate_total(items: list[Item]) -> float:
    """
    商品リストから合計金額を計算します。

    Args:
        items: 商品のリスト

    Returns:
        合計金額

    Raises:
        ValueError: items が空の場合
    """
    if not items:
        raise ValueError("商品リストが空です")
    return sum(item.price for item in items)
```

### JavaScript/TypeScript
- **フォーマッター**: Prettier
- **リンター**: ESLint
- **スタイル**: Airbnb スタイルガイド準拠

```typescript
/**
 * 商品リストから合計金額を計算します
 * @param items 商品の配列
 * @returns 合計金額
 */
function calculateTotal(items: Item[]): number {
  if (items.length === 0) {
    throw new Error('商品リストが空です');
  }
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

### 命名規則
- 変数名・関数名: `snake_case` (Python) / `camelCase` (JS/TS)
- クラス名: `PascalCase`
- 定数: `UPPER_SNAKE_CASE`
- プライベート: 先頭にアンダースコア `_`
- ブール値: `is_`, `has_`, `can_` などの接頭辞

### コメント
- 複雑なロジックには必ずコメントを追加
- コメントは日本語で記述
- TODO コメントには日付と担当者を記載
  ```python
  # TODO(2025-10-19, username): ここをリファクタリング
  ```

## Git / Pull Request ガイドライン

### コミットメッセージ
形式: `<type>: <subject>`

**Type**:
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント
- `refactor`: リファクタリング
- `test`: テスト追加・修正
- `style`: コードスタイル変更（機能影響なし）
- `chore`: ビルド・設定変更
- `perf`: パフォーマンス改善

**例**:
```
feat: ユーザー認証機能を追加

- メールアドレスとパスワードによるログイン機能
- JWTトークンベースの認証
- パスワードのハッシュ化（bcrypt使用）
- リフレッシュトークン対応
```

### Pull Request
- **タイトル**: `[Type] 簡潔な説明`
  - 例: `[Fix] ログイン時のセッション管理バグを修正`
- **説明**: 以下を含める
  - 変更の目的・背景
  - 実装内容の概要
  - テスト方法
  - スクリーンショット（UI変更の場合）
- **レビュー**: 最低1人の承認が必要
- **CI**: すべてのチェックがパスしていること
- **ブランチ**: `feature/`, `fix/`, `refactor/` などの接頭辞を使用

## セキュリティ

### 基本原則
- API キーや認証情報は環境変数で管理
- `.env` ファイルは `.gitignore` に含める
- 外部入力は必ずバリデーション
- SQL インジェクション対策を実施（ORM使用推奨）
- XSS 対策（エスケープ処理）
- CSRF トークンの使用

### パスワード管理
- bcrypt または Argon2 を使用
- ソルト付きハッシュ化
- パスワード強度チェック

### データ保護
- 個人情報は暗号化して保存
- HTTPS 通信のみ
- 適切な CORS 設定

## パフォーマンス

### データベース
- N+1 問題に注意（eager loading 使用）
- インデックスの適切な設定
- クエリの最適化（EXPLAIN で確認）
- コネクションプーリング

### ファイル処理
- 大きなファイルはストリーミング処理
- 非同期処理の活用
- メモリ使用量の監視

### キャッシュ
- Redis などを活用
- 適切な有効期限設定
- キャッシュ無効化戦略の実装

## エラーハンドリング

### 原則
- すべてのエラーを適切にハンドリング
- ユーザーフレンドリーなエラーメッセージ
- ログに詳細情報を記録
- エラー時のリトライ戦略

### ログレベル
- `DEBUG`: 開発時の詳細情報
- `INFO`: 通常の動作情報
- `WARNING`: 警告（処理は継続）
- `ERROR`: エラー（処理失敗）
- `CRITICAL`: 致命的エラー

## プロジェクト固有の情報

<!-- ここにプロジェクト固有のアーキテクチャ、デザインパターン、
     重要な決定事項などを記載してください -->

### アーキテクチャ
<!-- 例: クリーンアーキテクチャを採用 -->
<!-- 例: ドメイン駆動設計（DDD）を実践 -->

### 使用技術
<!-- 例: フレームワーク: FastAPI, Next.js -->
<!-- 例: データベース: PostgreSQL -->
<!-- 例: キャッシュ: Redis -->
<!-- 例: メッセージキュー: RabbitMQ -->

### 重要な設計決定
<!-- 例: API は RESTful 設計に準拠 -->
<!-- 例: 認証は OAuth 2.0 + JWT -->
<!-- 例: マイクロサービスアーキテクチャ -->

### ディレクトリ構造
<!-- 例:
src/
├── domain/          # ドメインロジック
├── application/     # アプリケーションロジック
├── infrastructure/  # インフラ層
└── presentation/    # プレゼンテーション層
-->

## 参考資料

- プロジェクトドキュメント: `docs/`
- API 仕様書: `docs/api/`
- アーキテクチャ図: `docs/architecture/`
