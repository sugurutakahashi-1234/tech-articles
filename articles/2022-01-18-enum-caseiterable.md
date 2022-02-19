---
title: "[Swift] 値付き enum は CaseIterable をつけても allCases を自身で定義しなければならない件"
emoji: "🔖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Swift","CaseIterable"]
published: true
---

# この記事で分かること

- 値付き enum で `CaseIterable` のプロトコルを適応させる場合、`allCases` を自身で定義しなければならない

# 具体例

## 例その1: CaseIterableの通常の使い方

```swift
enum Color: CaseIterable {
    case red, green, blue
}

Color.allCases.forEach {
    print($0)
}

// 出力
//
// red
// green
// blue
```

## 例その2: 値付きenumでCaseIterableを使う場合

以下のような値付き `enum` では `CaseIterable` とつけても `Type 'Trade' does not conform to protocol 'CaseIterable'` と怒られてしまいます。

```swift
enum Trade: CaseIterable { // Type 'Trade' does not conform to protocol 'CaseIterable'
    case buy(stock: String, amount: Int)
    case sell(stock: String, amount: Int)
}
```

そのため、以下のように `allCases` を自分で定義して、具体値を定義しなければなりません。

```swift
enum Trade: CaseIterable {
    // allCases を自分で定義しなければなない
    static var allCases: [Trade] {
        return [
            .buy(stock: "", amount: 0),
            .sell(stock: "", amount: 0)
        ]
    }
    
    case buy(stock: String, amount: Int)
    case sell(stock: String, amount: Int)
}

Trade.allCases.forEach {
    print($0)
}

// 出力
//
// buy(stock: "", amount: 0)
// sell(stock: "", amount: 0)
```


# 例その3: 値付きenumの「値」にenumを用いた場合

では、値付き `enum` の「値」を `CaseIterable` に適応した `enum` を用いた場合、どうなるのでしょうか？
「いい感じに察してくれないかな〜」と期待したいところですよね。

実際に試したところ、これもコンパイラに怒られてしまい、`allCases` を自分で定義しなければいけませんでした（泣）

無理やり書いてみると以下のようになりました。残念！！

```swift
enum FinancialProduct: CaseIterable {
    case stock
    case gold
    case crypto
}

enum Trade: CaseIterable {
    static var allCases: [Trade] {
        return [
            FinancialProduct.allCases.map { .buy(financialProduct: $0) },
            FinancialProduct.allCases.map { .sell(financialProduct: $0) },
        ].flatMap { $0 }
    }
        
    case buy(financialProduct: FinancialProduct)
    case sell(financialProduct: FinancialProduct)
}

Trade.allCases.forEach { trade -> () in
    switch trade {
    case let .buy(financialProduct):
        print("buy: \(financialProduct)")
    case let .sell(financialProduct):
        print("sell: \(financialProduct)")
    }
}

// 出力
//
// buy: stock
// buy: gold
// buy: crypto
// sell: stock
// sell: gold
// sell: crypto
```

# 結論

- 値付き `enum` で `CaseIterable` を使うのは注意が必要