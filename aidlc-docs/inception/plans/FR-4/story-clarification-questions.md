# FR-4 Clarification Questions

回答の一部に曖昧な点がありました。以下の3問に回答してください。

---

## Clarification 1: AI生成画像のタイミング（Q4の明確化）

Q4で「A+B」と回答されましたが、具体的な運用を明確にさせてください。

A) 進化時に新画像生成 + 毎日ステータス変化に応じて微調整画像を更新（両方フル実装）
B) 進化時に新画像生成（メイン）+ 日次で表情・サイズなど軽微なビジュアル変化（簡易更新）
C) Other (please describe after [Answer]: tag below)

[Answer]: B

## Clarification 2: 受け入れ基準フォーマット（Q7のおすすめ）

ハッカソンMVPという文脈では **B) チェックリスト形式** をおすすめします。

理由:
- Given-When-Thenは厳密だが記述量が多く、ハッカソンのスピード感に合わない
- チェックリスト形式なら「この条件を満たせばOK」が一目でわかり、実装・テストが速い

A) おすすめ通り B（チェックリスト形式）で進める
B) やはり Given-When-Then（BDD形式）がいい
C) Both（主要フローはGiven-When-Then、補足はチェックリスト）
D) Other (please describe after [Answer]: tag below)

[Answer]: A

## Clarification 3: スコアシステムの詳細度（Q8のおすすめ）

**B) 中程度（行動カテゴリ × 時間帯 × 頻度で変動）** をおすすめします。

理由:
- Aのシンプル固定ポイントだと「深夜ラーメンは昼ラーメンより背徳感が高い」を表現できない
- Cの複雑ロジックはMVPでは実装コストが高すぎる
- Bなら「深夜帯の暴食はボーナス」「3日連続夜更かしで倍率」など、ダメ人間の快感ポイントを適度に表現できる

A) おすすめ通り B（中程度）で進める
B) やはり A（シンプル固定）でMVP優先
C) やはり C（複雑）でゲーム性を重視
D) Other (please describe after [Answer]: tag below)

[Answer]: A
