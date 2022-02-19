---
title: "[Swift] Computed Property でも例外を throw できる件"
emoji: "🔖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Swift"]
published: true
---

# サンプルコード

- Swift: 5.5.2

適当にサンプルコードを書いてみました。

```swift
enum HogeError: Error {
    case zeroError
}

var moge: Int = 0

var hoge: Int {
    get throws {
        guard moge != 0 else {
            throw HogeError.zeroError
        }
        return moge
    }
}
```

アクセスする際は `try` をつける以外は、いつも通りの要領です。

```swift
moge = 1
do {
    print("hoge: \(try hoge)") // hoge: 1
} catch {
    print("error: \(error)")
}

moge = 0
do {
    print("hoge: \(try hoge)")
} catch {
    print("error: \(error)") // error: zeroError
}
```

以上になります。