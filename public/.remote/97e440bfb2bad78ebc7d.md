---
title: 【Swift】強制アンラップを返す関数の注意点
tags:
  - Swift
private: false
updated_at: '2021-09-26T09:55:28+09:00'
id: 97e440bfb2bad78ebc7d
organization_url_name: null
slide: false
ignorePublish: false
---

# 強制アンラップを返す関数の注意点

強制アンラップを返す関数で `nil` を返すような処理を書くとコンパイルエラーにはならずに実行時エラーになります。

環境：Xcode 12.5.1

```swift:サンプル
func testA() -> Int! {
    return 0
}

func testB() -> Int! {
    return nil // nilを返却してもコンパイルエラーにはならない
}

let hogeA: Int = testA() // 変数宣言時に!をつけなくてもコンパイルは通る
let hogeB: Int = testB() // 変数宣言時に!をつけなくてもコンパイルは通るが、実行時にエラーになる
```

なので、そもそも強制アンラップを返す関数は使うのはやめたほうがいいです。
