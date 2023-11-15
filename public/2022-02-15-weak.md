---
title: '[Swift] どうして weak var delegate とするのか？'
tags:
  - Swift
private: false
updated_at: '2023-11-15T20:50:30+09:00'
id: 047a19ef6db49c125016
organization_url_name: null
slide: false
ignorePublish: false
---

# 伝えたいこと

delegate に適応した self を弱参照させるパターンは以下の2通りがある。

- 案1: `weak var` で宣言した変数を用意して、delegate に適応した `self` を代入する
   - メリット：シンプルである
   - デメリット：delegate 変数の外部からの変更や、delegete の代入忘れの恐れがある
- 案2: `lazy var` で delegate に適応した `self` を init の引数で渡す。変数は `private weak var` または `private unowned let` で外部からの変更を阻止する
   - メリット：`weak var` を使う場合にあったようなデメリットがなくなる
   - デメリット：`lazy var` を使う影響で、その変数が変更される恐れや、`lazy var` の変数が使われるタイミングで init が走るので、そのタイミングによっては予期せぬバグが発生する（= `lazy var` のリスク）
     - 案2-1: `private weak var` で変数を宣言した場合：
       - メリット：delegate が破棄された状態でアクセスした場合に、`delegate?` か `delegate!` で 実行スキップか、クラッシュかを選べる
       - デメリット：`var` であること
     - 案2-2: `private unowned let` で変数を宣言した場合：
       - メリット：`let` であること
       - デメリット：delegate が破棄された状態でアクセスした場合に、必ずクラッシュする（むしろ、delegate が破棄されないことを想定しているのであれば、クラッシュすることによってバグの早期発見に繋がるのでメリットかもしれません。）

# どうして `weak var delegate` とするのか？

`weak` をつけていないサンプルコードを用いて挙動を確認してみます。

## weak をつけない場合の挙動

以下のようなサンプルコードを用意します。

```swift
protocol HogeDelegate: AnyObject {
    func hogehoge()
}

class MogeClass {
    var delegate: HogeDelegate?
    
    deinit {
        print("deinit: \(type(of: self))")
    }
    
    func mogemoge() {
        delegate?.hogehoge()
    }
}

class FugaClass {
    let mogeClass: MogeClass
    
    init() {
        mogeClass = MogeClass()
        mogeClass.delegate = self
    }
    
    deinit {
        print("deinit: \(type(of: self))")
    }
    
    func fugafuga() {
        mogeClass.mogemoge()
    }
}

extension FugaClass: HogeDelegate {
    func hogehoge() {
        print("called hogehoge() on FugaClass")
    }
}
```

### fugaClass の fugafuga() の実行

```swift
var fugaClass: FugaClass? = FugaClass()
fugaClass?.fugafuga()

// (出力)
// called hogehoge() on FugaClass
```

期待通りですね。

### fugaClass init して deinit する

```swift
var fugaClass: FugaClass? = FugaClass()
fugaClass = nil

// (出力)
// なし
```

あれ？
`fugaClass` が解放されませんね。

さらに `mogeClass` も解放する術も失っていますね。

## weak をつけた場合の挙動

```swift
class MogeClass {
    weak var delegate: HogeDelegate? // ← weak をつける
    
    deinit {
        print("deinit: \(type(of: self))")
    }
    
    func mogemoge() {
        delegate?.hogehoge()
    }
}
```

### fugaClass init して deinit する

```swift
var fugaClass: FugaClass? = FugaClass()
fugaClass = nil

// （出力）
// deinit: FugaClass
// deinit: MogeClass
```

解放されますね！！

### fugaClass の fugafuga() の実行して、それから fugaClass に nil を代入する

もちろん、fugaClass の fugafuga() の実行して、それから fugaClass に nil を代入しても解放されます。

```swift
var fugaClass: FugaClass? = FugaClass()
fugaClass?.fugafuga()
fugaClass = nil

// （出力）
// called hogehoge() on FugaClass
// deinit: FugaClass
// deinit: MogeClass
```

このように解放されないケースがあるので、`weak var` と宣言する必要があります。

# `weak var` の微妙な点

- 変数を `var` で宣言するので、外から変更されてしまう可能性がある
- delegate の変数に値を代入し忘れる可能性がある

