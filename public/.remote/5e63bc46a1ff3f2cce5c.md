---
title: コミットをまとめる方法（git rebase -i）
tags:
  - Git
  - GitHub
private: false
updated_at: '2021-12-23T16:24:15+09:00'
id: 5e63bc46a1ff3f2cce5c
organization_url_name: null
slide: false
ignorePublish: false
---

# 問題です
現在、 `コミットID_1` の `develop` ブランチから別のブランチである `feature/hogehoge` ブランチを派生させて `コミットID_2` → `コミットID_3` → `コミットID_4` の順に修正をコミットし、`feature/hogehoge` ブランチをリモートブランチにプッシュしています。

この状態で `コミットID_2` 〜 `コミットID_4` のコミットをまとめたい場合どのようにすればよいでしょうか？

**つまり、これを**
`コミット1（develop ブランチ）` → `コミット2（feature/hogehoge ブランチ）` → `コミット3（feature/hogehoge ブランチ）` → `コミット4（feature/hogehoge ブランチ）`

**こうしたい**
`コミット1（develop ブランチ）` → `コミット2〜4（feature/hogehoge ブランチ）`


# 答え

1. 対象のブランチにチェクアウトして `git log --oneline` で rebase 元になるコミット ID を探す
1. `git rebase -i <コミット ID>` で rebase を実行する
1. Edit モードで rebase 指示書を修正する
1. `git push --force-with-lease origin HEAD` で強制プッシュする

## 1. `git log --oneline` で rebase 元になるコミット ID を探す

```bash
$ git checkout feature/hogehoge
$ git log --oneline

コミットID_4 (HEAD -> feature/hogehoge, origin/feature/hogehoge)コミットメッセージ_4
コミットID_3 コミットメッセージ_3
コミットID_2 コミットメッセージ_2
コミットID_1 (origin/develop, origin/HEAD, develop) コミットメッセージ_1
```

## 2. `git rebase -i <コミット ID>` で rebase を実行する

まとめるコミット ID の1つ前を指定して、`git rebase -i` を実行します。
今回の場合は `コミットID_2` 〜 `コミットID_4` をまとめるので `コミットID_1` を指定します。

```bash
$ git rebase -i コミットID_1
```

## 3. Edit モードで rebase 指示書を修正する

`git rebase -i` を実行すると Edit モードで以下のような表示が出現します。
ここで表示されるのは `コミットID_1` からみて時系列順でコミットが上から並んでいます（`git log --oneline`とは逆順のはず）。

```bash
pick コミットID_2 コミットメッセージ_2
pick コミットID_3 コミットメッセージ_3
pick コミットID_4 コミットメッセージ_4

# Rebase xxxxx..yyyyy onto zzzzzz
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup <commit> = like "squash", but discard this commit's log message
# x, exec <command> = run command (the rest of the line) using shell
# b, break = stop here (continue rebase later with 'git rebase --continue')
# d, drop <commit> = remove commit
# l, label <label> = label current HEAD with a name
# t, reset <label> = reset HEAD to a label
# m, merge [-C <commit> | -c <commit>] <label> [# <oneline>]
```

今回は `コミットID_2` に `コミットID_3` と `コミットID_4` をまとめる方法を選択します（`コミットID_4` にまとめる方法はないはずです。）。
省略形の `p` とか `r` とか `f` を指定することが多いはずです。

```bash:コミットメッセージ修正しない場合
p コミットID_2 コミットメッセージ_2
f コミットID_3 コミットメッセージ_3
f コミットID_4 コミットメッセージ_4
```

Edit モードを `:wq` でセーブして抜けて rebase がうまくいくと以下が出力されます。

```bash
Successfully rebased and updated refs/heads/feature/hogehoge.
```

これで rebase は完了です。

### コミットメッセージを修正する場合

多くの場合はコミットメッセージを修正するので、rebase 指示書を以下のようにします。（`r` がポイント）

```bash:コミットメッセージ修正する場合
r コミットID_2 コミットメッセージ_2
f コミットID_3 コミットメッセージ_3
f コミットID_4 コミットメッセージ_4
```

Edit モードを `:wq` でセーブして抜けるとコミットメッセージの修正が求められます。

それも`:wq` でセーブして抜けると、以下のような表示がされるので、`git rebase --continue` してrebase を進めてください。

```bash
Aborting commit due to empty commit message.
You can amend the commit now, with

  git commit --amend 

Once you are satisfied with your changes, run

  git rebase --continue
```

## 4. `git push --force-with-lease origin HEAD` で強制プッシュする

強制プッシュします。
このときに作業中のブランチが間違っていないかは確認したほうがいいです。

```bash
$ git push --force-with-lease origin HEAD
```



## （番外編） rebase 中に操作ミスした場合

以下を実行すると `git rebase -i` 実行前に戻るはずです。

```bash
$ git rebase --abort
```
