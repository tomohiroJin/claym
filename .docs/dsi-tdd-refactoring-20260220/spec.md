# Deep Sea Interceptor TDD リファクタリング 仕様書

## 概要

Deep Sea Interceptor のゲームロジックを TDD でリファクタリングし、
SOLID / DRY / 関数型（副作用分離）の原則に基づいてコード品質を改善する。

## 対象ファイル（local/cline-playground-for-frontend-wip03/src/features/deep-sea-interceptor/）

### 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `types.ts` | `AudioEvent` 型を追加 |
| `entities.ts` | `isBoss()` ヘルパー関数を追加 |
| `movement.ts` | `getMovementStrategy()` テーブルルックアップ関数を追加 |
| `game-logic.ts` | サブ関数6つ追加 + `updateFrame()` をサブ関数呼び出しで再構成 |
| `hooks.ts` | `EntityFactory`/`Config` 直接参照を排除、`weapon.ts` を利用 |
| `enemy-ai.ts` | `isBoss()` ヘルパー利用に変更 |

### 新規ファイル

| ファイル | 内容 |
|---------|------|
| `weapon.ts` | `createBulletsForWeapon()`, `createChargedShot()` 純粋関数 |
| `test-helpers.ts` | `buildGameState()`, `buildUiState()` テストファクトリ |
| `__tests__/weapon.test.ts` | 武器ロジック 7 テスト |

### テスト追加

| ファイル | 追加テスト数 | 内容 |
|---------|-------------|------|
| `entities.test.ts` | +3 | `isBoss()` テスト |
| `game-logic.test.ts` | +31 | サブ関数ユニットテスト |
| `movement.test.ts` | +4 | `getMovementStrategy()` テスト |
| `weapon.test.ts` | +7 | 武器ロジックテスト |

## 抽出されたサブ関数

### `resolvePlayerInput(keys, touchInput) → {dx, dy}`
キーボードとタッチ入力を解決して移動ベクトルを返す純粋関数。
キーボード入力がタッチ入力より優先される。

### `updatePlayerPosition(player, input, speed) → Position`
プレイヤー位置を更新し、画面端でクランプ済みの座標を返す純粋関数。

### `getMovementStrategy(enemyType, pattern) → MovementFunction`
敵タイプと移動パターンから移動戦略を選択するテーブルルックアップ関数。
冗長な三項演算子チェーンを排除。

### `processBulletEnemyCollisions(bullets, enemies, now) → CollisionResult`
弾と敵の衝突を処理し、スコア変動・アイテムドロップ・ボス撃破判定を返す純粋関数。
`CollisionResult = { bullets, enemies, scoreDelta, items, audioEvents, bossDefeated, bossDefeatedTime }`

### `processItemCollection(player, items, uiState, enemies, now) → ItemResult`
アイテム取得処理。各アイテムタイプの効果適用を返す純粋関数。
`ItemResult = { remainingItems, uiChanges, enemies, audioEvents, clearBullets }`

### `processPlayerDamage(player, enemies, enemyBullets, params, now) → DamageResult`
プレイヤーダメージ判定。無敵・シールド・ゲームオーバー判定を返す純粋関数。
`DamageResult = { hit, livesLost, invincible, invincibleEndTime, event, audioEvents }`

### `checkStageProgression(params, now) → StageResult`
ステージ遷移判定。ステージクリア・エンディング判定を返す純粋関数。
`StageResult = { event, nextStage, clearEnemies, resetBossDefeated, highScore }`

## 副作用分離パターン

リファクタリング前: `audioPlay()` がサブ関数内部で直接呼ばれていた
リファクタリング後: 各サブ関数が `AudioEvent[]` を返し、`updateFrame()` 末尾で一括実行

```typescript
// 各サブ関数は AudioEvent[] を返す
const collisionResult = processBulletEnemyCollisions(bullets, enemies, now);
allAudioEvents.push(...collisionResult.audioEvents);

// 関数末尾で一括実行（副作用を集約）
allAudioEvents.forEach(e => audioPlay(e.name));
```
