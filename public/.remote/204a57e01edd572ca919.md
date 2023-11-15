---
title: '[Swift] 安全に割り算する Double の extension'
tags:
  - Swift
private: false
updated_at: '2023-11-15T20:50:30+09:00'
id: 204a57e01edd572ca919
organization_url_name: null
slide: false
ignorePublish: false
---

# 安全に割り算する Double の extension

単純な実装ですが作成してみました。

```swift
extension Double {
    /// 分子が nan、分母が nan、または分母が 0 であっても安全に割り算を行う
    /// - Parameter divisor: 分母
    /// - Returns: 割り算の計算結果を返却する。ただし、分子が nan、分母が nan、または分母が 0 の場合は nil を返却する。
    func safeDivide(by divisor: Double) -> Double? {
        guard !divisor.isZero else {
            return nil
        }
        guard !divisor.isNaN else {
            return nil
        }
        guard !self.isNaN else {
            return nil
        }
        return self / divisor
    }
}
```

デフォルト値を引数で渡そうとも考えていたのですが、そうするよりも、この関数を使う側でデフォルト値は設定してあげた方がいいと思い、`nil` を返却するようにしました。

他にも `安全に◯◯する` 系の便利関数を作る場合は `nil` を返すのがよさそうですね。

# 挙動の確認

サンプルコードになります。

```swift
var a: Double = 0.0
var b: Double = 0.0

a = 0.0
b = 0.0
print("original: \(a) / \(b) = \(a / b)")
print("safeDivide: \(a) / \(b) = \(a.safeDivide(by: b) ?? 0.0)")
// original: 0.0 / 0.0 = -nan
// safeDivide: 0.0 / 0.0 = 0.0

a = 1.0
b = 1.0
print("original: \(a) / \(b) = \(a / b)")
print("safeDivide: \(a) / \(b) = \(a.safeDivide(by: b) ?? 0.0)")
// original: 1.0 / 1.0 = 1.0
// safeDivide: 1.0 / 1.0 = 1.0

a = 1.0
b = 0.0
print("original: \(a) / \(b) = \(a / b)")
print("safeDivide: \(a) / \(b) = \(a.safeDivide(by: b) ?? 0.0)")
// original: 1.0 / 0.0 = inf
// safeDivide: 1.0 / 0.0 = 0.0

a = Double.nan
b = 1.0
print("original: \(a) / \(b) = \(a / b)")
print("safeDivide: \(a) / \(b) = \(a.safeDivide(by: b) ?? 0.0)")
// original: nan / 1.0 = nan
// safeDivide: nan / 1.0 = 0.0

a = 1.0
b = Double.nan
print("original: \(a) / \(b) = \(a / b)")
print("safeDivide: \(a) / \(b) = \(a.safeDivide(by: b) ?? 0.0)")
// original: 1.0 / nan = nan
// safeDivide: 1.0 / nan = 0.0
```

通常時だと `0.0 / 0.0 = -nan` となるのは予測できませんよね。（ハマりました。。。）

以上になります。
