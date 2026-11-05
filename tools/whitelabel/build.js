#!/usr/bin/env node
// يولّد نسخة خاصة (White-label) من بانِي لشركة مرخّصة: اسمها وشعارها وخادمها ومشروع Firebase الخاص بها،
// مع مفتاح الترخيص الذي تتحقق منه النسخة عند خادم بانِي الأصلي.
// الاستخدام: node tools/whitelabel/build.js <مجلد-الشركة>   (فيه brand.json وlogo.png وأيقونات اختيارية)
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..');
const dir = path.resolve(process.argv[2] || '');
if (!process.argv[2] || !fs.existsSync(path.join(dir, 'brand.json'))) { console.error('ضع brand.json في مجلد الشركة، مثال: tools/whitelabel/brand.example.json'); process.exit(1); }
const B = JSON.parse(fs.readFileSync(path.join(dir, 'brand.json'), 'utf8'));
const need = ['name', 'appId', 'proxyUrl', 'firebase', 'license'];
for (const k of need) if (!B[k]) { console.error('brand.json ينقصه: ' + k); process.exit(1); }
if (!/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$/.test(B.appId)) { console.error('appId غير صالح: ' + B.appId); process.exit(1); }
if (!/^BNL-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(B.license.key || '')) { console.error('مفتاح الترخيص غير صالح، أنشئه بـ createLicense في خادمك'); process.exit(1); }

const slug = (B.nameEn || B.appId.split('.').pop()).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || 'brand';
const OUT = path.join(ROOT, 'dist', slug);
fs.rmSync(OUT, { recursive: true, force: true });
const cp = (a, b) => { fs.mkdirSync(path.dirname(b), { recursive: true }); fs.cpSync(a, b, { recursive: true }); };

let html = fs.readFileSync(path.join(ROOT, 'www/index.html'), 'utf8');
const ORIG_PROXY = (html.match(/^var PROXY_URL = '([^']*)';/m) || [])[1];
if (!ORIG_PROXY) { console.error('لم أجد PROXY_URL في www/index.html'); process.exit(1); }
const sub = (re, val, what) => { if (!re.test(html)) { console.error('لم أجد ' + what); process.exit(1); } html = html.replace(re, val); };

// ١) الاسم في كل الواجهة والتعليمات (مع حروف الجر الملتصقة: ببانِي، لبانِي، وبانِي...)
const AR = '\u0621-\u064A\u066E-\u06D3'; // حروف فقط: الفاصلة «،» والأرقام ليست جزءاً من الكلمة
html = html.replace(new RegExp('(^|[^' + AR + '])([وفبلك]{0,2})بانِ?ي(?![' + AR + '])', 'gm'), (m, a, pre) => a + pre + B.name);
// ٢) الخادم وFirebase ورابط المشاركة والترخيص وصاحب المنتج
sub(/^var PROXY_URL = '[^']*';/m, "var PROXY_URL = '" + B.proxyUrl + "';", 'PROXY_URL');
sub(/var FB_CONFIG = \{[\s\S]*?\n\};/, 'var FB_CONFIG = ' + JSON.stringify(B.firebase, null, 2) + ';', 'FB_CONFIG');
if (B.shareBase) sub(/^var SHARE_BASE = '[^']*';/m, "var SHARE_BASE = '" + B.shareBase + "';", 'SHARE_BASE');
sub(/var LICENSE = null; \/\*LICENSE\*\//, 'var LICENSE = ' + JSON.stringify({ key: B.license.key, server: ORIG_PROXY, app: B.appId, contact: B.contact || '' }) + '; /*LICENSE*/', 'LICENSE');
if (B.maker) sub(/var BANEE_MAKER = '[^']*';/, "var BANEE_MAKER = '" + String(B.maker).replace(/'/g, '') + "';", 'BANEE_MAKER');
html = html.split('com.alloush.banee').join(B.appId);
// ٣) الشعار
if (B.logo && fs.existsSync(path.join(dir, B.logo))) {
  const ext = path.extname(B.logo).slice(1).replace('jpg', 'jpeg');
  const uri = 'data:image/' + ext + ';base64,' + fs.readFileSync(path.join(dir, B.logo)).toString('base64');
  sub(/(\.brand-mark \{ background: url\()data:image\/[a-z]+;base64,[A-Za-z0-9+/=]+(\))/, '$1' + uri + '$2', 'الشعار (.brand-mark)');
}

fs.mkdirSync(path.join(OUT, 'www'), { recursive: true });
fs.writeFileSync(path.join(OUT, 'www/index.html'), html);
cp(path.join(ROOT, 'www/vendor'), path.join(OUT, 'www/vendor'));
// أيقونات التطبيق: من مجلد الشركة إن وُجدت، وإلا أيقونات بانِي (يجب استبدالها قبل النشر)
for (const f of ['icon-only.png', 'icon-foreground.png', 'icon-background.png', 'splash.png', 'splash-dark.png'])
  cp(fs.existsSync(path.join(dir, f)) ? path.join(dir, f) : path.join(ROOT, 'assets', f), path.join(OUT, 'assets', f));
const cap = JSON.parse(fs.readFileSync(path.join(ROOT, 'capacitor.config.json'), 'utf8'));
cap.appId = B.appId; cap.appName = B.name;
fs.writeFileSync(path.join(OUT, 'capacitor.config.json'), JSON.stringify(cap, null, 2));
cp(path.join(ROOT, 'package.json'), path.join(OUT, 'package.json'));
cp(path.join(ROOT, 'firestore.rules'), path.join(OUT, 'firestore.rules'));
// خادم الشركة: نفس Code.gs بمشروعها وحزمتها، بلا تراخيص (لا يبيع نسخاً بنفسه)
let gs = fs.readFileSync(path.join(ROOT, 'server/Code.gs'), 'utf8');
gs = gs.replace(/PROJECT_ID: '[^']*'/, "PROJECT_ID: '" + B.firebase.projectId + "'").replace(/PACKAGE_NAME: '[^']*'/, "PACKAGE_NAME: '" + B.appId + "'");
gs = gs.replace(/\n\/\/ ═+ تراخيص النسخ الخاصة[\s\S]*$/, '\n').replace("    if (req.op === 'license') return out(licenseCheck(req));\n", '');
gs = gs.replace(new RegExp('(^|[^' + AR + '])([وفبلك]{0,2})بانِ?ي(?![' + AR + '])', 'gm'), (m, a, pre) => a + pre + B.name);
fs.mkdirSync(path.join(OUT, 'server'), { recursive: true });
fs.writeFileSync(path.join(OUT, 'server/Code.gs'), gs);
cp(path.join(ROOT, 'server/appsscript.json'), path.join(OUT, 'server/appsscript.json'));
cp(path.join(__dirname, 'SETUP.md'), path.join(OUT, 'SETUP.md'));

const left = (html.match(/بانِي/g) || []).length;
console.log('✅ نسخة «' + B.name + '» جاهزة في ' + path.relative(ROOT, OUT) + (left ? ' (بقي ' + left + ' موضعاً للاسم القديم داخل كلمات مركّبة، راجعها)' : ''));
