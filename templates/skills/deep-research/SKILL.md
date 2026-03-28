---
name: deep-research
description: 体系的調査・リサーチを実施します。文献レビュー、SIFT メソッドによる情報源評価、CRAAP テストによる信頼性判定、ラテラルリーディング、ニュース収集、競合分析を統合的に行います。研究設計から情報源の特定・評価・統合・レポート作成まで、エビデンスに基づくリサーチプロセス全体を支援します。
allowed-tools:
  - WebSearch
  - WebFetch
  - Read
  - Write
  - Bash
---

# ディープリサーチ

体系的な調査プロセスに従い、信頼性の高い情報を収集・評価・統合してリサーチレポートを作成します。

---

## 1. 研究設計: リサーチクエスチョンの定義

### PICO/PEO フレームワーク

調査開始前に、リサーチクエスチョンを構造化する。

**PICO（介入・比較研究向け）**
- **P**opulation: 対象（誰・何を調べるか）
- **I**ntervention: 介入・手段（何を適用するか）
- **C**omparison: 比較対象（何と比べるか）
- **O**utcome: 成果指標（何を測定するか）

**PEO（探索的リサーチ向け）**
- **P**opulation: 対象
- **E**xposure: 曝露・要因
- **O**utcome: 成果

### リサーチクエスチョンの品質基準

- 具体的で回答可能な問いであること
- スコープが明確（広すぎず狭すぎず）であること
- 評価可能な成功基準を含むこと

**例:**
```
悪い例: 「AIについて調べてください」
良い例: 「2025年以降の日本のSaaS企業において、
        AI コーディングアシスタント（Intervention）の導入が、
        開発チームの生産性（Outcome）にどの程度影響したか」
```

---

## 2. 検索戦略の設計

### 検索キーワードの体系化

1. リサーチクエスチョンの各要素からキーワードを抽出する
2. 各キーワードの同義語・関連語を列挙する
3. ブール演算子（AND / OR / NOT）で組み合わせる
4. 日本語と英語の両方でキーワードを準備する

### 検索ソースの優先順位

```
1. 一次情報源（公式文書、統計データ、学術論文）
2. 通信社（共同通信、時事通信、AP、Reuters）
3. 全国紙・公共放送
4. 専門メディア（IT系、経済系）
5. 個人ブログ・技術ブログ（実績ある著者のみ）
6. SNS・掲示板（裏取り必須）
```

### WebSearch / WebFetch の実行手順

```
手順1: WebSearch でキーワード検索（日本語・英語それぞれ）
手順2: 検索結果の上位ソースを SIFT で評価
手順3: 信頼性の高いソースを WebFetch で全文取得
手順4: 取得した情報を構造化して整理
手順5: 不足があれば検索キーワードを修正して再検索
```

---

## 3. 情報源の評価

### SIFT メソッド（4ステップ、必ず実行）

**S - Stop（立ち止まる）**
- 情報を見た瞬間に反応せず、まず立ち止まる
- その情報源について自分が何を知っているか確認する
- 知らない情報源であれば、次のステップへ進む

**I - Investigate the source（情報源を調べる）**
- 情報源の運営者・著者は誰か
- 専門性・実績・評判はどうか
- Wikipedia、About ページ、第三者の評価を確認する

**F - Find better coverage（より良い情報源を探す）**
- 同じ話題を扱う他の情報源を探す
- 複数の独立した情報源が同じ事実を報じているか確認する
- 通信社や公的機関の発表まで遡れるか確認する

**T - Trace claims（主張を遡る）**
- 元の研究・データ・発言を特定する
- 引用が正確か、文脈が歪められていないか確認する
- 一次情報源にたどり着けるか確認する

### CRAAP テスト（5基準）

| 基準 | チェック項目 |
|------|------------|
| **C**urrency（時宜性） | 情報はいつ公開・更新されたか。調査目的に対して十分新しいか |
| **R**elevance（関連性） | 情報はリサーチクエスチョンに直接関連するか。対象読者は適切か |
| **A**uthority（権威性） | 著者・発行元の専門性と資格。連絡先・所属は明示されているか |
| **A**ccuracy（正確性） | 証拠・データに裏付けられているか。他の情報源と整合するか。査読済みか |
| **P**urpose（目的） | 情報提供・説得・販売・娯楽のどれか。バイアスは明示されているか |

### ラテラルリーディング（横断的読解）

- 1つの情報源を深く読む前に、その情報源について他者が何を言っているかを確認する
- 複数のタブを開き、横断的に情報源の評判を調べる
- スタンフォード大学の研究で、プロのファクトチェッカーの行動と一致することが検証済み

### ROBOT テスト（AI生成コンテンツの評価）

