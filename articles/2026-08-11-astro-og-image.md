---
title: "Astro 製ブログの OGP 画像を Satori + sharp でビルド時に自動生成する"
emoji: "🖼️"
type: "tech"
topics: ["astro", "satori", "sharp", "ogp", "typescript"]
published: true
---

:::message
この記事は [ZENSHIN 技術ブログ](https://tech.zenshin-inc.co.jp/) で 2026-04-17 に公開した記事の転載です。元記事はこちら:

https://tech.zenshin-inc.co.jp/blog/astro-og-image-generation/
:::

[ZENSHIN の技術ブログ](https://tech.zenshin-inc.co.jp/)に、記事ごとの OGP 画像を自動生成する仕組みを入れました。Slack や X で記事 URL を共有したときに、記事固有のサムネイルが展開されます。

ちなみに、上のリンクカードに表示されているのが元記事の OGP です（本題のとおり、ビルド時に自動生成された PNG です）。

この記事では Astro で OGP 画像を生成する選択肢と、今回採用した Satori + sharp の実装方法を紹介します。

## なぜ記事ごとの OGP 画像が必要なのか

OGP を 1 枚の固定画像にしていると、どの記事を共有しても同じサムネイルが出ます。タイムラインに複数並んだときに区別がつきづらく、クリック率にも影響しそうです。

記事ごとに画像を用意すればタイトルがサムネイルに入り、内容が一目で伝わります。とはいえ毎回 Figma で作って書き出すのは手間なので、ビルド時に自動生成する仕組みを入れました。

## Astro で OGP 画像を生成する方法の比較

代表的な選択肢を、今回の要件（静的ビルド + 日本語 + 凝ったレイアウト）に対する採用しやすさ順で並べます。

| 方法                          | 特徴                                                                                                                           |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Satori + sharp（今回採用）    | JSX 風の記述で SVG を組み立て、sharp で PNG に変換。Astro の画像サービスが既に sharp を使っているため依存を増やさずに済む      |
| Satori + @resvg/resvg-js      | SVG→PNG のラスタライズだけ軽量な resvg-js に任せる構成。Workers など Edge で動的生成する時に強いが、sharp は結局残るので二重化 |
| @vercel/og                    | 内部で Satori を使う Vercel 製ラッパー。Next.js / Edge Runtime 向けの最適化が効くが、Astro 静的ビルドから使う旨味は薄い        |
| astro-og-canvas               | Astro 向けの Canvas ベースパッケージ。手早く書ける反面、flex レイアウトのような柔軟な記述は難しい                              |
| Puppeteer / Playwright        | ヘッドレスブラウザでスクショ。既存の HTML/CSS をそのまま使えるが、Chromium バイナリ (~300 MB) のコストが重い                   |
| 外部サービス（Cloudinary 等） | 動的生成はしやすいが、外部依存・コスト・ビルド時の API 呼び出しが発生する                                                      |

今回は **Satori + sharp** を採用しました。選んだ理由は次のあたりです。

- Astro の画像最適化が既に sharp を使っているので、OG 用に新たな依存を増やさず同じライブラリで完結できる
- Astro の [Fonts API ドキュメント](https://docs.astro.build/en/reference/experimental-flags/fonts/)のサンプルコードでも Satori + sharp が使われていて、エコシステムから大きく外れなさそうだった
- JSX 風のオブジェクトに CSS の `flex` や `padding` を指定でき、Figma のようなレイアウト感覚で書ける
- 外部サービスに依存せず、ビルド時に `dist/og/blog/<slug>.png` として静的ファイルが出力される
- Cloudflare Pages の静的ホスティングにそのまま乗せられる

2 番目の候補は **Satori + @resvg/resvg-js** でした。Cloudflare Workers で動的 OG 生成をしたくなった時に移植しやすい（sharp は workerd で動かないが resvg-js は動く）のが利点ですが、今回は静的ビルド前提で sharp も Astro の画像サービスでどのみち必要なため見送りました。

## Satori + sharp の役割分担

2 つのライブラリの役割を整理します。

- **[Satori](https://github.com/vercel/satori)**: JSX 風のオブジェクトを受け取って SVG を返す Vercel 製ライブラリ。`@vercel/og` の内部でも使われている
- **[sharp](https://github.com/lovell/sharp)**: 画像変換ライブラリ。SVG を PNG (1200x630) にラスタライズする

Satori は SVG しか出力しないため、OGP に必要な PNG 化は sharp に任せます。

## 実装のポイント

レンダリング処理を共通モジュールに切り出し、ブログとニュースのエンドポイントから呼び出す構成です。

- `src/lib/og-image.ts`: Satori でレイアウトを組み sharp で PNG 化する共通ロジック
- `src/pages/og/blog/[slug].png.ts` / `src/pages/og/news/[slug].png.ts`: コレクションを列挙して共通ロジックを呼ぶ薄いエンドポイント

### 動的ルートで全記事の OGP を生成

Astro の `getStaticPaths` でコレクションを列挙し、記事ごとに `/og/blog/<slug>.png` を生成します。ファイル名を `[slug].png.ts` のように拡張子付きで書くと、そのまま出力の拡張子になります。

```ts:src/pages/og/blog/[slug].png.ts
export const getStaticPaths: GetStaticPaths = async () => {
  const posts = await getCollection("blog");
  return posts.map((post) => ({
    params: { slug: post.data.slug },
    props: { post },
  }));
};

export const GET: APIRoute<Props> = async ({ props }) => {
  const png = await renderOgImage({
    label: "株式会社ZENSHIN 技術ブログ",
    title: props.post.data.title,
    author: await resolveAuthor(props.post.data.author.id),
  });
  return new Response(new Uint8Array(png), {
    headers: { "Content-Type": "image/png" },
  });
};
```

### Content Collections の `reference` で著者情報を型安全に繋ぐ

OGP 左下に著者の顔写真・氏名・役職を出したかったので、ブログの frontmatter に `author` を持たせて [Content Collections の `reference()`](https://docs.astro.build/en/guides/content-collections/#defining-collection-references) でメンバー情報と関連付けています。

文字列で緩く持つと typo や存在しない ID で実行時に落ちがちですが、`reference()` を使うとビルド時に存在チェックが入るので、記事とメンバーの整合を CI で担保できます。

```ts:src/content.config.ts
const blog = defineCollection({
  schema: z.object({
    title: z.string().max(20),
    // ...
    author: reference("members"),
  }),
});
```

記事側はメンバーファイル名（= ID）をそのまま指定するだけです。

```yaml
---
title: 技術ブログのOGP画像を自動生成した話
author: 05-takahashi
---
```

OGP エンドポイント側では `getEntry()` で実体を引いて、メンバーコレクションに持たせている `name` / `role` / `image` をそのまま渡しています。

```ts
const member = await getEntry("members", post.data.author.id);
const author = {
  name: member.data.name,
  role: member.data.role,
  imageDataUri: await toPngDataUri(memberImagePath, 200),
};
```

存在しない ID に変えるとビルドが失敗するので、「画像生成のための情報」とコンテンツ側のデータが自然に揃います。

### Zod スキーマで OGP の見栄えを守る

実装中にいちばん悩んだのが、**タイトルが長すぎて画像から溢れるケース**です。CSS の `text-overflow: ellipsis` で見切れさせることもできますが、途中で切れた OGP ではタイトルが伝わりません。

そこで、描画側で頑張って収めるのではなく、**コンテンツ側のバリデーションで最初から収まるタイトルだけ通す**方針にしました。Astro の Content Collections は Zod スキーマでフロントマターを検証できるので、タイトル長に上限を設けておけば、超過したマークダウンを置いた瞬間にビルドが落ちて気付けます。

```ts:src/content.config.ts
const blog = defineCollection({
  schema: z.object({
    // OGP で 1 行に収めるため 20 文字まで
    title: z.string().max(20),
    // ...
  }),
});

const news = defineCollection({
  schema: z.object({
    // OGP で 2 行に収まる想定で 40 文字まで
    title: z.string().max(40),
    // ...
  }),
});
```

ブログは 1 行固定で 20 文字、ニュースはやや緩めて 2 行想定で 40 文字、というようにコレクションごとに上限を変えています。タイトルの長さが自然と揃うので、一覧ページのカード UI でも改行位置が安定し、OGP 以外にも効いてくるのが良かったです。

## Astro の Content Collections と OGP 生成が綺麗に噛み合った

今回あらためて実感したのは、**コンテンツ管理（Content Collections）と OGP 画像生成が同じスキーマの上で動く**ことの気持ちよさです。

- 記事の本文・frontmatter は Zod で検証済み（タイトル長、カテゴリ、著者 ID の存在…）
- その Zod で検証済みのデータを `getCollection("blog")` / `getEntry("members", ...)` で型付きで取り出して、そのまま Satori に流し込んで OGP を生成
- 一覧ページ・詳細ページ・JSON-LD・OGP のすべてが同じ data source を見ているので、**「記事を追加したら OGP も一覧も検索インデックスも同時に更新される」**

### 動的 OG 生成が要らないのも Astro らしさ

もうひとつ嬉しかったのは、**そもそも動的 OG 生成が要らない**点です。OG 画像は Cloudflare Workers / Edge Function で動的に返すのが一般的ですが、Astro は Content Collections と `getStaticPaths` の組み合わせで**ビルド時に全記事の URL を列挙できる**ので、OG も単なる静的 PNG として書き出せます。

- ランタイムコスト・コールドスタートがゼロ
- Workers の実行クォータや課金を気にしなくていい
- 生成済み PNG が CDN に乗るので配信が速い

Next.js の `@vercel/og` のように Edge Runtime で動的生成するアプローチと比べると、Astro の「**コンテンツはリポジトリにある**」「**ビルド時に全部焼く**」という静的ファーストな設計思想が OG 生成と素直に噛み合っています。SSR を出せるかどうかではなく、そもそも出さずに済むように設計されているのが Astro の良さです。

CMS を別立てにしていたらここは結構めんどくさくて、Content Collections が Zod と結びついている Astro だからこそ素直に書けた部分でした。「なぜ Astro を選んだか」は元ブログの別記事に書いているので、合わせてどうぞ。

https://tech.zenshin-inc.co.jp/blog/tech-selection/

## ハマりどころまとめ

実装中に引っかかった点をまとめておきます。同じ構成を試す方の参考になれば幸いです。

- **Satori は WebP を埋め込めない**: ロゴが `.webp` だったので、sharp で PNG に変換してから data URI 化する必要がありました
- **CSS 変数は展開されない**: Tailwind のセマンティックカラートークン（`var(--color-surface-dark)` のような書き方）は使えないので、`@theme` で定義した値をそのままハードコードしています
- **大きな画像を原寸のまま data URI 化すると sharp が落ちる**: 著者アバター（元画像 ~1MB の JPG）を原寸で埋め込んだら、sharp 内部の XML パーサが ~10MB のバッファ上限に当たってビルド失敗。`sharp(path).resize(200, 200, { fit: "cover" })` で表示サイズ相当に先に縮めて解決しました
- **タイトル長の扱い**: `text-overflow: ellipsis` で切るより、Zod で縛って最初から収めるほうが見栄えが安定しました
- **ビルド時間**: 1 記事あたり ~100ms 程度。記事が増えても気にならない範囲です

## おわりに

記事ごとの OGP 画像を自動生成できるようになり、コンテンツ制作の手間を増やさずにシェア時の見え方を整えられました。Astro + Satori + sharp の組み合わせは今回のサイト規模でもさっと入れられて、やってみて良かったです。

---

ZENSHIN ではエンジニアを募集しています。こうした技術選定や開発に興味がある方は、ぜひご覧ください。

https://www.zenshin-inc.co.jp/recruit/
