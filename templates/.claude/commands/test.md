# テスト関連コマンド

このコマンドは、テストケースの生成とテスト実行を支援します。

## 概要

`/test` コマンドは、テスト駆動開発（TDD）をサポートし、品質の高いテストコードを生成します。以下のような機能を提供します：

- ユニットテストの自動生成
- 統合テストの自動生成
- E2E テストの自動生成
- テストカバレッジの分析
- テスト実行と結果の確認

## 使い方

```
/test <テストに関する要求>
```

### 例

```
/test src/utils/validator.ts のユニットテストを作成
```

```
/test API エンドポイント /api/users の統合テストを生成
```

```
/test 現在のテストカバレッジを確認して不足部分のテストを追加
```

## プロンプト

以下のガイドラインに従ってテストを生成・実行してください：

### 1. テストの準備

#### テスト対象の分析

- コードの機能を理解する
- 入力と出力を特定する
- エッジケースを考慮する
- 依存関係を確認する

#### テストフレームワークの確認

プロジェクトで使用されているテストフレームワークを特定：

- **JavaScript/TypeScript**: Jest、Vitest、Mocha など
- **Python**: pytest、unittest など
- **統合テスト**: Supertest、Playwright など

### 2. ユニットテストの生成

ユニットテストは以下の構造で生成してください：

#### テストの基本構造（AAA パターン）

```typescript
describe('<テスト対象の関数/クラス名>', () => {
  describe('<メソッド名>', () => {
    it('<期待される振る舞い>', () => {
      // Arrange: テストの準備
      const input = ...;
      const expected = ...;

      // Act: テスト対象を実行
      const result = functionUnderTest(input);

      // Assert: 結果を検証
      expect(result).toBe(expected);
    });
  });
});
```

#### テストケースの網羅

各関数に対して、以下のテストケースを含めてください：

1. **正常系（Happy Path）**
   - 典型的な入力での動作確認
   - 期待される結果が得られることを確認

2. **境界値テスト**
   - 最小値、最大値
   - 空の値（空文字列、空配列、null、undefined）
   - 0、負の値

3. **異常系（Error Path）**
   - 不正な入力
   - 例外が発生するケース
   - エラーメッセージの確認

4. **エッジケース**
   - 特殊な状況
   - まれに発生するケース

### 3. テスト例

#### TypeScript/JavaScript (Jest)

```typescript
import { validateEmail } from './validator';

describe('validateEmail', () => {
  describe('正常系', () => {
    it('有効なメールアドレスの場合、true を返す', () => {
      // Arrange
      const validEmail = 'test@example.com';

      // Act
      const result = validateEmail(validEmail);

      // Assert
      expect(result).toBe(true);
    });
  });

  describe('異常系', () => {
    it('@ がない場合、false を返す', () => {
      expect(validateEmail('invalid-email')).toBe(false);
    });

    it('ドメインがない場合、false を返す', () => {
      expect(validateEmail('test@')).toBe(false);
    });

    it('空文字列の場合、false を返す', () => {
      expect(validateEmail('')).toBe(false);
    });

    it('null の場合、false を返す', () => {
      expect(validateEmail(null)).toBe(false);
    });
  });
});
```

#### Python (pytest)

```python
import pytest
from calculator import Calculator

class TestCalculator:
    """Calculator クラスのテスト"""

    def test_add_positive_numbers(self):
        """正の数の加算"""
        # Arrange
        calc = Calculator()

        # Act
        result = calc.add(2, 3)

        # Assert
        assert result == 5

    def test_add_negative_numbers(self):
        """負の数の加算"""
        calc = Calculator()
        result = calc.add(-2, -3)
        assert result == -5

    def test_divide_by_zero(self):
        """ゼロ除算のテスト"""
        calc = Calculator()
        with pytest.raises(ZeroDivisionError):
            calc.divide(10, 0)

    @pytest.mark.parametrize("a,b,expected", [
        (0, 0, 0),
        (1, 0, 1),
        (0, 1, 1),
        (100, -100, 0),
    ])
    def test_add_edge_cases(self, a, b, expected):
        """境界値テスト"""
        calc = Calculator()
        assert calc.add(a, b) == expected
```

### 4. 統合テストの生成

API エンドポイントなどの統合テストは以下の形式で生成：

```typescript
import request from 'supertest';
import app from '../app';

describe('POST /api/users', () => {
  describe('正常系', () => {
    it('有効なデータでユーザーを作成できる', async () => {
      // Arrange
      const userData = {
        name: '山田太郎',
        email: 'yamada@example.com',
        password: 'SecurePass123!'
      };

      // Act
      const response = await request(app)
        .post('/api/users')
        .send(userData)
        .expect(201);

      // Assert
      expect(response.body).toMatchObject({
        id: expect.any(String),
        name: userData.name,
        email: userData.email,
      });
      expect(response.body.password).toBeUndefined(); // パスワードは返さない
    });
  });

  describe('異常系', () => {
    it('メールアドレスが不正な場合、400 エラーを返す', async () => {
      const invalidData = {
        name: '山田太郎',
        email: 'invalid-email',
        password: 'SecurePass123!'
      };

      const response = await request(app)
        .post('/api/users')
        .send(invalidData)
        .expect(400);

      expect(response.body.error).toBeDefined();
    });

    it('必須フィールドが欠けている場合、400 エラーを返す', async () => {
      const incompleteData = {
        name: '山田太郎'
        // email と password が欠けている
      };

      await request(app)
        .post('/api/users')
        .send(incompleteData)
        .expect(400);
    });
  });
});
```

