# デザインシステム構築

プロジェクトの特性に応じた包括的なデザインシステムを設計・生成します。

## 構築手順

### 1. ヒアリング

デザインシステム構築に必要な情報を収集します。

#### 必須項目
- **プロジェクト種別**: Web / ゲームUI / TUI / ポートフォリオ / SaaS
- **ターゲットユーザー**: 年齢層、技術レベル、利用デバイス
- **トーン&マナー**: プロフェッショナル / カジュアル / ゲーミング / ミニマル
- **既存ブランドカラー**: 指定がある場合
- **技術スタック**: Tailwind / CSS Modules / styled-components 等

#### 任意項目
- 競合サイトの参考URL
- 使用フレームワーク（Next.js / Astro / React等）
- 多言語対応の有無
- アクセシビリティレベル（AA / AAA）

### 2. カラーパレット生成

#### 60-30-10 ルールに基づく設計

| 役割 | 比率 | 用途 | 設計指針 |
|------|------|------|---------|
| **ドミナント** | 60% | 背景、基調色 | 目に優しく長時間の閲覧に耐える |
| **セカンダリ** | 30% | パネル、カード、ナビゲーション | ドミナントと調和しつつ区別可能 |
| **アクセント** | 10% | CTA、リンク、重要な通知 | 高い視認性、行動を促す |

#### HSBカラーシステムによる状態バリエーション

1つのベースカラーから彩度（S）と明度（B）を調整して状態を生成します。

```
ベースカラー: HSB(220, 80, 70)
├── Default:  HSB(220, 80, 70)  → メインの色
├── Hover:    HSB(220, 80, 80)  → 明度+10
├── Active:   HSB(220, 90, 60)  → 彩度+10, 明度-10
├── Disabled: HSB(220, 20, 50)  → 彩度-60, 明度-20
└── Focus:    HSB(220, 60, 85)  → 彩度-20, 明度+15
```

#### P3色域の活用

最新ディスプレイ向けにP3色域を活用し、sRGBフォールバックを必ず提供します。

```css
:root {
  /* sRGBフォールバック */
  --color-accent: #4f46e5;
  /* P3色域（対応ディスプレイで鮮やかに表示） */
  --color-accent: color(display-p3 0.31 0.27 0.90);
}
```

#### ゲームUI向けカラー心理

ゲームUIの場合、以下のセマンティックカラーを必ず定義します。

| セマンティック名 | 色相 | 用途 |
|---------------|------|------|
| `--color-danger` | 赤系 | ダメージ、緊急、リトライ |
| `--color-info` | 青系 | ナビゲーション、ツールチップ |
| `--color-heal` | 緑系 | 回復、安全、正のフィードバック |
| `--color-achievement` | 金/黄系 | 実績、エネルギー、レアリティ |

### 3. タイポグラフィスケール

#### バリアブルフォントの推奨

| 用途 | 推奨フォント | フォールバック |
|------|------------|-------------|
| 見出し（日本語） | Noto Sans JP Variable | "Hiragino Kaku Gothic ProN", sans-serif |
| 見出し（英語） | Inter Variable | system-ui, sans-serif |
| 本文（日本語） | Noto Sans JP Variable | "Hiragino Kaku Gothic ProN", sans-serif |
| コードブロック | JetBrains Mono | "Fira Code", monospace |

#### 流動的タイポグラフィスケール

`clamp()` を使用してブレイクポイント不要のレスポンシブ化を実現します。

```css
:root {
  /* タイポグラフィスケール（流動的） */
  --font-size-xs:   clamp(0.694rem, 0.66rem + 0.17vw, 0.8rem);
  --font-size-sm:   clamp(0.833rem, 0.78rem + 0.27vw, 1rem);
  --font-size-base: clamp(1rem, 0.93rem + 0.36vw, 1.25rem);
  --font-size-md:   clamp(1.2rem, 1.1rem + 0.5vw, 1.563rem);
  --font-size-lg:   clamp(1.44rem, 1.3rem + 0.7vw, 1.953rem);
  --font-size-xl:   clamp(1.728rem, 1.53rem + 0.99vw, 2.441rem);
  --font-size-2xl:  clamp(2.074rem, 1.79rem + 1.42vw, 3.052rem);

  /* 行間 */
  --line-height-tight:  1.2;  /* 見出し向け */
  --line-height-normal: 1.6;  /* 本文向け（日本語は広めに） */
  --line-height-loose:  1.8;  /* 長文読解向け */

  /* 字間 */
  --letter-spacing-tight:  -0.02em;  /* 大見出し */
  --letter-spacing-normal:  0;       /* 本文 */
  --letter-spacing-wide:    0.05em;  /* キャプション・ラベル */
}
```

### 4. スペーシング・レイアウトトークン

#### スペーシングスケール（8pxベース）