| 基準 | チェック項目 |
|------|------------|
| **R**eliability（信頼性） | AI ツール自体の信頼性。既知の限界は何か |
| **O**bjective（客観性） | 出力は事実に基づいているか。ハルシネーションの兆候はないか |
| **B**ias（バイアス） | 訓練データに起因する偏りはないか |
| **O**wner（所有者） | AI ツールの開発元・運営方針は透明か |
| **T**echnology（技術） | 使用されている技術の限界を理解しているか |

**重要: LLM の出力は二次情報源として扱い、必ず一次情報源で検証する。**
UNESCO の 2024 年データによれば、AI 検索エンジンは約 60% の確率で不正確なニュースソースを引用する。

---

## 4. 情報源リスト

### 日本のニュースソース

#### 通信社（一次ソース、最高信頼度）

| サイト名 | URL | 特徴 |
|----------|-----|------|
| 共同通信（47NEWS） | https://www.47news.jp/ | 日本最大の通信社。全国の地方紙と連携 |
| 時事ドットコム | https://www.jiji.com/ | 速報・政治・経済・国際に強い。RSS充実 |
| ロイター日本語版 | https://jp.reuters.com/ | 国際ニュース・金融情報（2024年〜一部有料化） |
| AFP BB News | https://www.afpbb.com/ | 国際ニュース・科学 |

#### 全国紙・公共放送

| サイト名 | URL | 特徴 |
|----------|-----|------|
| NHK NEWS WEB | https://www3.nhk.or.jp/news/ | 公共放送。中立性・防災情報 |
| Yahoo!ニュース | https://news.yahoo.co.jp/ | 最大のアグリゲーター。完全無料、RSS充実 |
| 読売新聞オンライン | https://www.yomiuri.co.jp/ | 購読者数日本一（一部無料） |
| 朝日新聞デジタル | https://www.asahi.com/ | 老舗ニュースサイト |
| 産経ニュース | https://www.sankei.com/ | 無料記事が比較的多い |

#### IT・テクノロジー専門

| サイト名 | URL | 特徴 |
|----------|-----|------|
| ITmedia NEWS | https://www.itmedia.co.jp/news/ | 国内最大級。AI・クラウド・セキュリティ網羅 |
| GIGAZINE | https://gigazine.net/ | 2000年開設の老舗。テクノロジーからサイエンスまで |
| CNET Japan | https://japan.cnet.com/ | IT業界のビジネス動向・製品レビュー |
| Publickey | https://www.publickey1.jp/ | クラウド・コンテナ・開発ツールの速報 |
| @IT | https://atmarkit.itmedia.co.jp/ | エンジニア向け技術解説 |
| Qiita | https://qiita.com/ | エンジニア向け技術共有プラットフォーム |
| はてなブックマーク テクノロジー | https://b.hatena.ne.jp/hotentry/it | ユーザーキュレーション |

### 世界のニュースソース

#### 国際通信社・多言語放送（完全無料、RSS提供）

| サイト名 | URL | 特徴 |
|----------|-----|------|
| AP News | https://apnews.com | 三大通信社で唯一完全無料を維持 |
| BBC News | https://www.bbc.com/news | 世界最大の国際放送（42言語） |
| Deutsche Welle (DW) | https://www.dw.com | ドイツ公共放送（32言語） |
| NHK World-JAPAN | https://www3.nhk.or.jp/nhkworld/ | 日本・アジアの多言語ニュース（19言語） |
| France 24 | https://www.france24.com | アフリカ・中東に強い（4言語） |
| Al Jazeera | https://www.aljazeera.com | 中東最大のニュースネットワーク |

#### 北米（完全無料5強）

| サイト名 | URL | 特徴 |
|----------|-----|------|
| NPR | https://www.npr.org | 米国公共放送（非営利） |
| PBS NewsHour | https://www.pbs.org/newshour | 米国公共放送 |
| ProPublica | https://www.propublica.org | 独立非営利調査報道。データAPI公開 |
| The Guardian | https://www.theguardian.com | Web完全無料。Content API公開 |
| CBC News | https://www.cbc.ca/news | カナダ公共放送 |

#### 学術・公的機関

| サイト名 | URL | 特徴 |
|----------|-----|------|
| UN News | https://news.un.org | 国連活動・人道問題（6言語） |
| The Conversation | https://theconversation.com | 学者執筆・CC再利用可 |
| J-STAGE | https://www.jstage.jst.go.jp/ | 日本の学術論文を無料閲覧 |

### IT エンジニアブログ（分野別）

#### 言語設計・低レイヤ
- まつもとゆきひろ（Matz）: https://matz.rubyist.net/ （Ruby言語設計）
- Rui Ueyama: https://note.com/ruiu （コンパイラ・リンカ設計）

