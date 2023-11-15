---
title: npm-scripts の 順次・並列実行（npm-run-all）
tags:
  - npm
  - npm-scripts
  - npm-run-all
private: false
updated_at: '2020-11-04T01:38:52+09:00'
id: 2a17a3cdfbc4a7e5e4eb
organization_url_name: null
slide: false
ignorePublish: false
---
# npm-run-all

> 公式 [npm-run-all](https://www.npmjs.com/package/npm-run-all)

npm-run-all は複数の npm-scripts を実行できるコマンドラインツールです。
オプションをつけることで引数の npm-scripts の順次実行 または 並列実行することができます。

# 実行コマンド

- 順次実行
  - `npm-run-all --serial <task>` = `npm-run-all -s <task>` = `run-s <task>`
- 並列実行
  - `npm-run-all --parallel <task>` = `npm-run-all -p <task>` = `run-p <task>`

# 実際にやってみた

## npm-scripts の準備

```shell
# 以下のような hello:foo と hello:bar という npm-scripts を追加
# （ちなみに && は左の処理が成功したら右の処理を実行するというもの）
$ vi package.json
{
  (省略)
  "scripts": {
+   "hello:foo": "sleep 1 && echo FOO",
+   "hello:bar": "sleep 1 && echo BAR"
  },
  (省略)
}

# 1秒後に "FOO" を echo する
$ npm run -s hello:foo
FOO

# 1秒後に "BAR" を echo する
$ npm run -s hello:bar
BAR
```

## npm-run-all のインストール

```shell
# npm-run-all のパッケージをインストール
$ npm install --save-dev npm-run-all
```

## 実行

```shell

# hello:foo と hello:bar を順次実行する hello-s と hello:foo と hello:bar を並列実行する hello-p を登録
$ vi package.json
{
  (省略)
  "devDependencies": {
    "npm-run-all": "^4.1.5"
  },
  "scripts": {
    "hello:foo": "sleep 1 && echo FOO",
    "hello:bar": "sleep 1 && echo BAR",
+   "hello-s": "run-s hello:foo hello:bar",
+   "hello-p": "run-p hello:foo hello:bar"
  },
  (省略)
}

# FOO が echo されて 1秒後に BAR が echo される（順次実行）
$ npm run -s hello-s
FOO
BAR

# FOO と BAR がほぼ同時に echo される（並列実行）
$ npm run -s hello-p
BAR
FOO
```

# ハマったこと

## npm-run-all は scripts に登録したことしか実行できない

なのでこういうことはできません。

```json:package.json
{
  (省略)
  "scripts": {
    "hoge": "npm-run-all -s 'sleep 1'"
  },
  (省略)
}
```

以下のように怒られます。

```
$ npm run hoge

> vpass_api_spec_document@1.0.0 hoge /Users/sugurutakahashi/git/vpass_api_spec_document
> npm-run-all -s 'sleep 1'

ERROR: Task not found: "sleep"
npm ERR! code ELIFECYCLE
npm ERR! errno 1
npm ERR! vpass_api_spec_document@1.0.0 hoge: `npm-run-all -s 'sleep 1'`
npm ERR! Exit status 1
npm ERR! 
npm ERR! Failed at the vpass_api_spec_document@1.0.0 hoge script.
npm ERR! This is probably not a problem with npm. There is likely additional logging output above.

npm ERR! A complete log of this run can be found in:
npm ERR!     /Users/sugurutakahashi/.npm/_logs/2020-11-03T16_29_57_468Z-debug.log
```
これは sleep コマンドが npm でインストールされたコマンドではないから、というわけでもなく、scripts にないコマンドは実行できないみたいです。

あくまでも npm-run-all は scripts の実行順のコントロール専用ということでしょうね。

scripts にワンライナーで一気に登録するより、細かく scripts にコマンドを登録して、それを npm-run-all でコントロールするという使い方が適切なようです。
