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

## 画像の使用方法

Zennで画像を使用する場合は、以下の方法があります：

### Zennエディタでの画像アップロード

1. Zennのエディタを開く
2. 画像をドラッグ&ドロップするか、画像アップロードボタンをクリック
3. 自動的に以下のようなMarkdownが挿入されます：

```markdown
![](https://storage.googleapis.com/zenn-user-upload/xxxxx.png)
```

### 画像の書式

```markdown
![代替テキスト](画像URL)
*キャプション*
```

画像のサイズ指定も可能です：

```markdown
![](画像URL =250x)
```

詳細は[Zennの公式ドキュメント](https://zenn.dev/zenn/articles/markdown-guide)を参照してください。