#### フロントエンド
- Dan Abramov「Overreacted」: https://overreacted.io/ （React内部哲学、RSC）
- Kent C. Dodds: https://kentcdodds.com/blog （テスト哲学、Reactフック）
- mizchi: https://mizchi.hatenablog.com/ （フロントエンド先端技術）
- yusukebe: https://yusukebe.com/ （Hono、エッジコンピューティング）
- Guillermo Rauch: https://rauchg.com/ （Next.js、フロントエンドアーキテクチャ）

#### バックエンド・アーキテクチャ
- Martin Fowler: https://martinfowler.com/ （リファクタリング、マイクロサービス、CI/CD）
- Joel Spolsky「Joel on Software」: https://www.joelonsoftware.com/ （1,114本以上、歴史的アーカイブ）
- DHH: https://world.hey.com/dhh （Ruby on Rails、モノリス vs マイクロサービス）
- Songmu: https://blog.song.mu/ （Go/Perl、ISUCON 3度優勝）

#### インフラ・パフォーマンス
- Julia Evans: https://jvns.ca/ （Linux内部、TCP/IP、DNS の平易な解説）
- Brendan Gregg: https://www.brendangregg.com/blog/ （フレームグラフ発明者、eBPF）

#### セキュリティ
- Troy Hunt: https://www.troyhunt.com/ （Have I Been Pwned 運営者、データ侵害分析）

#### AI・機械学習
- Andrej Karpathy: http://karpathy.github.io/ （深層学習のランドマーク記事）
- 清水亮: https://note.com/shi3zblog （生成AI最新動向、ほぼ毎日更新）

#### テスト・品質
- 和田卓人（t-wada）: https://t-wada.hatenablog.jp/ （TDD第一人者）

#### エンジニアリングマネジメント
- Gergely Orosz「The Pragmatic Engineer」: https://blog.pragmaticengineer.com/ （110万人以上の購読者）
- Paul Graham: https://paulgraham.com/articles.html （Y Combinator創業者、200本以上のエッセイ）

---

## 5. リサーチ実行ワークフロー

### ステップ 1: 準備

```
1. リサーチクエスチョンを PICO/PEO で構造化する
2. 検索キーワードを日本語・英語で準備する
3. 調査範囲（期間・地域・分野）を明確にする
4. 期待する成果物の形式を定義する
```

### ステップ 2: 情報収集

```
1. WebSearch で複数キーワードによる検索を実行
2. 情報源の優先順位に従い、信頼性の高いソースから着手
3. WebFetch で重要ページの全文を取得
4. 収集した情報を「事実」「意見」「推測」に分類
5. 情報の出典（URL、著者、日付）を記録
```

### ステップ 3: 評価・検証

```
1. 全ての情報源に SIFT メソッドを適用
2. 重要な情報源には CRAAP テストを実施
3. AI 生成コンテンツには ROBOT テストを追加
4. 矛盾する情報がある場合、一次情報源まで遡る
5. 事実関係を複数の独立した情報源で確認（三角測量）
```

### ステップ 4: 統合・レポート作成

```
1. 収集した情報をテーマ別に整理
2. 主要な発見事項を特定
3. エビデンスの強度を評価
4. レポートテンプレートに沿って構成
5. 全ての主張に出典を付与
```

---

## 6. リサーチレポートテンプレート

```markdown
# [調査テーマ]

## エグゼクティブサマリー
[調査の目的・主要な発見・結論を 3-5 文で要約]

## 調査方法
- リサーチクエスチョン: [PICO/PEO 形式]
- 調査期間: [yyyy-mm-dd 〜 yyyy-mm-dd]
- 検索キーワード: [使用したキーワード一覧]
- 情報源の種類と数: [通信社 X件、専門メディア Y件 等]

## 主要な発見事項

### 発見 1: [見出し]
[詳細な説明と根拠]
- 出典: [URL, アクセス日]

### 発見 2: [見出し]
[詳細な説明と根拠]
- 出典: [URL, アクセス日]

### 発見 3: [見出し]
[詳細な説明と根拠]
- 出典: [URL, アクセス日]

## 分析と考察
[発見事項の横断的分析、パターン・トレンドの特定]

## 結論と推奨事項
[調査から導かれる結論、次のアクション提案]

## 情報源一覧
[全ての参照情報源をリスト化、URL + アクセス日付]

## 調査の限界
[調査範囲の制約、情報の欠落、バイアスの可能性]
```

---

## 7. 品質チェックリスト

リサーチ完了前に以下を確認する。

- [ ] リサーチクエスチョンに対して回答が得られているか
- [ ] 全ての主張に出典（URL + アクセス日）が付与されているか
- [ ] SIFT メソッドを全情報源に適用したか
- [ ] 重要な事実を複数の独立した情報源で確認したか
- [ ] 情報源の偏り（特定メディアへの依存）がないか
- [ ] 「事実」と「意見・推測」が明確に区別されているか
- [ ] AI 生成コンテンツを二次情報源として扱い、一次情報源で検証したか
- [ ] 調査の限界を明示しているか
