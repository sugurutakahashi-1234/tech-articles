---
title: '[Swift] weak self しないと強参照で解放できないサンプルコード'
tags:
  - Swift
private: false
updated_at: '2023-11-15T20:50:30+09:00'
id: 3f0fe9ae95463e8e5250
organization_url_name: null
slide: false
ignorePublish: false
---

# はじめに

`weak self` しないことによって、参照元が強参照のため、解放できないサンプルコードを作るのが難しかったので、メモの代わりにここに残します。

## 適当な closure を持つ struct を用意

```swift
struct Calculator {
    let numA: Double
    let numB: Double
    let closure: (Double, Double) -> Void
    
    init(numA: Double, numB: Double, closure: @escaping (Double, Double) -> Void) {
        self.numA = numA
        self.numB = numB
        self.closure = closure
    }
    
    func calc() {
        closure(numA, numB)
    }
}
```

## 強参照サンプルコード

```swift
class SampleStrongClass {
    private let taxRate = 1.1
    let numA: Double
    let numB: Double
    
    init(numA: Double, numB: Double) {
        self.numA = numA
        self.numB = numB
    }
    
    deinit {
        print("deinit: \(type(of: self))")
    }

    // 強参照なコード
    func getCalculator() -> Calculator {
        Calculator(numA: numA, numB: numB) { numA, numB in // ← `[weak self]` がないため強参照
            print("\((numA + numB) * (self.taxRate))")
        }
    }
}
```

## 弱参照サンプルコード

```swift
class SampleWeakClass {
    private let taxRate = 1.1
    let numA: Double
    let numB: Double
    
    init(numA: Double, numB: Double) {
        self.numA = numA
        self.numB = numB
    }
    
    deinit {
        print("deinit: \(type(of: self))")
    }
    
    // 弱参照なコード
    func getCalculator() -> Calculator {
        Calculator(numA: numA, numB: numB) { [weak self] numA, numB in // ← `[weak self]` をつける
            guard let self = self else {
                print("self is nil")
                return
            }
            print("\((numA + numB) * (self.taxRate))")
        }
    }
}
```

## 強参照と弱参照の比較

### 強参照の場合

```swift
// 初期化
var smapleStrongClass: SampleStrongClass? = .init(numA: 3, numB: 4)
var strongClassCalculator: Calculator? = smapleStrongClass?.getCalculator()

// クロージャーの実行
strongClassCalculator?.calc() // 7.700000000000001

// 参照元の class に nil を代入
smapleStrongClass = nil // （出力なし） ← deinit が走らない = メモリリーク

// クロージャーの実行
strongClassCalculator?.calc() // 7.700000000000001 ← 計算できてしまう
```

### 弱参照の場合

```swift
// 初期化
var smapleWeakClass: SampleWeakClass? = .init(numA: 5, numB: 6)
var weakClassCalculator: Calculator? = smapleWeakClass?.getCalculator()

// クロージャーの実行
weakClassCalculator?.calc() // 12.100000000000001

// 参照元の class に nil を代入
smapleWeakClass = nil // deinit: SampleWeakClass ← deinit が走る

// クロージャーの実行
weakClassCalculator?.calc() // self is nil ← 計算できない
```

以上になります。
