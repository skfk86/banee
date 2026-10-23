#!/usr/bin/env node
// بانِي CLI
//   banee                         محادثة مباشرة مع الوكيل داخل المشروع الحالي
//   banee new "فكرة التطبيق"      يبني مشروع Capacitor كاملاً بمحرك بانِي
//   banee edit "المهمة"           وكيل يعدّل المشروع الحالي
//   banee check [ملف]             فحص أخطاء الصياغة
const readline = require('readline');
const path = require('path');

const args = process.argv.slice(2);
const cmd = args[0];
const flags = {}, rest = [];
for (let i = 1; i < args.length; i++) {
  const a = args[i];
  if (a.startsWith('--')) { const [k, v] = a.slice(2).split('='); flags[k] = v !== undefined ? v : (args[i + 1] && !args[i + 1].startsWith('--') ? args[++i] : true); }
  else rest.push(a);
}
const text = rest.join(' ').trim();
const os = require('os'), fs = require('fs');
const CFG_FILE = path.join(os.homedir(), '.banee', 'config.json');
const readCfg = () => { try { return JSON.parse(fs.readFileSync(CFG_FILE, 'utf8')); } catch (e) { return {}; } };
const saveCfg = (c) => { fs.mkdirSync(path.dirname(CFG_FILE), { recursive: true }); fs.writeFileSync(CFG_FILE, JSON.stringify(c, null, 2), { mode: 0o600 }); };
let KEY = flags.key || process.env.GEMINI_API_KEY || process.env.GEMINI_KEY || readCfg().key;
const VERSION = require('../package.json').version;
const MODEL = flags.model || process.env.BANEE_MODEL || readCfg().model || 'gemini-2.5-pro';
const log = (s) => console.log(s);
const ask = (q) => new Promise((r) => { const rl = readline.createInterface({ input: process.stdin, output: process.stdout }); rl.question(q, (a) => { rl.close(); r(a.trim()); }); });
// أول تشغيل: يطلب المفتاح مرة واحدة ويتحقق منه ثم يحفظه في ~/.banee/config.json
async function setupKey(askFn, force) {
  if (KEY && !force) return;
  if (!process.stdin.isTTY && !force) { console.error('❌ لا يوجد مفتاح Gemini. شغّل: banee key'); process.exit(1); }
  log('🔑 بانِي يحتاج مفتاح Gemini مفعّل عليه الفوترة (https://aistudio.google.com/apikey)');
  for (;;) {
    const k = (await askFn('الصق المفتاح: ')).trim();
    if (!k) continue;
    process.stdout.write('  يتحقق... ');
    try {
      const r = await fetch('https://generativelanguage.googleapis.com/v1beta/models/' + MODEL + ':generateContent?key=' + encodeURIComponent(k), { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ contents: [{ role: 'user', parts: [{ text: 'ok' }] }], generationConfig: { maxOutputTokens: 1 } }) });
      const j = await r.json().catch(() => ({})), em = (j.error && j.error.message) || '';
      if (r.ok) { saveCfg({ ...readCfg(), key: k }); KEY = k; log('✓ حُفظ المفتاح\n'); return; }
      if (r.status === 429 && /free_tier|free tier/i.test(em)) log('✗ هذا مفتاح على الخطة المجانية. بانِي CLI يتطلب مفتاحاً مفعّل عليه الفوترة (Google AI Studio ← Billing).');
      else log('✗ ' + (em.split('\n')[0] || r.status));
    } catch (e) { log('✗ تعذّر الاتصال: ' + e.message); }
  }
}
const needKey = () => setupKey(ask);