# `weak var` の微妙な点の改善方法を検討する

## 改良案：init の引数に delegate を設定し、`lazy var` で self を渡す

サンプルコードは以下になります。

```swift
protocol HogeDelegate: AnyObject {
    func hogehoge()
}

class MogeClass {
    let delegate: HogeDelegate // let に修正
    
    init(delegate: HogeDelegate) {
        self.delegate = delegate // init でもらうようにする
    }
    
    deinit {
        print("deinit: \(type(of: self))")
    }
    
    func mogemoge() {
        delegate.hogehoge()
    }
}

class FugaClass {
    lazy var mogeClass = MogeClass(delegate: self) // lazy var で self を渡すようにする
    
    deinit {
        print("deinit: \(type(of: self))")
    }
    
    func fugafuga() {
        mogeClass.mogemoge()
    }
}

extension FugaClass: HogeDelegate {
    func hogehoge() {
        print("called hogehoge() on FugaClass")
    }
}
```

### fugaClass の fugafuga() の実行

```swift
var fugaClass: FugaClass? = FugaClass()
fugaClass?.fugafuga()

// （出力）
// called hogehoge() on FugaClass
```

うん。問題ないですね。


### fugaClass init して deinit する

```swift
var fugaClass: FugaClass? = FugaClass()
fugaClass = nil

// （出力）
// deinit: FugaClass
```

MogeClass が解放されていないように見えるが、そもそも生成されていないので、問題ないですね。

### fugaClass の fugafuga() の実行して、それから fugaClass に nil を代入してみる

```swift
var fugaClass: FugaClass? = FugaClass()
fugaClass?.fugafuga()
fugaClass = nil

// （出力）
// called hogehoge() on FugaClass
```

あれ、、、解放されていないみたい。。。

### 結局、`let` → `weak var` にしてみる

```swift
class MogeClass {
    weak var delegate: HogeDelegate? // 結局 weak var にする
    
    init(delegate: HogeDelegate) {
        self.delegate = delegate
    }
    
    deinit {
        print("deinit: \(type(of: self))")
    }
    
    func mogemoge() {
        delegate?.hogehoge()
    }
}
```

### 再Try

```swift
var fugaClass: FugaClass? = FugaClass()
fugaClass?.fugafuga()
fugaClass = nil

// （出力）
// called hogehoge() on FugaClass
// deinit: FugaClass
// deinit: MogeClass
```

うまくいきましたね。。。
でも結句 `weak var` をつかってしまっております。。。

## 改良案の微妙な点

うまくいきましたが、`lazy var` で self を渡すようにしても、やっぱり `weak var` をつけなればいけないのですね。。。

ただ、`private` をつければ、外からの変更は防げるので、それが気になる方はそうした方がいいかもしれませんね。

しかし、そもそも `lazy var` としている方が、変更のリスクが発生しますが、、、どっちがいいんでしょうね。

また、`private` をつけるのであれば、init での delegate の設定を忘れないように、`delegate` を使う際は強制アンラップしてもよいかもしれないですね。

```swift
class MogeClass {
    private weak var delegate: HogeDelegate? // private をつける
    
    init(delegate: HogeDelegate) {
        self.delegate = delegate
    }
    
    deinit {
        print("deinit: \(type(of: self))")
    }
    
    func mogemoge() {
        delegate!.hogehoge() // 強制アンラップにする
    }
}
```

でも、init で設定しているはずなのに `delegate?` や `delegate!` とするのはなんかいけてませんよね。。。

`weak let` があれば、解決できそうですが、`weak let` を使おうとすると「`error: 'weak' must be a mutable variable, because it may change at runtime`」と怒られます。

どうやら `weak let` はないみたいですね。。。

## 改良案の改良案：`unowned let` を使う！

`weak let` はできないですが、`unowned let` であれば宣言できるみたいでした。
実際に使ってみます。

```swift
class MogeClass {
    private unowned let delegate: HogeDelegate // unowned なら let を宣言できる
    
    init(delegate: HogeDelegate) {
        self.delegate = delegate
    }
    
    deinit {
        print("deinit: \(type(of: self))")
    }
    
    func mogemoge() {
        delegate.hogehoge() // ? や ! も消せる
    }
}
```

### 再Try

