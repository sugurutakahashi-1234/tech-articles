import cryptoRandomString from 'crypto-random-string';
import { readFile, writeFile } from 'fs';

function generateSlug() {
  return cryptoRandomString({ length: 20, type: "hex"});
}

readFile('data4.json', 'utf-8', (err, data) => {
  var jsonData = JSON.parse(data)
  jsonData.forEach(d => {
    var toppics = d.tags.map(tag => tag.name)
    var title = d.title
    var header = `---
title: "${title}"
emoji: "🔖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["${toppics.join('","')}"]
published: true
---
`
    var body = d.body
    var issue = `${header}${body}`
    var fileName = `${generateSlug()}.md`
    writeFile(fileName, issue, (err) => {
      if (err) throw err
    })
  });
})