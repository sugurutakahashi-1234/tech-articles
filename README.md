# tech articles

- Zenn:
  - https://zenn.dev/ikuraikura
- Qiita:
  - https://qiita.com/sugurutakahashi12345

## はじめに

このリポジトリでは [Zenn CLI](https://zenn.dev/zenn/articles/zenn-cli-guide) と [Qiita CLI](https://github.com/increments/qiita-cli) によって、Zenn と Qiita の記事の投稿を管理しております。

- Zenn CLI:
  - https://zenn.dev/zenn/articles/zenn-cli-guide
- Qiita CLI:
  - https://github.com/increments/qiita-cli

具体的には、Zenn のアカウントと紐付けられているこのリポジトリの [articles](https://github.com/suguruTakahashi-1234/tech-articles/tree/main/articles) に Zenn の記事を書き、それを push することで Zenn へ記事が投稿され、その過程で git hook の pre-commit で実行されるスクリプトの処理で、Qiita CLI により、Qiita 用の記事の生成と投稿を行っております。

つまり、Zenn が親、Qiita が子の関係になっております。

また、Zenn と Qiita には全く同じ記事が投稿され、「Zenn のみに投稿したい」、「Qiita のみに投稿したい」ということは、一旦、できなくなっております。

## 使い方

以下の git hook を設定して、[articles](https://github.com/suguruTakahashi-1234/tech-articles/tree/main/articles) に Zenn 用の記事を書いて、push するだけです。

### git hook の設定

```shell
git config --local core.hooksPath .githooks
```

### Zenn の記事を Qiita にも投稿するスクリプトの実行

commit せずに実行したい場合は以下のコマンドでも実行できます。

```shell
sh zenn-to-qiita.sh
```

※ git hook を設定していれば pre-commit によっても実行されます。

### git hook を止めたい場合

```shell
git config --local --unset core.hooksPath .githooks
```


## 経緯と制約

Qiita を親にして、Zenn が子にできなくもなさそうですが、一度、Qiita から Zenn に完全移行した経緯から、Zenn を親にせざるを得なかったためそうなっております。

以前は Qiita の記事は Qiita CLI がなく GitHub 管理することができなく、Zenn では GitHub 管理することができたので移行したのですが、 Qiita CLI がでたことでそんなことする必要もなくなり、Qiita の方が記事がよくみられる傾向にあったので、どうせ両方とも GitHub 上で管理できるので、同じリポジトリで同じ記事を管理できないかと思い、このようになりました。

ただ、その経緯による制約もあり、記事の管理の関係上、新しく書く Zenn の記事のマークダウンファイル名は `yyyy-mm-dd-` で開始しなればならなくなっております。

また、Qiita から Zenn に移行した際のファイルがリポジトリに残ってるのもその影響です。（消してもいいのですが、とりあえずとっておいています。）

「Qiita しかやっていない」、「Zenn しかやっていない」という状況であれば、やっている方を親にして、やっていない方を子にする方がいいと思います。
