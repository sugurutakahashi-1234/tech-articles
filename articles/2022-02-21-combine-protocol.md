---
title: "[Swift] [Combine] 配列を引数にとる関数の return が AnyPublisher の場合のインターフェースの検討"
emoji: "🌾"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Swift"]
published: false
---

# 伝えたいこと

- 1つの Publisher を  `share()` せずに共有した場合は subscribe した数だけ重複して処理が走ってしまうので、`share()` をすることによって、それを防ぐことができる（この記事の[前編](https://zenn.dev/ikuraikura/articles/2022-02-19-share)の内容になります）
- **`share()` した Publisher について、subscribe する前に出力された値は、再度出力されない**
- **そのため、値の出力と subscribe のタイミングによっては、出力を逃してしまう**
- 対策案
  - 案1: **`share()` の直前に `delay()` する**
    - ただし、どのくらいの秒数 `delay()` すればよいかは、処理によってまちまちなので、**ワークアラウンド的に使用する**
  - 案2: **`share()` ではなく `multicast()` ＆ `connect()` を使う**
    - `connect()` のタイミングによっては、出力を逃してしまうので注意が必要
  - 案3: subscribe した数だけ重複して処理が走ってしまうことを受け入れて、`share()` や  `multicast()` ＆ `connect()` を使用せずに**諦める**

# share() の挙動の振り返り
