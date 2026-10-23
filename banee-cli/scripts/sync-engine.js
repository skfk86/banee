// ينسخ محرك بانِي (www/index.html) إلى banee-cli/engine حتى تعمل الأداة بعد تثبيتها من npm بلا المستودع
const fs = require('fs'), path = require('path');
const src = path.resolve(__dirname, '../../www/index.html');
const dst = path.resolve(__dirname, '../engine/index.html');
if (!fs.existsSync(src)) { console.error('لم أجد ' + src); process.exit(1); }
fs.mkdirSync(path.dirname(dst), { recursive: true });
fs.copyFileSync(src, dst);
console.log('✓ نُسخ المحرك:', Math.round(fs.statSync(dst).size / 1024), 'ك.ب');
