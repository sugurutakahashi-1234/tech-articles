---
title: "[Swift] 辞書型あれこれ"
tags:
  - "Swift"
private: false
updated_at: ''
id: d6efbaccdba760d90298
organization_url_name: null
slide: false
ignorePublish: false
---

# はじめに

基本的には辞書型は、クライアント側のコードでは `key` でのアクセスが `nil` の可能性を孕んだり、`value` や `key` に対して変数名を設定できないので、辞書型で宣言するよりも struct 型で宣言することがほとんどだと思います。

また、API レスポンスの型の都合上などで、辞書型を扱うことも `Codable` で定義することで、ほとんど必要なくなりました。

それでもたまに辞書型を使うとことがあるので、辞書型でよく使える技を書き残そうと思います。

# 伝えたいこと

- `key` も `value` も両方の値を使っていきたい -> 早めに Struct に変換する
- 辞書型を維持しなくても良いなら -> その段階で辞書型を変更 -> `.values` or `.keys`
- 辞書型を維持したまま処理するなら -> 辞書型を維持する処理 -> `.mapValues()`
- `.first(where: 条件)` は辞書型のまま使える

# `key` も `value` も両方の値を使っていきたい -> 早めに Struct に変換する

辞書型のままで良いですが、struct にして変数名を持たせることで、`key` と `value` に意味を持たせることができます。

```swift
let dict: [Int: String] = [1: "one", 2: "two" , 3: "three"]

struct Hoge {
    let id: Int
    let name: String
}

let hoges: [Hoge] = dict.map { key, value in Hoge(id: key, name: value) }
print(hoges) // [Hoge(id: 1, name: "one"), Hoge(id: 3, name: "three"), Hoge(id: 2, name: "two")]
```

※ ただし、順番は担保されないので注意が必要

# `key` だけや `value` だけの配列を生成する -> `.values` or `.keys`

```swift
let dict: [Int: String] = [1: "one", 2: "two" , 3: "three"]

print(dict.keys) // [1, 3, 2]
print(dict.values) // ["one", "three", "two"]

// 以下も同じ結果である
print(dict.map(\.key)) // [1, 3, 2]
print(dict.map(\.value)) // ["one", "three", "two"]
```

※ ただし、順番は担保されないので注意が必要

# `.mapValues()` で辞書型を維持したまま `value` だけ変換処理をする

```swift
let dict: [Int: String] = [1: "one", 2: "two" , 3: "three"]

print(dict.mapValues { $0.count }) // [1: 3, 2: 3, 3: 5]
```

`.values` or `.keys` や `.mapValues()` を使うことで通常の配列っぽく扱うことが可能ですが、以下のことを念頭に置くとよさそうです。

- 辞書型を維持したまま処理するなら -> 辞書型を維持する処理 -> `.mapValues()`
- 辞書型を維持しなくても良いなら -> その段階で辞書型を変更するとよさそう -> `.values` or `.keys`

# `.first(where: 条件)` は辞書型のまま使える

```swift
let dict: [Int: String] = [1: "one", 2: "two" , 3: "three"]

// 以下はすべて同じ結果である
print(dict[2]!) // two
print(dict.first(where: { $0.key == 2 })!.value) // two
print(dict.first(where: { $0.value == "two" })!.value) // two

// もちろん先にvalueに変換してもよし
print(dict.map(\.value).first(where: { $0 == "two" })!) // two
```

大体、配列と同じような処理をすることが辞書型でも可能みたいです。

以上です。
