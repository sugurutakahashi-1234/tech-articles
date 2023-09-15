---
title: "[Swift] CustomStringConvertible の実装例"
emoji: "🕊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Swift"]
published: true
---

# CustomStringConvertible の実装例

`CustomStringConvertible` を適応させることで、出力するときに任意の文字列表現に変換できます。

```swift
import Foundation

struct CustomStringConvertibleHoge: CustomStringConvertible {
    let value: Int
    
    var description: String {
        "CustomStringConvertible を適応している場合: \(value)"
    }
}

struct NotCustomStringConvertibleHoge {
    let value: Int
    
    var description: String {
        "CustomStringConvertible を適応していない場合: \(value)"
    }
}

let customStringConvertibleHoge = CustomStringConvertibleHoge(value: 0)
let notCustomStringConvertibleHoge = NotCustomStringConvertibleHoge(value: 1)

print(customStringConvertibleHoge) // CustomStringConvertible を適応している場合: 0
print(notCustomStringConvertibleHoge) // NotCustomStringConvertibleHoge(value: 1)
```

以上です。