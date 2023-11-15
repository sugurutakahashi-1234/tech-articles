#!/bin/bash

# Zenn 記事のディレクトリ TODO: スクリプトの引数にする
ZENN_DIR="./articles"

# Qiita 記事のディレクトリ
QIITA_DIR="public"

# Qiita 記事の反映
npx qiita pull

# Zenn の記事を Qiita のフォーマットに変換して複製する
for FILE in $(ls $ZENN_DIR | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}'); do
    # Qiita の記事ファイル名
    QIITA_FILE="$QIITA_DIR/$(basename "$FILE" .md).md"

    # Zenn の記事を読み込み
    ZENN_ARTICLE=$(<"$ZENN_DIR/$FILE")

    # Zenn のヘッダー情報（YAML形式）を解析
    ZENN_TITLE=$(echo "$ZENN_ARTICLE" | grep '^title:' | sed 's/title: "\(.*\)"/\1/')
    ZENN_TOPICS=$(echo "$ZENN_ARTICLE" | grep '^topics:' | sed 's/topics: \[\(.*\)\]/\1/')

    # 既に同名のファイルが存在する場合は更新、存在しない場合は新規作成
    if [ -f "$QIITA_FILE" ]; then
        echo "Updating file $QIITA_FILE..."
        QIITA_ID=$(grep '^id:' "$QIITA_FILE" | sed 's/id: //')
    else
        echo "Creating new file $QIITA_FILE..."
        npx qiita new "$(basename "$FILE" .md)"
        QIITA_ID="null"
    fi

    # Qiita の記事ヘッダーを更新
    echo "---" > $QIITA_FILE
    echo "title: \"$ZENN_TITLE\"" >> $QIITA_FILE
    echo "tags:" >> $QIITA_FILE
    IFS=', ' read -r -a array <<< "$ZENN_TOPICS"
    for element in "${array[@]}"
    do
        echo "  - $element" >> $QIITA_FILE
    done
    echo "private: false" >> $QIITA_FILE
    echo "updated_at: ''" >> $QIITA_FILE
    echo "id: $QIITA_ID" >> $QIITA_FILE
    echo "organization_url_name: null" >> $QIITA_FILE
    echo "slide: false" >> $QIITA_FILE
    echo "ignorePublish: false" >> $QIITA_FILE

    # Zenn の記事本文を Qiita の記事に追加
    echo "$ZENN_ARTICLE" | awk '/---/{i++}i==2' >> $QIITA_FILE
done

# 記事の投稿
npx qiita publish --all
echo "Completed Zenn to Qiita"
