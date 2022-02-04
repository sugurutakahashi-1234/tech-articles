---
title: "【Swift】配列を比較して差分のあるindexの配列を返却する便利関数を作った件"
emoji: "🔖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Swift"]
published: true
---

# 結論

こちらになります。

```swift
extension Array where Element: Equatable {
    func diffIndices(from oldArray: [Element]) -> [Int] {
        var diffIndices: [Int] = []
        self.indices.indices.forEach {
            if oldArray.indices.contains($0) {
                if self[$0] != oldArray[$0] {
                    diffIndices.append($0)
                }
            } else {
                diffIndices.append($0)
            }
        }
        return diffIndices
    }
}
```

注意点として、順番も考慮します。

使い方は以下の通りです。

```swift
let stringsA: [String] = ["a", "b", "c", "d", ""]
let stringsB: [String] = ["x", "b", "a", "d", "", "hoge"]

let diffIndices = stringsB.diffIndices(from: stringsA)
print("diff: \(diffIndices)")
// diff: [0, 2, 5]

stringsB.diffIndices(from: stringsA).forEach {
    print("diff value: \(stringsB[$0])")
}

// diff value: x
// diff value: a
// diff value: hoge
```

本編は以上です。

# 番外編

順番を考慮したくない方は以下を使ってください。
（関数名のセンスがなくてすみません。。。）

```swift
extension Array where Element: Equatable {
    func diffIndicesNotConsideringOrder(from oldArray: [Element]) -> [Int] {
        var diffIndices: [Int] = []
        self.indices.indices.forEach {
            if !oldArray.contains(self[$0]) {
                diffIndices.append($0)
            }
        }
        return diffIndices
    }
}
```

使い方は同じです。

```swift
let stringsA: [String] = ["a", "b", "c", "d", ""]
let stringsB: [String] = ["x", "b", "a", "d", "", "hoge"]

let diffIndices: [Int] = stringsB.diffIndicesNotConsideringOrder(from: stringsA)

print("diff: \(diffIndices)")
// diff: [0, 5]

stringsB.diffIndicesNotConsideringOrder(from: stringsA).forEach {
    print("diff value: \(stringsB[$0])")
}

// diff value: x
// diff value: hoge
```

以上になります。