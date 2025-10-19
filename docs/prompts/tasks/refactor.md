# リファクタリングプロンプト

コードの品質を向上させるリファクタリングのガイドラインです。

## 目的

外部から見た動作を変えずに、コードの内部構造を改善する。

## リファクタリングの原則

> "Make it work, make it right, make it fast" - Kent Beck

1. **動作を保つ**: 外部の動作は変更しない
2. **テストで保護**: リファクタリング前にテストを充実させる
3. **小さなステップ**: 一度に一つの変更
4. **継続的なテスト**: 各ステップでテストを実行

## 実装手順

### 1. リファクタリングの動機確認

以下のいずれかに該当するか確認：

- [ ] コードの重複が多い（DRY原則違反）
- [ ] 関数・クラスが大きすぎる
- [ ] 命名が不適切
- [ ] 複雑度が高い（ネストが深い、条件分岐が多い）
- [ ] テストが書きにくい
- [ ] 依存関係が複雑
- [ ] デザインパターンが適用できそう

**リファクタリングの匂い（Code Smells）**:
- 長いメソッド
- 大きなクラス
- パラメータの多い関数
- データの群れ（関連する変数が複数）
- スイッチ文の羅列
- 推測的一般性（使われていない汎用性）

### 2. 現状の把握

- [ ] 対象コードを理解
- [ ] 依存関係を確認
- [ ] 使用箇所を調査
- [ ] カバレッジを確認

```bash
# 使用箇所の検索
grep -r "function_name" src/

# 依存関係の可視化（言語によって異なる）
# Python の例
pydeps src/module.py --show-deps

# カバレッジ確認
pytest --cov=src tests/
```

### 3. テストの強化

リファクタリング前に必ずテストを充実させる

- [ ] ユニットテストが存在するか確認
- [ ] カバレッジを向上（目標: 80%以上）
- [ ] エッジケースをカバー
- [ ] 全テストが通ることを確認

```python
# リファクタリング前のテスト例
def test_existing_behavior():
    """既存の動作を保護するテスト"""
    # 現在の動作を全てテスト
    assert current_behavior() == expected_result
    assert edge_case_1() == expected_1
    assert edge_case_2() == expected_2
```

### 4. ブランチ作成

```bash
git checkout -b refactor/[対象の説明]
```

### 5. リファクタリングパターンの選択

### パターン1: メソッドの抽出（Extract Method）

**Before**:
```python
def process_order(order):
    # 検証
    if not order:
        raise ValueError("Order is None")
    if order.total < 0:
        raise ValueError("Total is negative")

    # 計算
    tax = order.total * 0.1
    shipping = 5.0 if order.total < 50 else 0
    total = order.total + tax + shipping

    # 保存
    order.final_total = total
    db.save(order)
```

**After**:
```python
def process_order(order):
    validate_order(order)
    total = calculate_total(order)
    save_order(order, total)

def validate_order(order):
    if not order:
        raise ValueError("Order is None")
    if order.total < 0:
        raise ValueError("Total is negative")

def calculate_total(order):
    tax = order.total * 0.1
    shipping = 5.0 if order.total < 50 else 0
    return order.total + tax + shipping

def save_order(order, total):
    order.final_total = total
    db.save(order)
```

### パターン2: 変数名の改善（Rename Variable）

**Before**:
```python
def calc(x, y, z):
    t = x * y
    r = t + z
    return r
```

**After**:
```python
def calculate_total_price(quantity, unit_price, tax):
    subtotal = quantity * unit_price
    total = subtotal + tax
    return total
```

### パターン3: マジックナンバーの定数化

**Before**:
```python
def calculate_discount(amount):
    if amount > 100:
        return amount * 0.1
    return 0
```

**After**:
```python
DISCOUNT_THRESHOLD = 100
DISCOUNT_RATE = 0.1

def calculate_discount(amount):
    if amount > DISCOUNT_THRESHOLD:
        return amount * DISCOUNT_RATE
    return 0
```

### パターン4: 条件の分解

**Before**:
```python
if user.age >= 18 and user.has_license and not user.has_violations:
    allow_driving()
```

**After**:
```python
def can_drive(user):
    return (
        user.age >= 18
        and user.has_license
        and not user.has_violations
    )

if can_drive(user):
    allow_driving()
```

### パターン5: ガード句の導入

**Before**:
```python
def process(data):
    if data:
        if data.is_valid():
            if data.is_ready():
                # 実際の処理
                return do_something(data)
```

**After**:
```python
def process(data):
    if not data:
        return None
    if not data.is_valid():
        return None
    if not data.is_ready():
        return None

    # 実際の処理（ネストが減った）
    return do_something(data)
```

### パターン6: クラスの抽出

**Before**:
```python
class User:
    def __init__(self, name, email, street, city, zip):
        self.name = name
        self.email = email
        self.street = street
        self.city = city
        self.zip = zip
```

**After**:
```python
class Address:
    def __init__(self, street, city, zip):
        self.street = street
        self.city = city
        self.zip = zip

class User:
    def __init__(self, name, email, address):
        self.name = name
        self.email = email
        self.address = address
```

### 6. 段階的なリファクタリング

