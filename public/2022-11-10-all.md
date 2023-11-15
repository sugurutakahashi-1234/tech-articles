---
title: '[Swift] 空配列の allSatisfy と contains の判定には注意せよ'
tags:
  - Swift
private: false
updated_at: '2023-11-15T20:50:31+09:00'
id: 5a7a5e7bb15cbfa0a7cf
organization_url_name: null
slide: false
ignorePublish: false
---

# 伝えたいこと

- 空配列に対する `allSatisfy` と `contains` の判定の違い
  - `allSatisfy`: 配列にひとつでも `false` があれば `false`
    - -> 空配列には `false` はないので `true`
  - `contains`: 配列にひとつでも `true` があれば `true`
    - -> 空配列には `true` はないので `false`
- `allSatisfy` と `contains` の使い分け
  - 『すべての値が `true` or `false` であるのか』を判定するなら -> `allSatisfy`
  - 『ひとつでも `true` or `false` があるのか』を判定するなら -> `contains`
- 教訓
  - 空配列の可能性があるものを `allSatisfy` や `contains` の処理をかける際は注意が必要である
  - 空配列の処理の混乱を避けるため `if [判定対象の配列].empty { return true or false }` で、先に処理を抜けさせるのも手である
  - `allSatisfy` や `contains` を使う際に `!` による否定は混乱の元なので、でできることなら避けた方がいい

## 空配列に対する `allSatisfy` と `contains` の判定の違い

以下のように、空配列に対する `allSatisfy` と `contains` の判定の結果は異なるので注意が必要になります。

```swift
[].allSatisfy { $0 } // true
[].contains { $0 } // false
```

この違いは、以下のような理解になります。

- `allSatisfy`: 配列にひとつでも `false` があれば `false`
  - -> 空配列には `false` はないので `true`
- `contains`: 配列にひとつでも `true` があれば `true`
  - -> 空配列には `true` はないので `false`

## `allSatisfy` や `contains` を使うときのポイント

つまるところ、`[判定対象の配列].allSatisfy { $0 }` と `![判定対象の配列].contains { !$0 }` は同値となります。（たぶん）

なので、`allSatisfy` や `contains` のどちらか片方だけで記述することは可能なのですが、`!` による否定を使うと混乱するので、どちらを使うか迷ったときは、以下のようなイメージを持つと良いと思います。

- 『すべての値が `true` or `false` であるのか』を判定するなら -> `allSatisfy`
- 『ひとつでも `true` or `false` があるのか』を判定するなら -> `contains`

また、`!` による否定系を使えばワンライナーで書けるケースも、`if [判定対象の配列].empty { return true or false }` で判定を早期リターンさせて、複数行で書いてあげた方が読みやすいコードになると個人的には思っています。

## 挙動の確認

以下は、playground で実験した際のサンプルコードです。
挙動を確認したいときにお試しください。

```swift
[true, false].allSatisfy { $0 } // false
[true, true].allSatisfy { $0 } // true
[false, false].allSatisfy { $0 } // false
[].allSatisfy { $0 } // true
```

```swift
[true, false].allSatisfy { !$0 } // false
[true, true].allSatisfy { !$0 } // false
[false, false].allSatisfy { !$0 } // true
[].allSatisfy { !$0 } // true
```

```swift
[true, false].contains { $0 } // true
[true, true].contains { $0 } // true
[false, false].contains { $0 } // false
[].contains { $0 } // false
```

```swift
[true, false].contains { !$0 } // true
[true, true].contains { !$0 } // false
[false, false].contains { !$0 } // true
[].contains { !$0 } // false
```

以上になります。
