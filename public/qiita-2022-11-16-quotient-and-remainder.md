---
title: "[Swift] 割り算の商と余りの両方がほしい場合は quotientAndRemainder を使おう"
tags:
  - "Swift"
private: false
updated_at: ''
id: ef0686984a5a45d91713
organization_url_name: null
slide: false
ignorePublish: false
---

# 伝えたいこと

- 割り算の商と余りの両方がほしい場合は `quotientAndRemainder` を使うと一発で両方が求められる

https://developer.apple.com/documentation/swift/int/quotientandremainder(dividingby:)

# `/` と `％` による商と余りの計算

`/` と `％` によって、以下のように割り算の商と余りの計算ができます。

```swift
let appleCount = 13
let friendCount = 4

// `/` と `％` による商と余りの計算
let quotient = appleCount / friendCount // 商: 3
let remainder = appleCount % friendCount // 余り: 1

print(quotient) // 3
print(remainder) // 1
```

# `quotientAndRemainder` による商と余りの計算

割り算の商と余りの両方がほしい場合は `quotientAndRemainder` を使うと一発で両方が求められます。

https://developer.apple.com/documentation/swift/int/quotientandremainder(dividingby:)

以下、サンプルコードです。

```swift
let appleCount = 13
let friendCount = 4

// `quotientAndRemainder` による商と余りの計算
let divisionResult = appleCount.quotientAndRemainder(dividingBy: friendCount)

// (quotient: 商, remainder: 余り) のタプルが返ってくる
print(divisionResult) // (quotient: 3, remainder: 1)

// もちろんこのようなアクセスも可能
print(divisionResult.quotient) // 3
print(divisionResult.remainder) // 1

// タプルのインデックスへのアクセスも可能
print(divisionResult.0) // 3
print(divisionResult.1) // 1
```

割り算の商と余りの両方使う場合はこちらを使うとよさそうですね。

以上になります。
