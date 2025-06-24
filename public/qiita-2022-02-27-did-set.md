---
title: "[Swift] Class と Struct の変数の didSet 挙動の違いについて"
tags:
  - "Swift"
private: false
updated_at: ''
id: 42f2a23b9e787434dd5d
organization_url_name: null
slide: false
ignorePublish: false
---

# 結論

- `Class` や `Struct` を持つ変数について、`didSet` を実装する時は、挙動が異なるので注意が必要

## 共通コード


以下のような、適当な `Class` と `Struct` を要します。

```swift
// 🏫 Class
class Moge {
    var mogemoge: Int = 0 {
        didSet {
            print("mogemoge: \(mogemoge)")
        }
    }
    
    init() {}
    
    func update(mogemoge: Int) {
        self.mogemoge = mogemoge
    }
}

// 🏗 Struct
struct Fuga {
    var fugafuga: Int = 0 {
        didSet {
            print("fugafuga: \(fugafuga)")
        }
    }
    
    // struct の場合 `mutating` をつけないとコンパイルエラー⚠️
    mutating func update(fugafuga: Int) {
        self.fugafuga = fugafuga
    }
}
```

上記の `Class` または `Struct` を変数にもつ `Class` をさらに用意します。

```Swift
class Hoge {
    // 🔢 Int の場合
    var hogehoge: Int = 0 {
        didSet {
            print("hogehoge: \(hogehoge)")
        }
    }
    
    // 🏫 Class の場合
    var moge: Moge = .init() {
        didSet {
            print("moge: \(moge), mogemoge: \(moge.mogemoge)")
        }
    }
    
    // 🏗 Struct の場合
    var fuga: Fuga = .init() {
        didSet {
            print("fuga: \(fuga), fugafuga: \(fuga.fugafuga)")
        }
    }
    
    init() {}
}

let hoge: Hoge = .init()
```

ここで、この `hoge` に対して、値の更新を走らせるとどうなるか実験してみます。

## 🔢 Int の場合

```swift:🔢 Int の場合
hoge.hogehoge = 1
// hogehoge: 1
```

当たり前の挙動になりました。

## 🏫 Class の場合

```swift:🏫 Class の場合
hoge.moge = Moge()
// moge: __lldb_expr_49.Moge, mogemoge: 0

hoge.moge.mogemoge = 2
// mogemoge: 2

hoge.moge.update(mogemoge: 3)
// mogemoge: 3
```

これもなんとなく想像の通りの結果だと思います。

## 🏗 Struct の場合

```swift:🏗 Struct の場合
hoge.fuga = Fuga()
// fuga: Fuga(fugafuga: 0), fugafuga: 0

hoge.fuga.fugafuga = 4
// fugafuga: 4
// fuga: Fuga(fugafuga: 4), fugafuga: 4 ← ❗️❗️

hoge.fuga.update(fugafuga: 5)
// fugafuga: 5
// fuga: Fuga(fugafuga: 5), fugafuga: 5 ← ❗️❗️
```

**`Struct` の持っている変数の変更を実施した場合、`Struct` の場合は、`Class` と違って、変更された変数の `didSet` に加えて、さらに、`hoge` が持っている `fuga` の `Struct` 自身の `didSet` も走っています。**

このように `Class` や `Struct` を持つ変数について、`didSet` を実装する時は、挙動が異なるので注意が必要です。

## 考察

このような挙動の差は、`Class` が参照型であり、`Struct` が値型であること原因であると考えられます。

また、似たような話として、`@Published` や `CurrentValueSubject` の挙動も `Class` と `Struct` で差があります。

- 参考
  - [値型と参照型 - Swiftの始め方](https://swift.codelly.dev/guide/%E6%A7%8B%E9%80%A0%E4%BD%93%E3%81%A8%E3%82%AF%E3%83%A9%E3%82%B9/%E5%80%A4%E5%9E%8B%E3%81%A8%E5%8F%82%E7%85%A7%E5%9E%8B.html)
  - [[Swift] [Combine] @Published な変数が Class と Struct では挙動が異なる件](https://zenn.dev/ikuraikura/articles/2022-02-26-pub4)


以上になります。
