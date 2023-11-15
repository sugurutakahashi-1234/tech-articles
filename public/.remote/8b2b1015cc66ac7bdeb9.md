---
title: '[Swift] [Combine] Publisher を flatMap() 内に隠蔽して直接 subscribe するのを避ける方法'
tags:
  - Swift
private: false
updated_at: '2023-11-15T20:50:30+09:00'
id: 8b2b1015cc66ac7bdeb9
organization_url_name: null
slide: false
ignorePublish: false
---

# はじめに

以下の記事にもあるように、『Failure となる可能性がある Publisher を直接 subscribe している場合、一度でも Failure が発生すると、その時点で Completion となり、Output を受け付けなくなる』という挙動を示します。

- [[Swift] [Combine] エラーがあっても止まらないストリームを作りたい！](https://zenn.dev/ikuraikura/articles/2022-02-17-result)

その回避方法として、記事内では `flatMap() 内での tryMap() -> catch -> Empty の合わせ技` を紹介しているのですが、**そもそも外側にある Publisher を `flatMap()` 内に隠蔽する方法について、いくつかパターンがあるので、それを紹介する記事になります。**