```swift
var fugaClass: FugaClass? = FugaClass()
fugaClass?.fugafuga()
fugaClass = nil

// （出力）
// called hogehoge() on FugaClass
// deinit: FugaClass
// deinit: MogeClass
```

うまくいきましたね。

`lazy var` で delegate となる `self` を init で渡すような場合は、`unowned let` を使っても良さそうですね。

ただ、`lazy var` を使うことのリスクもあるので、それには十分注意が必要です。

## `unowned let` のリスクについて

`lazy var` で delegate となる `self` を init で渡すようにする際には、`unowned let` でもよさそうなのですが、init で渡した delegate が途中で破棄されるような場合は、この使い方だとクラッシュするリスクがあります。

以下のような、`HogeDelegate` に適応した `PiyoClass` を用意して、これを使って、`MogeClass` を生成してみます。

```swift
class PiyoClass: HogeDelegate {
    deinit {
        print("deinit: \(type(of: self))")
    }
    
    func hogehoge() {
        print("called hogehoge() on PiyoClass")
    }
}
```

### 再Try

```swift
var piyoClass: PiyoClass? = PiyoClass()
let mogeClass = MogeClass(delegate: piyoClass!)
mogeClass.mogemoge()
piyoClass = nil

// （出力）
// called hogehoge() on PiyoClass
// deinit: PiyoClass
```

一見、問題なさそうですが、`piyoClass = nil` としたあとに再び、`mogeClass.mogemoge()` を実行してみます。

```swift
var piyoClass: PiyoClass? = PiyoClass()
let mogeClass = MogeClass(delegate: piyoClass!)
mogeClass.mogemoge()
piyoClass = nil

mogeClass.mogemoge() // error: Execution was interrupted, reason: signal SIGABRT.
```

クラッシュしました。
`MogeClass` で渡したはずの `HogeDelegate` がないので、当然ですよね。

### では、`unowned let` はやっぱり良くないのか？

もちろん、`unowned let` ではなく `weak var` に変更して、`MogeClass` での delegate 使用時に `delegate?` とアクセスすればクラッシュはさけられます。

ただ、それはアプリを使用するユーザーにとって良いことなのかは、ケースバイケースだと思います。

そもそも、思わぬタイミングで破棄されるような書き方になっていることも問題ですし、潔くクラッシュして、できるだけ早く不具合を発覚して、修正したほうがいいという考え方もあります。

今回の場合も、`unowned let` が問題というよりは、`piyoClass` を `nil` 許容の変数にしたり、`MogeClass` の生成時に、`piyoClass` を強制アンラップしているのが問題な気がします。

裏を返すと、ここまでしないと、`unowned let` でクラッシュは起こせないです。

もちろん `weak var` でも `delegate!` とすれば、このケースでもクラッシュを起こせるので、どれを使うかはやっぱりケースバイケースだと思います。

銀の弾丸はないということですね。。。

# 結論

delegate に適応した self を弱参照させるパターンは以下の2通りがある。

- 案1: `weak var` で宣言した変数を用意して、delegate に適応した `self` を代入する
   - メリット：シンプルである
   - デメリット：delegate 変数の外部からの変更や、delegete の代入忘れの恐れがある
- 案2: `lazy var` で delegate に適応した `self` を init の引数で渡す。変数は `private weak var` または `private unowned let` で外部からの変更を阻止する
   - メリット：`weak var` を使う場合にあったようなデメリットがなくなる
   - デメリット：`lazy var` を使う影響で、その変数が変更される恐れや、`lazy var` の変数が使われるタイミングで init が走るので、そのタイミングによっては予期せぬバグが発生する（= `lazy var` のリスク）
     - 案2-1: `private weak var` で変数を宣言した場合：
       - メリット：delegate が破棄された状態でアクセスした場合に、`delegate?` か `delegate!` で 実行スキップか、クラッシュかを選べる
       - デメリット：`var` であること
     - 案2-2: `private unowned let` で変数を宣言した場合：
       - メリット：`let` であること
       - デメリット：delegate が破棄された状態でアクセスした場合に、必ずクラッシュする（むしろ、delegate が破棄されないことを想定しているのであれば、クラッシュすることによってバグの早期発見に繋がるのでメリットかもしれません。）