- [ ] 一度に一つの変更を実施
- [ ] 各変更後にテストを実行
- [ ] グリーンを保つ（テストが通る状態を維持）
- [ ] 小さくコミット

**リファクタリングのサイクル**:
```
1. テストが全てパス（グリーン）
2. 小さなリファクタリングを実施
3. テストを実行
4. グリーンを確認
5. コミット
6. 次のリファクタリングへ
```

```bash
# 各ステップでコミット
git add .
git commit -m "refactor: メソッドを抽出 - validate_order"
# テスト
pytest tests/
# 次のステップへ
```

### 7. コードメトリクスの確認

リファクタリング前後でメトリクスを比較

- [ ] 循環的複雑度（Cyclomatic Complexity）
- [ ] 行数
- [ ] 関数の数
- [ ] ネストの深さ
- [ ] 重複コード

```bash
# Python の例: radon でメトリクスを測定
radon cc src/ -a  # 複雑度
radon mi src/     # 保守性指標

# 重複コードの検出
radon raw src/
```

**目標値**:
- 循環的複雑度: 10以下（理想は5以下）
- 関数の行数: 20行以下
- ネストの深さ: 3階層以下

### 8. テストの実行

- [ ] 全テストが通ることを確認
- [ ] カバレッジが維持または向上
- [ ] パフォーマンステスト（必要に応じて）

```bash
# 全テスト実行
pytest tests/

# カバレッジ確認
pytest --cov=src --cov-report=html tests/

# パフォーマンス比較
python -m timeit "import module; module.function()"
```

### 9. ドキュメントの更新

- [ ] コメント・docstringを更新
- [ ] アーキテクチャドキュメントを更新（大きな変更の場合）
- [ ] CHANGELOGを更新（必要に応じて）

### 10. レビュー準備

- [ ] コミット履歴を整理
- [ ] PRの説明を準備
- [ ] Before/Afterを明示

**PR テンプレート（リファクタリング用）**:
```markdown
## リファクタリング

### 動機
[なぜリファクタリングが必要だったか]

### 変更内容
- [変更点1]
- [変更点2]

### Before/After

#### Before
```[language]
[リファクタリング前のコード]
```

#### After
```[language]
[リファクタリング後のコード]
```

### メトリクスの改善
- 複雑度: 15 → 8
- 行数: 150 → 100
- テストカバレッジ: 70% → 85%

### テスト
- [x] 既存テストが全て通る
- [x] カバレッジが維持または向上
- [x] パフォーマンス劣化なし

### チェックリスト
- [x] 動作が変わっていない
- [x] テストで保護されている
- [x] コードメトリクスが改善
- [x] ドキュメント更新
```

## リファクタリングの種類別ガイド

### 名前の変更

**目的**: コードの意図を明確にする

**手順**:
1. IDEのリネーム機能を使用（推奨）
2. 全ての使用箇所を更新
3. テストを実行

### 関数の分割

**目的**: 関数を小さく保つ（単一責任の原則）

**基準**:
- 20行を超えたら分割を検討
- 複数の責任がある場合

### 重複の排除

**目的**: DRY（Don't Repeat Yourself）原則の適用

**手順**:
1. 重複を見つける
2. 共通部分を抽出
3. 元の場所から呼び出す

### 条件分岐の簡略化

**目的**: 可読性の向上、複雑度の削減

**テクニック**:
- ガード句の導入
- 早期リターン
- ポリモーフィズムの活用
- 戦略パターンの適用

### クラス・モジュールの整理

**目的**: 適切な責任分割

**基準**:
- クラスは単一の責任を持つ
- 密結合を避け、疎結合を目指す
- 依存関係を逆転（DI）

## やってはいけないこと

1. **テストなしのリファクタリング**
   - 必ずテストで保護する

2. **機能追加との混在**
   - リファクタリングと機能追加は別のPRに

3. **一度に大規模な変更**
   - 小さなステップで進める

4. **動作の変更**
   - 外部から見た動作は変えない

5. **パフォーマンス劣化の無視**
   - リファクタリング後も性能を維持

## トラブルシューティング

### テストが壊れた

1. 直前のコミットに戻す
2. より小さなステップで進める
3. テストを見直す（誤ったテストの可能性）

### パフォーマンスが悪化した

1. プロファイラで原因を特定
2. アルゴリズムを見直す
3. 元の実装の利点を再検討

### レビューで指摘が多い

1. 変更を小さく分割
2. Before/After を明確に
3. 動機を詳しく説明

## ベストプラクティス

1. **レッド・グリーン・リファクター**
   - TDDのサイクルでリファクタリング

2. **童子軍ルール**
   - 来た時よりも美しく（小さな改善を積み重ねる）

3. **二帽子ルール**
   - 機能追加とリファクタリングは別々に

4. **継続的リファクタリング**
   - 大規模な書き直しより、継続的な小改善

5. **ペアプログラミング**
   - 複雑なリファクタリングはペアで

## 完了条件

- [ ] コードが読みやすくなった
- [ ] 複雑度が下がった
- [ ] 重複が減った
- [ ] テストが全て通る
- [ ] パフォーマンス劣化なし
- [ ] ドキュメント更新済み

## 参考

- Martin Fowler "Refactoring"
- Robert C. Martin "Clean Code"
- プロジェクトのコーディング規約
