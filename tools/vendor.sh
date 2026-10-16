#!/bin/sh
# يعيد بناء نسخة Firebase المضمّنة في www/vendor/firebase بنفس FB_VERSION في index.html
set -e
V=$(grep -o "FB_VERSION = '[0-9.]*'" www/index.html | grep -o "[0-9.]*")
ROOT=$(pwd); T=$(mktemp -d); cd "$T"; npm init -y >/dev/null; npm i --silent firebase@$V esbuild@0.24.0
for m in app auth firestore; do echo "export * from 'firebase/$m';" > firebase-$m.js; done
rm -rf "$ROOT/www/vendor/firebase"
npx esbuild firebase-app.js firebase-auth.js firebase-firestore.js --bundle --splitting --format=esm --minify --legal-comments=none --outdir="$ROOT/www/vendor/firebase"
