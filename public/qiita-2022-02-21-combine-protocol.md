---
title: "[Swift] [Combine] 配列を引数にとる関数の戻り値が AnyPublisher であるときのインターフェースの検討"
tags:
  - "Swift"
private: false
updated_at: ''
id: 5abbcaddfb9b76e2374c
organization_url_name: null
slide: false
ignorePublish: false
---

# 伝えたいこと

- 配列を引数にとる関数の戻り値が AnyPublisher の場合のインターフェースの場合は以下のことに注意する
  - **Input と Output の紐付けが必要な場合は、順序による暗黙的な紐付けを行わないようにすること**
  - Input と Output の型は統一性があったほうが自然だということ
  - Output を **単体** or **配列** で迷った場合は、**より汎用的な 単体 を用いて**、 Output をまとめて処理したい場合は、**subscribe 側で `collect()` すること**

# はじめに

Combine の特性上、配列処理との相性がとても良いです。

今回は、配列を引数にとる関数の戻り値が AnyPublisher の場合のインターフェースの検討をおこなっていきます。

# やりたいこと

具体例があると想像しやすいので、以下の定義されているときに、『複数の写真のサムネイルに取得して、それを Realm などのデータストアに永続化する処理』をやりたいとして、それを例に検討します。


```swift
import Combine
import Foundation

private var cancellables: Set<AnyCancellable> = []

// PhotoEntity
struct PhotoEntity: Identifiable {
    /// id
    let id: String
    /// サムネイルのURL(サムネイルの未取得の場合は nil)
    var thumbnail: URL?
}

// サムネイルの未取得の PhotoEntity の配列
let photos: [PhotoEntity] = [.init(id: UUID().uuidString), .init(id: UUID().uuidString)]

// サムネイルのfetch処理
func fetchThumbnail(photoId: String) -> URL {
    URL(string: photoId)!
}

// 保存処理（単体版）
func store(photo: PhotoEntity) {
    // Realm などへのデータストアへの保存処理...
    print("PhotoEntityの保存に成功しました！ id: \(photo.id), thumbnail: \(String(describing: photo.thumbnail))")
}

// 保存処理（複数版）
func store(photos: [PhotoEntity]) {
    photos.forEach { store(photo: $0) }
}
```

前提条件は以下になります。

- サムネイルの未取得の `PhotoEntity` の配列がある
- サムネイルの URL の fetch 処理には `PhotoEntity` の `id` が必要
- Realm などへのデータストアへの保存処理の `store()` は単体でも複数でも保存が可能である
- サムネイル取得処理は AnyPublisher 型で返却され、それを subscribe した Output を `store()` していくという実装方針

# インターフェースの案

AnyPublisher を返却する関数の案として、以下の A 〜 F までの 6 つの案を考えたとき、どれが良いかを検討します。

```swift
protocol PhotoDownloadDriverProtocol {
    // 案 A
    func fetchThumbnailA(photoIds: [String]) -> AnyPublisher<[URL], Never>
    
    // 案 B
    func fetchThumbnailB(photoIds: [String]) -> AnyPublisher<URL, Never>
    
    // 案 C
    func fetchThumbnailC(photoIds: [String]) -> AnyPublisher<(photoId: String, thumbnailURL: URL), Never>
    
    // 案 D
    func fetchThumbnailD(photoIds: [String]) -> AnyPublisher<PhotoEntity, Never>
    
    // 案 E
    func fetchThumbnailE(photos: [PhotoEntity]) -> AnyPublisher<PhotoEntity, Never>
    
    // 案 F
    func fetchThumbnailF(photos: [PhotoEntity]) -> AnyPublisher<[PhotoEntity], Never>
}
```

A 〜 F までの 6 つの案の違いを表でまとめると以下になります。

| 案 | Input                    | Output                                 | 
