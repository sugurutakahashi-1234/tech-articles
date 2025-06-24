---
title: "[Swift] Swift でも clamp() したい！"
tags:
  - "Swift"
private: false
updated_at: ''
id: 3a63d6a64e7525f65697
organization_url_name: null
slide: false
ignorePublish: false
---

# Swift で clamp() 

`c++` には `min <= x <= max` の範囲で `x` の値を返却してくる [`clamp()`](https://cpprefjp.github.io/reference/algorithm/clamp.html) という関数があるので、それの Swift 版の紹介です。

```swift
extension Comparable {
    func clamp(minValue: Self, maxValue: Self) -> Self {
        min(max(minValue, self), maxValue)
    }
    
    func clamp(to range: ClosedRange<Self>) -> Self {
        self.clamp(minValue: range.lowerBound, maxValue: range.upperBound)
    }
}
```

正直、似たような記事はいくつもあったのですが、`Comparable` の拡張なら `ClosedRange` を用いて、表現できるとより綺麗かなと思い、投稿しました。

# 実際に使ってみた

使い方は以下のようになります。

```swift
let minValue: Int = 0
let maxValue: Int = 2
let range: ClosedRange<Int> = minValue...maxValue

print((-1).clamp(minValue: minValue, maxValue: maxValue)) // 0
print(0.clamp(minValue: minValue, maxValue: maxValue)) // 0
print(1.clamp(minValue: minValue, maxValue: maxValue)) // 1
print(2.clamp(minValue: minValue, maxValue: maxValue)) // 2
print(3.clamp(minValue: minValue, maxValue: maxValue)) // 2

print((-1).clamp(to: range)) // 0
print(0.clamp(to: range)) // 0
print(1.clamp(to: range)) // 1
print(2.clamp(to: range)) // 2
print(3.clamp(to: range)) // 2
```

以上になります。