```css
:root {
  --space-1:  0.25rem;  /*  4px */
  --space-2:  0.5rem;   /*  8px */
  --space-3:  0.75rem;  /* 12px */
  --space-4:  1rem;     /* 16px */
  --space-5:  1.5rem;   /* 24px */
  --space-6:  2rem;     /* 32px */
  --space-7:  3rem;     /* 48px */
  --space-8:  4rem;     /* 64px */
  --space-9:  6rem;     /* 96px */
  --space-10: 8rem;     /* 128px */
}
```

#### レイアウトトークン

```css
:root {
  /* コンテンツ幅 */
  --content-width-sm:   640px;
  --content-width-md:   768px;
  --content-width-lg:  1024px;
  --content-width-xl:  1280px;
  --content-width-2xl: 1536px;

  /* 角丸 */
  --radius-sm:   0.25rem;
  --radius-md:   0.5rem;
  --radius-lg:   0.75rem;
  --radius-xl:   1rem;
  --radius-full: 9999px;

  /* シャドウ（ダークモード対応） */
  --shadow-sm:  0 1px 2px var(--color-shadow);
  --shadow-md:  0 4px 6px var(--color-shadow);
  --shadow-lg:  0 10px 15px var(--color-shadow);
  --shadow-xl:  0 20px 25px var(--color-shadow);
}
```

### 5. ダークモード対応

CSSカスタムプロパティで完全なダークモードを実装します。

```css
/* ライトモード（デフォルト） */
:root {
  --color-bg-primary:    #ffffff;
  --color-bg-secondary:  #f8f9fa;
  --color-bg-tertiary:   #e9ecef;
  --color-text-primary:  #1a1a2e;
  --color-text-secondary: #495057;
  --color-text-muted:    #868e96;
  --color-border:        #dee2e6;
  --color-shadow:        rgba(0, 0, 0, 0.1);
  --color-accent:        #4f46e5;
  --color-accent-hover:  #4338ca;
  --color-success:       #10b981;
  --color-warning:       #f59e0b;
  --color-danger:        #ef4444;
}

/* ダークモード */
[data-theme="dark"],
@media (prefers-color-scheme: dark) {
  :root {
    --color-bg-primary:    #0f0f1b;
    --color-bg-secondary:  #1a1a2e;
    --color-bg-tertiary:   #252540;
    --color-text-primary:  #e4e4e7;
    --color-text-secondary: #a1a1aa;
    --color-text-muted:    #71717a;
    --color-border:        #2d2d44;
    --color-shadow:        rgba(0, 0, 0, 0.4);
    --color-accent:        #818cf8;
    --color-accent-hover:  #a5b4fc;
    --color-success:       #34d399;
    --color-warning:       #fbbf24;
    --color-danger:        #f87171;
  }
}
```

#### ダークモード設計の注意点

- 純黒（#000）を背景に使わない（目の疲労を招く）
- 7段階のグレースケールで深度を表現する
- アクセントカラーはライトモードより彩度を下げ、明度を上げる
- シャドウの不透明度をダークモードでは高めに設定する

### 6. コンポーネント命名規約

#### トークン命名パターン

```
--{カテゴリ}-{プロパティ}-{バリアント}

例:
--color-bg-primary
--color-text-secondary
--font-size-lg
--space-4
--radius-md
--shadow-lg
```

#### セマンティック命名の優先

生の色値ではなくセマンティック名を使用します。

```css
/* 非推奨: 生の色名 */
--blue-500: #4f46e5;

/* 推奨: セマンティック名 */
--color-accent: #4f46e5;
--color-interactive: var(--color-accent);
--color-link: var(--color-accent);
```

#### コンポーネントトークン

```css
/* ボタン */
--btn-bg: var(--color-accent);
--btn-text: var(--color-text-on-accent);
--btn-radius: var(--radius-md);
--btn-padding-x: var(--space-4);
--btn-padding-y: var(--space-2);

/* カード */
--card-bg: var(--color-bg-secondary);
--card-border: var(--color-border);
--card-radius: var(--radius-lg);
--card-padding: var(--space-5);
--card-shadow: var(--shadow-md);

/* 入力フィールド */
--input-bg: var(--color-bg-primary);
--input-border: var(--color-border);
--input-focus-border: var(--color-accent);
--input-radius: var(--radius-md);
--input-padding: var(--space-2) var(--space-3);
```

## 出力形式

デザインシステムの成果物は以下の構造で出力してください。

```markdown
# デザインシステム: [プロジェクト名]

## メタ情報
- 種別: [プロジェクト種別]
- ターゲット: [ユーザー像]
- トーン: [トーン&マナー]

## カラーパレット
[60-30-10の定義とCSS変数]

## タイポグラフィ
[フォント選定とスケール定義]

## スペーシング
[スペーシングスケールとレイアウトトークン]

## ダークモード
[カスタムプロパティの完全な定義]

## コンポーネントトークン
[ボタン、カード、入力フィールド等の定義]

## 使用例
[各トークンの適用例コードスニペット]
```
