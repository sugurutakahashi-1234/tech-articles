---
title: "[Swift] rawValue を持つ enum には自動的にイニシャライザが定義される"
tags:
  - "Swift"
private: false
updated_at: ''
id: 52a09017bdd928eae6c5
organization_url_name: null
slide: false
ignorePublish: false
---

# rawValue を持つ enum には自動的にイニシャライザが定義される

最近まで知りませんでした。
swift.org に普通に書いてありました。

> # Initializing from a Raw Value
> If you define an enumeration with a raw-value type, the enumeration automatically receives an initializer that takes a value of the raw value’s type (as a parameter called rawValue) and returns either an enumeration case or nil. You can use this initializer to try to create a new instance of the enumeration.

https://docs.swift.org/swift-book/LanguageGuide/Enumerations.html


DeepL翻訳↓

> 生の値からの初期化
> 生の値の型を持つ列挙型を定義すると、列挙型は自動的に初期化子を受け取り、生の値の型の値（rawValueというパラメータ）を取り、列挙型のケースまたはnilを返します。このイニシャライザーを使って、列挙型の新しいインスタンスの作成を試みることができる。

# 実際に挙動を確認してみる

```swift
enum Drink: String {
    case coffee
    case tea
}

print(Drink(rawValue: "coffee") ?? "Undefined") // coffee
print(Drink(rawValue: "tea") ?? "Undefined") // tea
print(Drink(rawValue: "hoge") ?? "Undefined") // Undefined
```

自動的に以下のようなイニシャライザが定義されているみたいです。

```swift
enum Drink: String {
    case coffee
    case tea
    
    // これが自動的に記述される
    init?(rawValue: String) {
        switch rawValue {
        case Drink.coffee.rawValue:
            self = .coffee
        case Drink.tea.rawValue:
            self = .tea
        default:
            return nil
        }
    }
}
```


正直、大抵の場合は enum の定義を extension すれば済むことがほとんどだと思うので、使い所は限られてくると思います。

一致する rawValue がなければイニシャライザで `nil` が返却されることを考慮しなければならないので、その辺もすこし使いづらい印象です。

- 参考
  - [Enumerations - docs.swift.org](https://docs.swift.org/swift-book/LanguageGuide/Enumerations.html)
  - [Initializer init(rawValue:)- Apple Developer Documentation](https://developer.apple.com/documentation/swift/rawrepresentable/init(rawvalue:))

以上です。
