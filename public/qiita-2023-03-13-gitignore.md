---
title: "[git] gitignore.io から .gitignore ファイルを npx コマンドで生成する方法"
tags:
  - "gitignore"
private: false
updated_at: ''
id: 776ddbae37accb844243
organization_url_name: null
slide: false
ignorePublish: false
---

# 動機

環境構築する際に [gitignore.io](https://www.toptal.com/developers/gitignore/) からコマンドラインからファイルが取得できれば楽だと思い、やり方を探したところ[公式ドキュメント](https://docs.gitignore.io/install/client-applications#node-tejas-kumar)にやり方が書いてありました。

そのまま紹介したいと思います。

# 環境

- Node.js 環境導入済

```shell
$ node -v
v19.7.0
```

```shell
$ npm -v
9.6.1
```

# コマンド実行

`npx add-gitignore` を実行するだけです。

```shell
$ npx add-gitignore
? What environments would your .gitignore to ignore?
❯◯ 1c
 ◯ 1c-bitrix
 ◯ a-frame
 ◯ actionscript
 ◯ ada
 ◯ adobe
 ◯ advancedinstaller
 ◯ adventuregamestudio
 ◯ agda
 ◯ al
```

コマンド実行後に、文字を入力すると検索ができるので、指定したい言語やフレームワークを十字キーでカーソルを合わせてスペースキーで選択ができます。

選択した状態で Enter キーを入力するとコマンドを実行した階層に `.gitignore` ファイルが生成されます。

# 余談

これをうまく組み込んで CI で自動更新できないかとも思ったのですが、`.gitignore` ファイルは自動更新するようなものではない気がするので、検討するのを辞めました。

以上です。
