---
title: '[Swift] [Combine] ローディング状態を表す enum に値を持たせない方法'
tags:
  - Swift
private: false
updated_at: '2023-11-15T20:50:30+09:00'
id: 1766f4b0e02f14c2ef91
organization_url_name: null
slide: false
ignorePublish: false
---

# 伝えたいこと

- ローディング状態を表す enum に値を持たせない方法
  - 『値』と『ローディング状態を表す enum』 を分離する
  - 『値』のストリームに対応して、『ローディング状態を表す enum』を更新する
    - 宣言的な記述ができる `Combine` で記述することがオススメ（`didSet` はやめよう！）
- ローディング状態を表す enum に値を持たせないことのメリット
  - ViewModel側のメリット: 『APIの呼び出し』と『ローディング状態の更新』を分けて記述することができる
  - View側のメリット: 『値』と『ローディング状態を表す enum』 の関心事を分離できる
- 前提として、ローディング状態を表す enum に値を持たせない方がよい（はず）
  - （というよりもそもそもローディング状態を表す enum は必要であれば、その値を管理すべきであるが、画面ごとにローディング状態を管理する必要はなく、共通のローディングを描画する UI コンポーネントのみで、その値を用いるようにした方が良い）（この記事ではそれについて特に触れていません。）


# 前提

以下のような、`HogeResponse` と `MogeResponse` の2つの API のレスポンスとして受け取とる画面において、画面側でローディングの状態に合わせて UI を変化させるための変数（`LoadState`）を公開する `ObservableObject` を適応させた class を考えます。

```swift
struct HogeResponse {
    let hoge: Int
}

struct MogeResponse {
    let moge: Int
}

struct TestError: Error {}
```

# （パターン1）ローディング状態を表す enum に値を持たせた場合

## ViewModel の実装

```swift
enum LoadState {
    case notLoad
    case loading
    case loaded(Result<(HogeResponse, MogeResponse), TestError>) // 値を持たせる
}

class ViewModel: ObservableObject {
    @Published private(set) var loadState: LoadState = .notLoad

    func onAppear() async {
        loadState = .loading

        // API の呼び出し（省略した記述）
        // HogeResponse の取得
        let hogeResponse = HogeResponse(hoge: 1)
        // MogeResponse の取得
        let mogeResponse = MogeResponse(moge: 2)

        loadState = .loaded(.success((hogeResponse, mogeResponse)))
    }
}
```

## View 側のハンドリング

```swift
var cancellables: Set<AnyCancellable> = []
let viewModel = ViewModel()

viewModel.$loadState
    .sink { completion in
        switch completion {
        case .finished:
            print("finished: \(completion)")

        case let .failure(error):
            print("error: \(error)")
        }
    } receiveValue: { result in
        switch result {
        case .notLoad:
            print("notLoad: \(result)")

        case .loading:
            print("loading: \(result)")

        case .loaded(.success((let hogeResponse, let mogeResponse))):
            print("loaded: (hogeResponse: \(hogeResponse), mogeResponse: \(mogeResponse))")

        case .loaded(.failure(let error)):
            print("error: \(error)")
        }
    }
    .store(in: &cancellables)
```

## ローディングの処理

```swift
Task {
    await viewModel.onAppear()
}

// notLoad: notLoad
// loading: loading
// loaded: (hogeResponse: HogeResponse(hoge: 1), mogeResponse: MogeResponse(moge: 2))
```

# （パターン2）ローディング状態を表す enum に値を持たせない場合

## ViewModel の実装

```swift
enum LoadState {
    case notLoad
    case loading
    case loaded // 値を持たせない
}

class ViewModel: ObservableObject {
    @Published private(set) var loadState: LoadState = .notLoad
    @Published private(set) var error: TestError?
    @Published private(set) var hogeResponse: HogeResponse?
    @Published private(set) var mogeResponse: MogeResponse?
    private var cancellables: Set<AnyCancellable> = []

    init() {
        // ローディングのステータスの更新を $hogeResponse と $mogeResponse のストリームから生成する
        $hogeResponse
            .combineLatest($mogeResponse)
            .map { hogeResponse, mogeResponse -> LoadState in
                switch (hogeResponse, mogeResponse) {
                case (.none, .none):
                    return .notLoad

                case (.some, .none):
                    return .loading
                    
                case (.none, .some):
                    return .loading
                    
                case (.some, .some):
                    return .loaded
                }
            }
            .removeDuplicates()
            .assign(to: \.loadState, on: self)
            .store(in: &cancellables)
    }

    func onAppear() async {
        // API の呼び出し（省略した記述）
        // HogeResponse の取得
        hogeResponse = HogeResponse(hoge: 1)
        // MogeResponse の取得
        mogeResponse = MogeResponse(moge: 2)
    }
}
```

一見、複雑になりましたが、`init()` では `hogeResponse` や `mogeResponse` の値に応じて `loadState` の値を更新して、`onAppear()` では API の呼び出しの処理をしているだけになります。

`パターン1` と比較して、記述量は増えましたが、`onAppear()` でやることが、API の呼び出しに集中することができます。

## View 側のハンドリング

`パターン1` と比較して、View側の記述が圧倒的に減ります。

```swift
var cancellables: Set<AnyCancellable> = []
let viewModel = ViewModel()

viewModel.$loadState
    .sink(receiveValue: { print("loadState: \($0)") })
    .store(in: &cancellables)

viewModel.$error
    .compactMap { $0 }
    .sink(receiveValue: { print("error: \($0)") })
    .store(in: &cancellables)

viewModel.$hogeResponse
    .compactMap { $0 }
    .sink(receiveValue: { print("hogeResponse: \($0)") })
    .store(in: &cancellables)

viewModel.$mogeResponse
    .compactMap { $0 }
    .sink(receiveValue: { print("mogeResponse: \($0)") })
    .store(in: &cancellables)
```

## ローディングの処理

```swift
Task {
    await viewModel.onAppear()
}

// loadState: notLoad
// loadState: loading
// hogeResponse: HogeResponse(hoge: 1)
// loadState: loaded
// mogeResponse: MogeResponse(moge: 2)
```

# 伝えたいこと（おさらい）

- ローディング状態を表す enum に値を持たせない方法
  - 『値』と『ローディング状態を表す enum』 を分離する
  - 『値』のストリームに対応して、『ローディング状態を表す enum』を更新する
    - 宣言的な記述ができる `Combine` で記述することがオススメ（`didSet` はやめよう！）
- ローディング状態を表す enum に値を持たせないことのメリット
  - ViewModel側のメリット: 『APIの呼び出し』と『ローディング状態の更新』を分けて記述することができる
  - View側のメリット: 『値』と『ローディング状態を表す enum』 の関心事を分離できる
- 前提として、ローディング状態を表す enum に値を持たせない方がよい（はず）
  - （というよりもそもそもローディング状態を表す enum は必要であれば、その値を管理すべきであるが、画面ごとにローディング状態を管理する必要はなく、共通のローディングを描画する UI コンポーネントのみで、その値を用いるようにした方が良い）（この記事ではそれについて特に触れていません。）

以上です。
