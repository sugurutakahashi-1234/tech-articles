---
title: "第2章: 基本的な使い方"
---

# 基本的な使い方

この章では、Zennの基本的な使い方を説明します。

## 記事の作成

```bash
npx zenn new:article
```

## 本の作成

```bash
npx zenn new:book --slug book_slug_name
```

## プレビュー

```bash
npx zenn preview
```

これらのコマンドを使用して、コンテンツを作成・管理できます。

## 静的ファイルの配置

本や記事で使用する画像などの静的ファイルは、`public`ディレクトリに配置します。

![Zenn Booksロゴ](/zenn-books-logo.svg)

### ファイルパスの指定方法

- 絶対パス: `/ファイル名` （推奨）
- 相対パスは使用しません

### サポートされるファイル形式

- 画像: `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`
- その他の静的ファイル

詳細は[Zennの公式ドキュメント](https://zenn.dev/zenn/articles/markdown-guide)を参照してください。
