# tech articles

- Zenn:
  - https://zenn.dev/ikuraikura

## はじめに

このリポジトリでは [Zenn CLI](https://zenn.dev/zenn/articles/zenn-cli-guide) によって、Zenn の記事の投稿を管理しております。

- Zenn CLI:
  - https://zenn.dev/zenn/articles/zenn-cli-guide

Zenn のアカウントと紐付けられているこのリポジトリの [articles](https://github.com/suguruTakahashi-1234/tech-articles/tree/main/articles) に Zenn の記事を書き、それを push することで Zenn へ記事が投稿されます。

## 使い方

[articles](https://github.com/suguruTakahashi-1234/tech-articles/tree/main/articles) に Zenn 用の記事を書いて、push するだけです。

### 新しい記事の作成

```shell
npx zenn new:article
```

### 新しい本の作成

```shell
npx zenn new:book --slug book_slug_name
```

### プレビュー

```shell
npx zenn preview
```

## ディレクトリ構造

```
.
├── articles/ # 記事を格納するディレクトリ
├── books/    # 本を格納するディレクトリ
│   └── sample_book_example/ # サンプルブック
│       ├── config.yaml # 本の設定ファイル
│       ├── example1.md # 第1章
│       └── example2.md # 第2章
└── public/   # 画像などの静的ファイルを格納
