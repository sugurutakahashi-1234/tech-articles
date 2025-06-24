---
title: "[Swift] 0.0 に限りなく近い値である Double.ulpOfOne の有用性について"
tags:
  - "Swift"
private: false
updated_at: ''
id: 301ad170e9f85ef41709
organization_url_name: null
slide: false
ignorePublish: false
---

## Swiftでの`Double.ulpOfOne`の有用性

Swift における `Double.ulpOfOne` の使い方とその重要性を、簡単な割り算の例を通じて説明します。`Double.ulpOfOne` は、Double の最小単位（ULP: Unit in the Last Place）を表し、これを使って非常に小さい値で割り算を行った場合の挙動を確認します。

### コード例

以下の関数は、与えられた分子（`numerator`）を非常に小さい値（`epsilon`）で割り、その結果と結果が無限大かどうかを返します。

```swift
func divideAndReturnResult(_ numerator: Double, epsilon: Double) -> (result: Double, isInfinite: Bool) {
    let result = numerator / epsilon
    return (result, result.isInfinite)
}

let value = 1.0

// Double.ulpOfOneを使った場合
let (resultWithUlp, isInfiniteWithUlp) = divideAndReturnResult(value, epsilon: Double.ulpOfOne)
print("Double.ulpOfOneを使用した場合の結果: \(resultWithUlp), 無限大？ \(isInfiniteWithUlp)")

// 0.0を使った場合
let (resultWithZero, isInfiniteWithZero) = divideAndReturnResult(value, epsilon: 0.0)
print("0.0を使用した場合の結果: \(resultWithZero), 無限大？ \(isInfiniteWithZero)")
```

このコードを実行すると、以下のような結果が得られます：

```swift
Double.ulpOfOneを使用した場合の結果: 4503599627370496.0, 無限大？ false
0.0を使用した場合の結果: inf, 無限大？ true
```

## 解説

Double.ulpOfOne を使用した場合、結果は非常に大きな値になりますが、無限大ではありません。
一方、0.0 で割ると結果は無限大（inf）になります。

この違いは、非常に小さな値での割り算の挙動を理解する上で重要です。
Double.ulpOfOne は、限りなく小さいがゼロではない値であり、計算の精度と安定性を保つ上で重要な役割を果たします。

以上です。
