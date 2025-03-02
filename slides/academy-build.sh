#!/bin/sh
mkdir -p out
rm -f _redirects academy-index.html
echo "/ /academy-index.html 200!" >> _redirects
while read MD
do
  MD=$MD envsubst < academy-template.yml >/tmp/md.yml
  FILE=$(basename ${MD%.md})
  ./markmaker.py /tmp/md.yml > out/$FILE.html
  echo "/$FILE /out/$FILE.html 200!" >> _redirects
  TITLE=$(head -n1 $MD | sed 's/^#* //')
  printf '<a href="%s">%s</a><br/>\n' "$FILE" "$TITLE" >> academy-index.html
done  < academy-toc.txt
