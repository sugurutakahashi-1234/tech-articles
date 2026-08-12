# Project Claude Code instructions

## 記事執筆について
- 記事を書く・修正する際は、明示的な指示がない限り他の記事を参考にしないこと
- 基本的にはその記事の中で完結するように対応すること

## 転載記事について（ZENSHIN 技術ブログからのクロスポスト）
- `articles/` には [ZENSHIN 技術ブログ](https://tech.zenshin-inc.co.jp/)からの転載記事が含まれる（冒頭に転載メッセージがあるもの）
- 手順・変換ルールの正本は zenshin-tech リポジトリの `zenn-crosspost` スキル（`docs/agent-instructions/skills/zenn-crosspost/`）。ここには最小限の規約のみ置く
- 転載記事は冒頭の `:::message` による転載表記 + 元記事（tech.zenshin-inc.co.jp）リンクが必須。Zenn は外部 canonical を張れないため、これを消すと検索・AI 検索の入口を Zenn 側に奪われる
- 全量転載はしない。対外発信したい代表作のみユーザーが選択して転載する
- 転載記事は公開時点のスナップショット扱い。元記事を更新しても Zenn 版への追従義務は負わない
- 画像・図はこのリポジトリに置かず、`https://tech.zenshin-inc.co.jp` の絶対 URL を直参照する
- 転載メッセージ末尾に絵文字（👇 など）を置かない（画面幅によって絵文字だけ折り返して見た目が崩れる）
- 公開フロー: `published: false` で作成 → `bun run preview` で確認 → `published: true` にして push で公開
- `published` の変更・commit・push はユーザーの明示指示があるまで行わないこと
