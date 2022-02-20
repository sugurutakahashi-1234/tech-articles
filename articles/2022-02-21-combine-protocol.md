---
title: "[Swift] [Combine] 配列を引数にとる関数の return が AnyPublisher の場合のインターフェースの検討"
emoji: "🌾"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Swift"]
published: false
---

# 伝えたいこと

- a
- b

# もげもげ

```swift
import Combine
import Foundation

private var cancellables: Set<AnyCancellable> = []


// PhotoEntity
struct PhotoEntity: Identifiable {
    let id: String
    var thumbnail: URL?
}

// サムネイルの未取得のPhotoEntity
let photos: [PhotoEntity] = [.init(id: UUID().uuidString), .init(id: UUID().uuidString)]

// サムネイルのfetch処理
func fetchThumbnail(photoId: String) -> URL {
    URL(string: photoId)!
}

// 保存処理（単体版）
func store(photo: PhotoEntity) {
    // Realmなどへの保存処理...
    print("PhotoEntityの保存に成功しました！ id: \(photo.id), thumbnail: \(String(describing: photo.thumbnail))")
}

// 保存処理（複数版）
func store(photos: [PhotoEntity]) {
    photos.forEach { store(photo: $0) }
}
```

## インターフェースの案

```swift
protocol PhotoDownloadDriverProtocol {
    // パターンA
    func fetchThumbnailA(photoIds: [String]) -> AnyPublisher<[URL], Never>
    
    // パターンB
    func fetchThumbnailB(photoIds: [String]) -> AnyPublisher<URL, Never>
    
    // パターンC
    func fetchThumbnailC(photoIds: [String]) -> AnyPublisher<(photoId: String, thumbnailURL: URL), Never>
    
    // パターンD
    func fetchThumbnailD(photoIds: [String]) -> AnyPublisher<PhotoEntity, Never>
    
    // パターンE
    func fetchThumbnailE(photos: [PhotoEntity]) -> AnyPublisher<PhotoEntity, Never>
    
    // パターンF
    func fetchThumbnailF(photos: [PhotoEntity]) -> AnyPublisher<[PhotoEntity], Never>
}
```

## インターフェースを適応したDriverの実装

```swift
class PhotoDownloadDriver: PhotoDownloadDriverProtocol {
    // パターンA
    func fetchThumbnailA(photoIds: [String]) -> AnyPublisher<[URL], Never> {
        Just(photoIds.map { fetchThumbnail(photoId: $0) })
            .eraseToAnyPublisher()
    }
    
    // パターンB
    func fetchThumbnailB(photoIds: [String]) -> AnyPublisher<URL, Never> {
        photoIds.publisher
            .map { fetchThumbnail(photoId: $0) }
            .eraseToAnyPublisher()
    }
    
    // パターンC
    func fetchThumbnailC(photoIds: [String]) -> AnyPublisher<(photoId: String, thumbnailURL: URL), Never> {
        photoIds.publisher
            .map { (photoId: $0, thumbnailURL: fetchThumbnail(photoId: $0)) }
            .eraseToAnyPublisher()
    }
    
    // パターンD
    func fetchThumbnailD(photoIds: [String]) -> AnyPublisher<PhotoEntity, Never> {
        photoIds.publisher
            .map { PhotoEntity(id: $0, thumbnail: fetchThumbnail(photoId: $0)) }
            .eraseToAnyPublisher()
    }
    
    // パターンE
    func fetchThumbnailE(photos: [PhotoEntity]) -> AnyPublisher<PhotoEntity, Never> {
        photos.publisher
            .map { PhotoEntity(id: $0.id, thumbnail: fetchThumbnail(photoId: $0.id)) }
            .eraseToAnyPublisher()
    }
    
    // パターンF
    func fetchThumbnailF(photos: [PhotoEntity]) -> AnyPublisher<[PhotoEntity], Never> {
        Just(photos.map { PhotoEntity(id: $0.id, thumbnail: fetchThumbnail(photoId: $0.id)) })
            .eraseToAnyPublisher()
    }
}

let photoDownloadDriver: PhotoDownloadDriver = .init()
```

## subscribe 側の記述

```swift
// パターンAの場合
photoDownloadDriver.fetchThumbnailA(photoIds: photos.map { $0.id })
    .sink { print("completion A: \($0)") } receiveValue: { urls in
        guard photos.count == urls.count else {
            assertionFailure("photos.count is not equal urls.count.")
            return
        }
        store(photos: photos.indices.map { PhotoEntity(id: photos[$0].id, thumbnail: urls[$0]) })
    }
    .store(in: &cancellables)

// パターンBの場合
photoDownloadDriver.fetchThumbnailB(photoIds: photos.map { $0.id })
    .zip(photos.publisher)
    .sink { print("completion B: \($0)") } receiveValue: { url, photo in
        store(photo: PhotoEntity(id: photo.id, thumbnail: url))
    }
    .store(in: &cancellables)

// パターンCの場合
photoDownloadDriver.fetchThumbnailC(photoIds: photos.map { $0.id })
    .sink { print("completion C: \($0)") } receiveValue: { photoId, thumbnailURL in
        store(photo: PhotoEntity(id: photoId, thumbnail: thumbnailURL))
    }
    .store(in: &cancellables)

// パターンDの場合
photoDownloadDriver.fetchThumbnailD(photoIds: photos.map { $0.id })
    .sink { print("completion D: \($0)") } receiveValue: { store(photo: $0) }
    .store(in: &cancellables)

// パターンEの場合
photoDownloadDriver.fetchThumbnailE(photos: photos)
    .sink { print("completion E: \($0)") } receiveValue: { store(photo: $0) }
    .store(in: &cancellables)

// パターンFの場合
photoDownloadDriver.fetchThumbnailF(photos: photos)
    .sink { print("completion F: \($0)") } receiveValue: { store(photos: $0) }
    .store(in: &cancellables)
```