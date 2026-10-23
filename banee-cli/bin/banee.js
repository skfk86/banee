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
const KEY = flags.key || process.env.GEMINI_API_KEY || process.env.GEMINI_KEY;
const MODEL = flags.model || process.env.BANEE_MODEL || 'gemini-2.5-flash';
const log = (s) => console.log(s);
const ask = (q) => new Promise((r) => { const rl = readline.createInterface({ input: process.stdin, output: process.stdout }); rl.question(q, (a) => { rl.close(); r(a.trim()); }); });
const needKey = () => { if (!KEY) { console.error('❌ ضع مفتاح Gemini: export GEMINI_API_KEY=...  (أو --key)'); process.exit(1); } };

const HELP = `🧱 بانِي من الـ terminal

  banee
      محادثة مباشرة داخل المشروع الحالي: اطلب، اسأل، عدّل، وهو يتذكر المحادثة.
      أوامر داخل المحادثة: /new فكرة · /check ملف · /clear · /help · /exit

  banee new "وصف التطبيق" [--out مجلد] [--name الاسم] [--id com.x.app] [--admob ca-app-pub-..~..] [--yes]
  banee new --kit delivery|store|booking|edu
      يبني تطبيقاً كاملاً بمحرك بانِي (محلل ← مخطط ← شاشات ← فحص ← وكيل إصلاح)
      ويخرج مشروع أندرويد Capacitor جاهزاً للرفع على GitHub وبناء APK.

  banee edit "المهمة" [--steps 40]
      وكيل يعمل داخل المشروع الحالي: يقرأ، يعدّل، يفحص، ويصلح أخطاءه.

  banee check [www/index.html]
      فحص أخطاء الصياغة في سكربتات HTML/JS (بلا ذكاء اصطناعي).

المفتاح: export GEMINI_API_KEY=...   النموذج: --model أو BANEE_MODEL (الافتراضي ${MODEL})`;


const CHAT_HELP = `أوامر المحادثة:
  /new وصف التطبيق   بناء تطبيق كامل جديد بمحرك بانِي
  /check [ملف]       فحص أخطاء الصياغة (الافتراضي www/index.html)
  /clear             محادثة جديدة (ينسى ما سبق)
  /exit              خروج
وأي شيء آخر تكتبه يذهب للوكيل مباشرة.`;

async function chat() {
  needKey();
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
  const root = process.cwd();
  log('🧱 بانِي — ' + path.basename(root) + '  (' + MODEL + ')');
  log('اكتب طلبك بالعربي، أو /help للأوامر، أو /exit للخروج.');
  const { createSession, checkJs } = require('../lib/agent');
  const s = createSession({ key: KEY, model: MODEL, root, ask, log, maxSteps: +flags.steps || 40 });
  for (;;) {
    const t = await ask('\n❯ ');
    if (!t) continue;
    if (t === '/exit' || t === 'خروج') return bye();
    if (t === '/help') { log(CHAT_HELP); continue; }
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
      log('  ⏳ ...');
      const r = await s.send(t);
      if (r.summary) log('\n✅ ' + r.summary);
    } catch (e) { log('❌ ' + e.message); }
  }
}

(async () => {
  if (!cmd || cmd === 'chat') return chat();
  if (cmd === 'new') {
    needKey();
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
    needKey();
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