const HELP = `🧱 بانِي من الـ terminal

  banee
      محادثة مباشرة داخل المشروع الحالي: اطلب، اسأل، عدّل، وهو يتذكر المحادثة.
      أوامر داخل المحادثة: /init · /new فكرة · /check ملف · /clear · /help · /exit

  banee new "وصف التطبيق" [--out مجلد] [--name الاسم] [--id com.x.app] [--admob ca-app-pub-..~..] [--yes]
  banee new --kit delivery|store|booking|edu
      يبني تطبيقاً كاملاً بمحرك بانِي (محلل ← مخطط ← شاشات ← فحص ← وكيل إصلاح)
      ويخرج مشروع أندرويد Capacitor جاهزاً للرفع على GitHub وبناء APK.

  banee edit "المهمة" [--steps 40]
      وكيل يعمل داخل المشروع الحالي: يقرأ، يعدّل، يفحص، ويصلح أخطاءه.

  banee check [www/index.html]
      فحص أخطاء الصياغة في سكربتات HTML/JS (بلا ذكاء اصطناعي).

  banee key        تغيير مفتاح Gemini      banee update     تحديث لآخر إصدار

المفتاح يُحفظ عند أول تشغيل، أو: export GEMINI_API_KEY=...   النموذج: --model أو BANEE_MODEL (الافتراضي ${MODEL})`;


const CHAT_HELP = `أوامر المحادثة:
  /new وصف التطبيق   بناء تطبيق كامل جديد بمحرك بانِي
  /check [ملف]       فحص أخطاء الصياغة (الافتراضي www/index.html)
  /init              يدرس المشروع ويكتب له BANEE.md (تعليمات خاصة به)
  /clear             محادثة جديدة (ينسى ما سبق)
  /key               تغيير مفتاح Gemini
  /model [اسم]        عرض النموذج الحالي أو تغييره
  /exit              خروج
وأي شيء آخر تكتبه يذهب للوكيل مباشرة.`;

async function chat() {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  // طابور للمدخلات: ما تكتبه أثناء عمل الوكيل لا يضيع، بل يُنفَّذ بعده بالترتيب
  const queue = [], waiters = []; let closed = false;
  const bye = () => { console.log('\nمع السلامة 👋'); process.exit(0); };
  rl.on('line', (l) => { l = l.trim(); if (waiters.length) waiters.shift()(l); else queue.push(l); });
  rl.on('close', () => { closed = true; if (waiters.length) bye(); });
  const ask = (q) => {
    process.stdout.write(q);
    if (queue.length) { const l = queue.shift(); if (!process.stdin.isTTY) console.log(l); return Promise.resolve(l); }
    if (closed) bye();
    return new Promise((r) => waiters.push(r));
  };
  await setupKey(ask);
  const root = process.cwd();
  log('🧱 بانِي ' + VERSION + ' — ' + path.basename(root) + '  (' + MODEL + ')');
  log('اكتب طلبك بالعربي، أو /help للأوامر، أو /exit للخروج.');
  const { createSession, checkJs, colors: col } = require('../lib/agent');
  const s = createSession({ key: KEY, model: MODEL, root, ask, log, maxSteps: +flags.steps || 40 });
  let t2 = null;
  if (fs.existsSync(path.join(root, 'BANEE.md'))) log('📘 يقرأ تعليمات المشروع من BANEE.md');
  for (;;) {
    const t = await ask('\n' + col.cyan('❯') + ' ');
    if (!t) continue;
    if (t === '/exit' || t === 'خروج') return bye();
    if (t === '/help') { log(CHAT_HELP); continue; }
    if (t === '/key') { await setupKey(ask, true); log('أعد تشغيل banee لاستخدام المفتاح الجديد.'); continue; }
    if (t === '/init') {
      if (fs.existsSync(path.join(root, 'BANEE.md')) && (await ask('BANEE.md موجود. أحدّثه؟ (y/n) ')).toLowerCase() !== 'y') continue;
      t2 = 'ادرس هذا المشروع (البنية، الملفات الرئيسية، الستاك، الإعدادات، أسلوب الكود، الأوامر المهمة) ثم أنشئ أو حدّث ملف BANEE.md في جذره: تعليمات مختصرة بالعربية (أقل من ٨٠ سطراً) لوكيل يعمل على المشروع لاحقاً: ما هو التطبيق، أين كل شيء، الأنماط المتبعة، أوامر البناء والفحص، وما يجب تجنبه. لا تخترع ما لم تره في الملفات.';
    }
    if (t.startsWith('/model')) {
      const m = t.slice(6).trim();
      if (!m) { log('النموذج الحالي: ' + s.model() + '\nللتغيير: /model gemini-2.5-flash  (يُحفظ للمرات القادمة)'); continue; }
      s.setModel(m); saveCfg({ ...readCfg(), model: m }); log('✓ النموذج: ' + m); continue;
    }
    if (t === '/clear') { s.reset(); log('🧹 محادثة جديدة.'); continue; }
    if (t.startsWith('/check')) { try { log(checkJs(path.resolve(root, t.slice(6).trim() || 'www/index.html'))); } catch (e) { log('❌ ' + e.message); } continue; }
    if (t.startsWith('/new')) {
      const idea = t.slice(4).trim();
      if (!idea) { log('اكتب الفكرة: /new تطبيق حجز مواعيد'); continue; }
      try {
        const r = await require('../lib/engine').build({ idea, key: KEY, ask, log });
        if (r) log(`\n✅ جاهز في ${r.minutes} دقيقة: ${r.dir}  — افتحه بـ cd ثم شغّل banee لتكمل عليه بالمحادثة`);
      } catch (e) { log('❌ ' + e.message); }
      continue;
    }
    try {
      const r = await s.send(t2 || t); t2 = null;
      if (r.summary) log('\n' + col.green('✓') + ' ' + r.summary);
    } catch (e) { log('❌ ' + e.message); }
  }
}

