# テスト規約

以下はプロジェクトの技術スタックに応じて適用してください。

## テストフレームワーク（デフォルト）

- ユニットテスト: Jest（Node.js）/ pytest（Python）
- コンポーネントテスト: Testing Library（React の場合）
- テストファイル: `*.test.ts(x)` / `test_*.py` / `*_test.go` 等

## テスト記述パターン

### AAA パターン（Arrange / Act / Assert）

```typescript
it('合計金額を正しく計算する', () => {
  // Arrange: テストデータの準備
  const items = [
    { name: '商品A', price: 100 },
    { name: '商品B', price: 200 },
  ];

  // Act: テスト対象の実行
  const total = calculateTotal(items);

  // Assert: 結果の検証
  expect(total).toBe(300);
});
```

### describe / it の構造

```typescript
describe('calculateTotal', () => {
  describe('正常系', () => {
    it('商品リストから合計金額を計算する', () => { ... });
    it('空のリストは0を返す', () => { ... });
  });

  describe('異常系', () => {
    it('不正な値が含まれる場合にエラーを投げる', () => { ... });
  });
});
```

## テストの原則

### 振る舞いベース
- 内部実装ではなく、外部から見た振る舞いをテスト
- Testing Library: `getByRole`, `getByText` を優先（`getByTestId` は最終手段）

### 独立性
- 各テストは他のテストに依存しない
- テスト間で状態を共有しない
- `beforeEach` で初期化、`afterEach` でクリーンアップ

### 可読性
- テスト名は「何をしたら何が起きるか」を日本語で記述
- 1つのテストで1つのアサーション（関連するアサーションはグループ化可）

## カバレッジ目標

| 対象 | 目標 |
|------|------|
| 新規コード | 80% 以上 |
| ビジネスロジック | 90% 以上 |
| ユーティリティ関数 | 90% 以上 |
| UI コンポーネント | 70% 以上 |

## 避けるべきパターン

- テスト内でのロジック（条件分岐、ループ）
- テスト対象以外のモジュールの詳細なモック
- スナップショットテストの過度な使用
- `setTimeout` を使った非同期待ち（`waitFor` を使用）
