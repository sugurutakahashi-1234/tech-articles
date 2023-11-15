---
title: '[Swift] Computed Property でも例外を throw できる件'
tags:
  - Swift
private: false
updated_at: '2023-11-15T20:50:30+09:00'
id: b497f4b73c60709be0e5
organization_url_name: null
slide: false
ignorePublish: false
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
