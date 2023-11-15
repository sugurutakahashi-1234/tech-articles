---
title: docker-compose を用いて Apache・PHP・MySQL の開発環境を構築してみた
tags:
  - PHP
  - MySQL
  - Apache
  - Docker
  - docker-compose
private: false
updated_at: '2021-02-24T23:21:40+09:00'
id: 5daf89b2d33ef8d9fa2e
organization_url_name: null
slide: false
ignorePublish: false
---
# はじめに

docker-compose を用いて Apache・PHP・MySQL の開発環境を構築してみた備忘録になります。

# 構成図


![ddd.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/259125/83455a40-d189-8150-b9ab-358bf470e8cc.png)

[GitHub](https://github.com/suguruTakahashi-1234/docker-compose-sample) にもあげました。ご参考まで。


# できたこと

以下を自動化する docker-compose の開発環境構築を行いました。

- DocumentRoot の変更
- php.ini の変更
- my.cnf の変更
- MySQL への初期データの投入
- MySQL のデータの永続化
- PHP-Apache コンテナから MySQL コンテナへの疎通

つまり、これらの環境がワンライナーで構築できるようになりました。

# バージョン情報

docker-compose はインストールされていることが前提になります。
今回は以下のバージョンでの動きになります。

```shell
$ docker-compose -v
docker-compose version 1.26.2, build eefe0d31
```

PHP のバージョンは 5.4、MySQL のバージョンは 5.5 の環境を構築します。
Apache のバージョンは特に気にしていません。

# ディレクトリ構造

ディレクトリ構造は以下のようになります。

```shell
.
├── config
│   ├── mysql
│   │   ├── Dockerfile
│   │   ├── initdb.d
│   │   │   └── init.sql
│   │   └── my.cnf
│   └── php
│       ├── Dockerfile
│       ├── apache2.conf
│       ├── php.ini
│       └── sites
│           ├── 000-default.conf
│           └── default-ssl.conf
├── data
├── docker-compose.yml
└── html
    └── test
        ├── connect.php
        └── index.php
```

# 設定

各サービスに以下のような設定ファイルがそれぞれあると思いますが、それらを変更したものを動かしたいと思います。

## Apache の設定

今回は DocumentRoot を変更してみます。

[公式ドキュメント](https://hub.docker.com/_/php) をみると以下のように Dockerfile を記述することで DocumentRoot を変更できるようです。

<img width="1181" alt="b.png" src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/259125/723a16cf-4c9c-a0b5-889b-421886f715e4.png">


~~いろいろな記事をみるとコンテナから 000-default.conf などの設定ファイルをホスト側にもってきてそれを修正した後、Dockerfile の `COPY` でコンテナ側にコピーするようでした。~~

~~やはり公式ドキュメントをみるのが一番ですね。~~

公式ドキュメントのように行ったらコンテナが再起動ループに陥ってしまいました。

※ 理由をよく調べたら php:5.5-apache 以降であればそれでよかったらしいです。

なので、php:5.4-apache のイメージからコンテナを立ち上げて、元ファイルをホスト側にコピーして、それを編集することにしました。

```shell
# とりあえず php:5.4-apache のコンテナを動かしてログインする
$ docker image pull php:5.4-apache
$ docker container run --name php54apache -d php:5.4-apache
$ docker exec -it php54apache /bin/bash

# 設定ファイルを確認 ( php:5.4-apache 以前は apache2.conf の修正も必要)
$ ls /etc/apache2/apache2.conf
httpd.conf

$ ls /etc/apache2/sites-available
000-default.conf  default-ssl.conf

# コンテナを抜ける
$ exit

# ホスト側にコピー
$ docker container cp php54apache:/etc/apache2/apache2.conf ./config/php
$ docker container cp php54apache:/etc/apache2/sites-available/000-default.conf ./config/php/sites
$ docker container cp php54apache:/etc/apache2/sites-available/default-ssl.conf ./config/php/sites
```

これらの `apache2.conf`、`000-default.conf`、`default-ssl.conf` に記述してある DocumentRoot を変更します。

今回は以下のように変更しました。

```shell
# DocumentRoot /var/www/html
DocumentRoot /var/www/html/test
```
これで DocumentRoot の変更の準備は完了です。

## PHP の設定

PHP は `php.ini` によって設定を行います。

[公式ドキュメント](https://hub.docker.com/_/php) をみると以下のように記述することで php.ini を指定するらしいです。

<img width="766" alt="a.png" src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/259125/d9576ccb-7260-6052-312c-d5dcd5218f9d.png">

しかし、コンテナを立ち上げてログインしてみても、 `php.ini-development` や `php.ini-produciton` のようなファイルは存在しませんでした。

おそらく Apache の設定でもそうであったように公式のドキュメントは過去のバージョンまで挙動は保証していないようです。

サンプルにあるような `php:7.4-fpm-alpine` ならそれで良さそうですね。

今回は `php.ini-development` や `php.ini-produciton` については GitHub で公開してあったのでそちらの [php.ini-development](https://github.com/php/php-src/blob/master/php.ini-development) を元に php.ini を作成することにしました。

php.ini の修正については[こちら](https://qiita.com/hikotaro_san/items/0aab2a53726674c50868)を参照して、ロケーションや言語の設定を修正しました。



## MySQL の設定ファイルの変更

MySQL の設定ファイルは `my.cnf` によって行います。

MySQL の設定ファイルの my.cnf は [公式ドキュメント](https://hub.docker.com/_/mysql) によると `/etc/mysql/my.cnf` に配置してあるとのことでした。

<img width="1223" alt="c.png" src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/259125/80c28a39-3ae3-6d20-352e-ca670694e281.png">

なのでそちらをローカルホストに持ってきて、適宜修正していきたいと思います。

```shell
# とりあえず mysql:5.5 のコンテナを動かしてログインする
$ docker image pull mysql:5.5
$ docker container run -e MYSQL_ROOT_PASSWORD=sample_pw --name mysql55 -d mysql:5.5
$ docker exec -it mysql55 /bin/bash

# /etc/mysql/my.cnf を確認
$ ls /etc/mysql/my.cnf
/etc/mysql/my.cnf

# コンテナを抜ける
$ exit

# my.cnf をホスト側にコピー
$ docker container cp mysql55:/etc/mysql/my.cnf ./config/mysql/
```

あとは環境に合わせて修正して、`my.cnf` を作成してください。

※ ちなみに今回は `my.cnf` の修正は行っていません。

# Dockerfile の作成

Dockerfile は `php:5.4-apache` と `mysql:5.5` のイメージについて作成しました。

## php:5.4-apache

```Dockerfile:config/php/Dockerfile
# image
FROM php:5.4-apache

# Set php.ini
COPY ./php.ini /usr/local/etc/php/

# Set apache conf (Before tag:5.4-apache)
COPY ./apache2.conf /etc/apache2/
COPY ./sites/*.conf /etc/apache2/sites-available/

# Set apache conf (After tag:5.5-apache)
# ENV APACHE_DOCUMENT_ROOT /var/www/html/test
# RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
# RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Install MySQL connection module
RUN apt-get update \
  && apt-get install -y libpq-dev \
  && docker-php-ext-install pdo_mysql pdo_pgsql mysqli mbstring
```

ここでは「DocumentRoot の変更」、「php.ini の配置」、「MySQL と疎通するためのモジュールを追加」しています。

## mysql:5.5

```Dockerfile:config/mysql/Dockerfile
# image
FROM mysql:5.5

# Set my.cnf
COPY ./my.cnf /etc/mysql/conf.d/

# Set Japanese
RUN apt-get update && apt-get install -y \
  locales \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
RUN sed -i -E 's/# (ja_JP.UTF-8)/\1/' /etc/locale.gen \
  && locale-gen
ENV LANG ja_JP.UTF-8
CMD ["mysqld", "--character-set-server=utf8", "--collation-server=utf8_unicode_ci"]
```

デフォルトのままであると MySQL にログインした後に日本語の入力ができなかったため、ここでは日本語を入力可能にするような設定をおこなています。

MySQL の日本語の設定は [こちら](https://oki2a24.com/2020/03/27/use-japanese-in-debian-based-docker-containers/) を参照しました。

# MySQL の初期データの投入

docker-compose 起動時に MySQL に初期データを投入してみたく、以下のような SQL を用意しました。

```sql:init.sql
DROP TABLE IF EXISTS sample_table;

CREATE TABLE sample_table (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name TEXT NOT NULL
) charset=utf8;

INSERT INTO sample_table (name) VALUES ("太郎"),("花子"),("令和");
```

コンテナ起動後にここで記述した SQL が実行されていることを確認します。

# docker-compose.yml の作成

以下のように docker-compose.yml を作成しました。

```yml:docker-compose.yml
version: '3.8'

services:

  # PHP Apache
  php-apache:
    build: ./config/php
    ports:
      - "8080:80"
    volumes:
      - ./html:/var/www/html
    restart: always
    depends_on:
      - mysql

  # MySQL
  mysql:
    build: ./config/mysql
    ports:
      - 3306:3306
    volumes:
      - ./config/mysql/initdb.d:/docker-entrypoint-initdb.d
      - ./data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: sample_root_passward
      MYSQL_DATABASE: sample_db
      MYSQL_USER: sample_user
      MYSQL_PASSWORD: sample_pass
```

## MySQL のデータの永続化について

MySQL のデータディレクトリは /var/lib/mysql であり、 `- ./data:/var/lib/mysql` とあるようにホスト側の `./data` ディレクトリにマウントすることによってデータを永続化しております。

試してみたところ `docker-compose stop` や `docker-compose down` してもデータが永続化されていることが確認できました。

# docker-compose 使い方

いよいよ docker-compose を動かします。

## docker-compose 起動

まずはなにも起動されていないことを確認します。

```shell
$ docker-compose ps
Name   Command   State   Ports
------------------------------

$ docker container ls
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
````

今回はわかりやすいようにコンテナも空の状態にしておきます。

docker-compose.yml が存在する階層で `docker-compose up -d` コマンドを実行することで、docker-compose.yml の記述をもとにコンテナが作成されます。

※ docker-compose のコマンドの `build` と `up` の違いやオプションについては[こちら](https://qiita.com/tegnike/items/bcdcee0320e11a928d46)がわかりやすかったです。

```shell
# image の作成
$ docker-compose build --no-cache
Successfully tagged docker-compose-sample_php-apache:latest

# コンテナの構築・起動
$ docker-compose up -d
Creating network "docker-compose-sample_default" with the default driver
Creating docker-compose-sample_mysql_1 ... done
Creating docker-compose-sample_php-apache_1 ... done

# docker-compose の確認
$ docker-compose ps
               Name                            Command             State           Ports
-------------------------------------------------------------------------------------------------
docker-compose-sample_mysql_1        docker-entrypoint.sh mysqld   Up      0.0.0.0:3306->3306/tcp
docker-compose-sample_php-apache_1   apache2-foreground            Up      0.0.0.0:8080->80/tcp

# コンテナの確認
$ docker container ls
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS              PORTS                    NAMES
26b0cec2daad        docker-compose-sample_php-apache   "apache2-foreground"     3 minutes ago       Up 3 minutes        0.0.0.0:8080->80/tcp     docker-compose-sample_php-apache_1
eaae044f4bba        mysql:5.5                          "docker-entrypoint.s…"   3 minutes ago       Up 3 minutes        0.0.0.0:3306->3306/tcp   docker-compose-sample_mysql_1
```

コンテナが動いていることが確認できました。

## PHP-Apache コンテナの確認

DocumentRoot の直下に配置する、php:5.4-apache コンテナの疎通確認用のページとして以下のようなファイルを用意しました。

```php:html/test/index.php
<?php
echo  __DIR__;
phpinfo();
```

`http://localhost:8080` にアクセスすると以下のように表示されるはずです。

`echo  __DIR__;` はその PHP ファイルが置かれている絶対パスを出力するので DocumentRoot の変更が行われていることが確認できます。

また、`php.ini` についてオリジナルものから修正を加えていれば、`phpinfo();` の出力でそちらも反映されていることも確認できるかと思います。

<img width="692" alt="f.png" src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/259125/44a69daa-0557-a852-061b-e92e8fd7250b.png">


# MySQL コンテナの確認

`mysql:5.5` のイメージで作成されたコンテナにログインして、初期データが投入されていることを確認します。

```:shell
# コンテナにログイン
$ docker exec -it eaae044f4bba /bin/bash

# MySQL にログイン
$ mysql -p
Enter password:
```

パスワードを求められるので docker-compose.yml で `MYSQL_ROOT_PASSWORD` の環境変数に登録した `sample_root_passward` と入力するとログインできます。

docker-compose.yml に登録した `MYSQL_DATABASE`、`MYSQL_USER` が登録されていることを確認します。

```shell
mysql> select user, host from mysql.user;

+-------------+-----------+
| user        | host      |
+-------------+-----------+
| root        | %         |
| sample_user | %         |
| root        | localhost |
+-------------+-----------+
3 rows in set (0.00 sec)

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sample_db          |
+--------------------+
4 rows in set (0.00 sec)
```

`sample_user` と `sample_db` があることが確認できました。

続いて `init.sql` で作成したテーブルとカラムについても確認してみます。

```shell
mysql> use sample_db;
Database changed

mysql> show tables;
+---------------------+
| Tables_in_sample_db |
+---------------------+
| sample_table        |
+---------------------+
1 row in set (0.00 sec)

mysql> select * from sample_table;
+----+--------+
| id | name   |
+----+--------+
|  1 | 太郎 |
|  2 | 花子 |
|  3 | 令和 |
+----+--------+
3 rows in set (0.00 sec)
```

テーブルとカラムについても問題なく確認できました。

# PHP-Apache から MySQL コンテナへの疎通確認

PHP-Apache から MySQL コンテナへの疎通確認用のページとして以下のようなファイルを用意しました。

```php:html/test/connect.php
<?php
try {
    // host=XXXの部分のXXXにはmysqlのサービス名を指定します
    $dsn = 'mysql:host=mysql;dbname=sample_db;';
    $db = new PDO($dsn, 'sample_user', 'sample_pass');

    $sql = 'SELECT * FROM sample_table;';
    $stmt = $db->prepare($sql);
    $stmt->execute();
    $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
    var_dump($result);
} catch (PDOException $e) {
    echo $e->getMessage();
    exit;
}
```
※ 注意点として、ホスト名は `localhost` や `127.0.0.1` ではなく、docker-compose.yml でサービス名として指定してた `mysql` を使用します。

`http://localhost:8080/connect.php` にアクセスすると以下のように表示されればが PHP-Apache から MySQL コンテナへの疎通がうまく行っています。

<img width="747" alt="g.png" src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/259125/303bce94-ad40-d217-f926-c4c173118d5c.png">
さきほど、初期投入されたデータが確認できますね。

## docker-compose 停止・削除

以下のコマンドで 停止・削除 を行います。

```shell
# コンテナを停止
$ docker-compose stop

# コンテナを停止し、そのコンテナとネットワークの削除
$ docker-compose down

# コンテナを停止し、そのコンテナとネットワークを削除、さらにイメージも削除
$ docker-compose down --rmi all --volumes
```

`./config/mysql/initdb.d/init.sql` の初期データ投入からやり直したい時などは `docker-compose down --rmi all --volumes` してから `./data` ディレクトリの中身も削除して `docker-compose up -d` でコンテナの構築・起動からやり直してください。

# まとめ

以下を自動化する docker-compose の開発環境構築を行いました。

- DocumentRoot の変更
- php.ini の変更
- my.cnf の変更
- MySQL への初期データの投入
- MySQL のデータの永続化
- PHP-Apache コンテナから MySQL コンテナへの疎通

つまり、これらの環境がワンライナーで構築できるようになりました。

# 学んだこと

今回初めて docker-compose で開発環境を構築してみて学んだことを羅列します。

- 公式ドキュメント（DockerHub）は読んだ方がいい
    - Qiita よりも DockerHub を先に見た方がよさそうです。
- docker-compose.yml と Dockerfile は書き分ける
    - 一度変更すればコンテナ起動後に変更のない設定ファイルなどは Dockerfile で `COPY` でコンテナ側にファイルを配置して、コンテナ起動後に変更のあるものは docker-compose.yml でマウントさせるという書き分けがよさそうです。
- Dockerfile をいきなり書くのは難しい
    - 以下の手順で Dockerfile を書くと良いです。
        - ベースイメージを決める
        - ベースイメージのコンテナ内で作業しつつ、うまくいった処理をメモ
        - 全て成功したらDockerfileを作成

以上になります。


