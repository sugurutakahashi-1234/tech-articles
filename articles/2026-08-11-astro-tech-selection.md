---
title: "会社ホームページを Next.js ではなく Astro で作った理由"
emoji: "🚀"
type: "tech"
topics: ["astro", "nextjs", "cloudflare", "tailwindcss", "frontend"]
published: true
---

:::message
この記事は [ZENSHIN 技術ブログ](https://tech.zenshin-inc.co.jp/) で 2026-04-12 に公開した記事の転載です。元記事はこちら:

https://tech.zenshin-inc.co.jp/blog/tech-selection/
:::

株式会社ZENSHINのCTOの高橋です。[ZENSHINのホームページ](https://www.zenshin-inc.co.jp/)を Astro で構築しました。技術選定の経緯と、実際に使ってみた感想をご紹介します。

https://astro.build

## なぜ Astro を選んだのか

以前から Astro の存在は知っており、調べていくうちに良さそうだなとは感じていました。ホームページに必要な要件を整理してみたところ、Astro で対応できそうなものばかりだったのが採用の決め手になりました。

- SEO 対応（サイトマップ生成、メタタグ管理、構造化データ）が揃っている
- Cloudflare Pages へのデプロイが簡単
- マークダウンでコンテンツを管理する仕組みが組み込まれている
- ログイン機能のようなインタラクティブな要件がない
- お問い合わせフォームのようなサーバー処理は Cloudflare Pages Functions で対応できる

もちろん Next.js も候補に挙がりました。ただ今回のホームページでは状態管理やクライアントサイドルーティング、仮想 DOM を使う場面がなく、React のランタイムを載せる必要がありませんでした。

素の HTML / CSS で作る方法もありますが、SEO 周りやコンテンツ管理、画像最適化の仕組みを一から整えるのはなかなか大変です。Astro はそのあたりがちょうどよく揃っていて、ぴったりのフレームワークでした。

## Cloudflare による買収と長期サポート

Astro を選ぶ上でもう一つ大きかったのが、2025 年の [Cloudflare による Astro の買収](https://astro.build/blog/the-next-chapter-of-astro/)です。

私たちはもともと Cloudflare Pages でホスティングしているので、フレームワークとホスティングが同じエコシステムに統合されたのは嬉しいポイントでした。長期的なサポートやプラットフォーム最適化も期待できます。

静的サイトのフレームワーク選定で気になるのは、プロジェクトの開発が止まってしまうリスクです。OSS は優れたものでも、メンテナンスが止まると使い続けにくくなります。

Cloudflare のバックアップがあるという点は、安心して採用に踏み切れる大きな材料になりました。

## React なしでも問題なく作れた

Astro では React を使わなくても、ホームページに必要な機能は一通り揃っています。実際に今回のサイトは React なしで構築しましたが、特に困る場面はありませんでした。

Astro コンポーネント（`.astro` ファイル）は HTML をそのまま書く感覚で使えます。

```astro
---
const { title, date } = Astro.props;
---
<article>
  <h1>{title}</h1>
  <time>{date}</time>
  <slot />
</article>
```

ハンバーガーメニューやスクロール検知などのインタラクションはバニラ JS で対応しました。もちろん React を使うこともできますが、このホームページぐらいの規模であれば React なしでも全然問題なくカバーできています。

## Content Collections で CMS が不要に

コンテンツ管理の面でも Astro の仕組みがうまくハマりました。

Astro には Content Collections という機能があり、マークダウンファイルを Zod スキーマで型安全に管理できます。この[ホームページ](https://www.zenshin-inc.co.jp/)では 6 つのコレクションをすべてマークダウンで運用しています。

| コレクション | 用途                                                   |
| ------------ | ------------------------------------------------------ |
| News         | [お知らせ](https://www.zenshin-inc.co.jp/news/)        |
| Blog         | [技術ブログ](https://tech.zenshin-inc.co.jp/)          |
| Works        | [事例紹介](https://www.zenshin-inc.co.jp/works/)       |
| Members      | [メンバー紹介](https://www.zenshin-inc.co.jp/company/) |
| Positions    | [採用情報](https://www.zenshin-inc.co.jp/recruit/)     |
| Services     | [事業内容](https://www.zenshin-inc.co.jp/services/)    |

Zod のバリデーションにより CMS を導入しなくてもコンテンツの整合性を保てるので、私たちのような少人数のチームでは Git 管理だけでうまく回っています。

## ビルドの速さと依存の少なさ

開発体験の面でも良い点がありました。

このサイトでは React を使っていないため、ビルドが非常に軽量です。15 ページのビルドが **1秒未満** で完了します。フィードバックループが短く、スムーズに開発を進められました。

本番環境の依存パッケージも **7 つ**だけです。

- Astro 本体
- サイトマップ生成
- Tailwind CSS Typography プラグイン
- フォント × 2
- Zod
- astro check

依存が少ないと、アップデート対応やセキュリティの面でも安心です。

## おわりに

Next.js でもホームページは作れますし、プロジェクトによっては Next.js がベストな場面もあると思います。今回はシンプルな構成で済む要件だったので、Astro がぴったりでした。

必要なものがちょうどよく揃っていて、余計なものを持ち込まずに済む。Cloudflare による長期的なサポートも期待できる。私たちのホームページの技術基盤として、良い選択ができたと感じています。

---

ZENSHIN ではエンジニアを募集しています。こうした技術選定や開発に興味がある方は、ぜひご覧ください。

https://www.zenshin-inc.co.jp/recruit/