### 5. モックとスタブの使用

外部依存をモック化する例：

```typescript
import { jest } from '@jest/globals';
import { UserService } from './userService';
import { Database } from './database';

// Database をモック化
jest.mock('./database');

describe('UserService', () => {
  let userService: UserService;
  let mockDb: jest.Mocked<Database>;

  beforeEach(() => {
    // モックをリセット
    mockDb = new Database() as jest.Mocked<Database>;
    userService = new UserService(mockDb);
  });

  it('ユーザーを取得できる', async () => {
    // Arrange
    const mockUser = { id: '123', name: '山田太郎' };
    mockDb.findUser.mockResolvedValue(mockUser);

    // Act
    const user = await userService.getUser('123');

    // Assert
    expect(user).toEqual(mockUser);
    expect(mockDb.findUser).toHaveBeenCalledWith('123');
    expect(mockDb.findUser).toHaveBeenCalledTimes(1);
  });
});
```

### 6. テストカバレッジの確認

テストカバレッジを確認し、不足部分を特定：

```bash
# Jest の場合
npm test -- --coverage

# pytest の場合
pytest --cov=src --cov-report=html
```

カバレッジ結果を分析し、以下を確認：

- **行カバレッジ**: すべての行が実行されているか
- **分岐カバレッジ**: すべての条件分岐がテストされているか
- **関数カバレッジ**: すべての関数がテストされているか

### 7. テスト生成の原則

#### 独立性

- 各テストは他のテストに依存しない
- テストの実行順序に依存しない
- 共有状態を使わない

#### 明確性

- テスト名は何をテストしているか明確に
- Given-When-Then または Arrange-Act-Assert パターンを使用
- 1 テストにつき 1 つの検証項目

#### 信頼性

- フレイキーテスト（不安定なテスト）を避ける
- タイムアウトやランダム値に注意
- 外部サービスへの依存を最小化

#### 保守性

- テストコードも読みやすく
- DRY 原則（重複を避ける）
- ヘルパー関数を活用

### 8. テスト生成後の説明

テスト生成後、以下を説明してください：

- **生成したテストファイルの一覧**
- **カバレッジの状況**
- **実行方法**
- **追加で必要なテストケース**

## 例: 関数のユニットテスト生成

### ユーザーの入力

```
/test src/utils/formatDate.ts のユニットテストを作成
```

### 期待される出力

1. **対象コードの分析**
   ```
   formatDate 関数を分析しました：
   - 入力: Date オブジェクトまたは ISO 文字列
   - 出力: "YYYY-MM-DD" 形式の文字列
   - エッジケース: null、undefined、不正な日付
   ```

2. **テストファイルの生成**
   ```typescript
   // src/utils/formatDate.test.ts
   import { formatDate } from './formatDate';

   describe('formatDate', () => {
     describe('正常系', () => {
       it('Date オブジェクトを正しくフォーマットする', () => {
         const date = new Date('2025-01-15T10:30:00Z');
         expect(formatDate(date)).toBe('2025-01-15');
       });

       it('ISO 文字列を正しくフォーマットする', () => {
         expect(formatDate('2025-01-15T10:30:00Z')).toBe('2025-01-15');
       });
     });

     describe('異常系', () => {
       it('null の場合、空文字列を返す', () => {
         expect(formatDate(null)).toBe('');
       });

       it('undefined の場合、空文字列を返す', () => {
         expect(formatDate(undefined)).toBe('');
       });

       it('不正な日付文字列の場合、空文字列を返す', () => {
         expect(formatDate('invalid-date')).toBe('');
       });
     });
   });
   ```

3. **実行手順の提示**
   ```bash
   # テストの実行
   npm test src/utils/formatDate.test.ts

   # カバレッジ付きで実行
   npm test -- --coverage src/utils/formatDate.test.ts
   ```

## カスタマイズ

### テストパターンの追加

プロジェクト固有のテストパターンを定義できます：

```markdown
## プロジェクト固有のテストパターン

### データベーステスト

- トランザクションを使用する
- テスト後にデータをロールバックする
- テストデータは Factory を使用する

### 認証が必要な API

- 認証ヘッダーを含める
- 権限のテストを含める
```

### テストカバレッジの目標

```markdown
## カバレッジ目標

- 全体: 80% 以上
- クリティカルな機能: 90% 以上
- ユーティリティ関数: 100%
```

## 注意事項

### テストの粒度

- ユニットテストは小さく、高速に
- 統合テストは必要最小限に
- E2E テストは重要なフローのみ

### テストデータ

- 本番データは使用しない
- 個人情報を含めない
- テスト用のモックデータを使用

### CI/CD との統合

- すべてのテストは CI で実行される前提
- フレイキーテストは修正する
- テスト実行時間に注意

## トラブルシューティング

### テストが失敗する

- エラーメッセージを確認
- デバッグモードで実行
- モックの設定を確認

### テストが遅い

- 不要な待機時間を削除
- 並列実行を検討
- モックを活用

### カバレッジが上がらない

- 未テストのブランチを特定
- エッジケースを追加
- 不要なコードを削除

---

**更新日**: 2025-10-20
