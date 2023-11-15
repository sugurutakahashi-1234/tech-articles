---
title: '[Swift] タプルのアクセス方法あれこれ'
tags:
  - Swift
private: false
updated_at: '2023-11-15T20:50:30+09:00'
id: 85ee2dc668a6ff1ec383
organization_url_name: null
slide: false
ignorePublish: false
---

# タプルのアクセス方法あれこれ

以下はすべて同じ挙動になります。

```swift
let nums: [Int] = [1,2,3]

zip(nums, nums.dropFirst()).map {
    print("パターンA: \($0),\($1)")
}
// パターンA: 1,2
// パターンA: 2,3

zip(nums, nums.dropFirst()).map {
    print("パターンB: \($0.0),\($0.1)")
}
// パターンB: 1,2
// パターンB: 2,3

zip(nums, nums.dropFirst()).map { hoge in
    print("パターンC: \(hoge.0),\(hoge.1)")
}
// パターンC: 1,2
// パターンC: 2,3

zip(nums, nums.dropFirst()).map { hoge, moge in
    print("パターンD: \(hoge),\(moge)")
}
// パターンD: 1,2
// パターンD: 2,3

zip(nums, nums.dropFirst()).map { (hoge, moge) in
    print("パターンE: \(hoge),\(moge)")
}
// パターンE: 1,2
// パターンE: 2,3
```

個人的には `パターン A` か`パターン D` がおすすめです。

以上になります。