(async () => {
  if (!cmd || cmd === 'chat') return chat();
  if (cmd === '--version' || cmd === '-v') return log(VERSION);
  if (cmd === 'key') return setupKey(ask, true);
  if (cmd === 'update') {
    require('child_process').execSync('curl -fsSL https://raw.githubusercontent.com/skfk86/banee/main/site/install.sh | bash', { stdio: 'inherit' });
    return;
  }
  if (cmd === 'new') {
    await needKey();
    if (!text && !flags.kit) { console.error('اكتب وصف التطبيق: banee new "تطبيق حجز مواعيد عيادة"'); process.exit(1); }
    log('🧱 بانِي يبني: ' + (text || 'نظام ' + flags.kit) + '\n');
    const { build } = require('../lib/engine');
    const r = await build({ idea: text, kit: flags.kit, key: KEY, out: flags.out, name: flags.name, appId: flags.id, admob: flags.admob, slug: flags.slug,
      yes: !!flags.yes, verbose: !!flags.verbose, maxMin: +flags.minutes || 110, ask, log });
    if (!r) process.exit(1);
    log(`\n✅ جاهز في ${r.minutes} دقيقة: ${r.dir}  (${r.count} ملفاً، ${r.cfg.appId})`);
    log(`\nالتالي:\n  cd ${path.relative(process.cwd(), r.dir) || '.'}\n  git init && git add . && git commit -m "أول إصدار"\n  # ارفعه على GitHub وسيُبنى APK تلقائياً، أو محلياً: npm i && npx cap add android && npx cap sync`);
    if (!flags.admob) log('\nℹ️  استخدمت معرّف AdMob التجريبي من Google. ضع معرّفك بـ --admob قبل النشر.');
  } else if (cmd === 'edit') {
    await needKey();
    if (!text) { console.error('اكتب المهمة: banee edit "أضف وضعاً ليلياً"'); process.exit(1); }
    log('🧱 بانِي يعمل على: ' + text + '\n');
    const r = await require('../lib/agent').run({ task: text, key: KEY, model: MODEL, root: process.cwd(), ask, log, maxSteps: +flags.steps || 40 });
    log('\n✅ ' + (r.summary || 'انتهى'));
  } else if (cmd === 'check') {
    const f = path.resolve(text || 'www/index.html');
    log(require('../lib/agent').checkJs(f));
  } else {
    log(HELP);
  }
})().catch((e) => { console.error('❌ ' + e.message); process.exit(1); });
