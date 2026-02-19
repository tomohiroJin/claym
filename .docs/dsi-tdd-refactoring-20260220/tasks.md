# Deep Sea Interceptor TDD リファクタリング タスク

## Phase 0: 基盤整備
- [x] 0-1. `entities.ts` に `isBoss()` DRY ヘルパー関数を追加（テスト先行）
- [x] 0-2. `types.ts` に `AudioEvent` 型を追加
- [x] 0-3. `test-helpers.ts` に `buildGameState()` / `buildUiState()` テストファクトリ作成
- [x] 0-4. `game-logic.ts`, `enemy-ai.ts` で `isBoss()` を利用するようリファクタ

## Phase 1: 武器ロジックの抽出
- [x] 1-1. `weapon.ts` 新規作成（テスト先行: `weapon.test.ts`）
  - `createBulletsForWeapon()` 純粋関数
  - `createChargedShot()` 純粋関数
- [x] 1-2. `hooks.ts` を `weapon.ts` を import して既存ロジックを置換

## Phase 2: updateFrame サブ関数抽出
- [x] 2-1. `resolvePlayerInput()` — キーボード/タッチ入力解決（テスト先行）
- [x] 2-2. `updatePlayerPosition()` — クランプ付き移動計算（テスト先行）
- [x] 2-3. `getMovementStrategy()` — テーブルルックアップ（`movement.ts` に追加、テスト先行）
- [x] 2-4. `processBulletEnemyCollisions()` — 弾-敵衝突判定（テスト先行）
- [x] 2-5. `processItemCollection()` — アイテム取得処理（テスト先行）
- [x] 2-6. `processPlayerDamage()` — プレイヤーダメージ判定（テスト先行）
- [x] 2-7. `checkStageProgression()` — ステージ遷移判定（テスト先行）

## Phase 3: updateFrame 合成再構築
- [x] 3-1. サブ関数を組み合わせて `updateFrame()` を再構成
- [x] 3-2. `AudioEvent[]` を集約し関数末尾で一括実行パターンに変更
- [x] 3-3. `getMovementStrategy()` で冗長な三項演算子を置換

## Phase 4: hooks.ts 責務整理
- [x] 4-1. `EntityFactory` / `Config` 直接参照を排除
- [x] 4-2. `weapon.ts` 関数で弾生成を統一
- [x] 4-3. gameover/ending イベント処理を簡素化

## テスト結果
- テストスイート: 5 → 6 (+1: weapon.test.ts)
- テスト数: 54 → 99 (+45)
- 全テスト PASS
