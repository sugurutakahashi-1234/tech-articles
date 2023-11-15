---
title: '[Swift] 配列を比較して差分のあるindexの配列を返却する便利関数を作った件'
tags:
  - Swift
private: false
updated_at: '2023-11-15T20:50:31+09:00'
id: 475610a1e48d8a80559b
organization_url_name: null
slide: false
ignorePublish: false
---

# 結論

こちらになります。

```swift
extension Array where Element: Equatable {
    func diffIndices(from oldArray: [Element]) -> [Int] {
        self.indices.compactMap { index in
            if oldArray.indices.contains(index) {
                if self[index] != oldArray[index] {
                    return index
                }
            } else {
                return index
            }
            return nil
        }
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
        self.indices.indices.compactMap { index in
            if !oldArray.contains(self[index]) {
                return index
            }
            return nil
        }
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
