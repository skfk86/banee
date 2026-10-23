// وكيل التعديل: يعمل داخل مشروع موجود، يقرأ ويعدّل وينفّذ أوامر، ثم يفحص عمله ويصلح أخطاءه
const fs = require('fs'), path = require('path');
const { execSync } = require('child_process');

const SYSTEM = `أنت "بانِي"، وكيل برمجة يعمل داخل مشروع على جهاز المطور.
الستاك: تطبيقات Capacitor بملف HTML واحد (www/index.html) بـ HTML/CSS/JS، Firebase للـ backend، AdMob للإعلانات، واجهات عربية RTL.
طريقة العمل:
1. افهم المشروع أولاً (list_dir ثم read_file للملفات المهمة). الملفات الكبيرة اقرأها بأجزاء (from/to بالأسطر) أو ابحث فيها بـ search.
2. عدّل بأقل تغيير ممكن عبر edit_file، ولا تعيد كتابة ملف كبير كاملاً، ولا تحذف كوداً لا علاقة له بالمهمة.
3. بعد كل تعديل افحص عملك: check_js لملفات HTML/JS، ثم أعد قراءة الجزء المعدّل.
4. إن ظهر خطأ أصلحه وأعد الفحص.
5. عند الانتهاء استدعِ done بملخص قصير بالعربية لما تغيّر.`;

const S = (props, req) => ({ type: 'object', properties: props, required: req });
const str = { type: 'string' }, int = { type: 'integer' };
const tools = [{ functionDeclarations: [
  { name: 'list_dir', description: 'عرض محتوى مجلد', parameters: S({ path: str }, ['path']) },
  { name: 'read_file', description: 'قراءة ملف، مع أسطر من/إلى اختيارياً', parameters: S({ path: str, from: int, to: int }, ['path']) },
  { name: 'search', description: 'بحث عن نص أو regex في ملفات المشروع، يعيد الملف ورقم السطر', parameters: S({ pattern: str, path: str }, ['pattern']) },
  { name: 'write_file', description: 'إنشاء ملف جديد أو استبدال ملف صغير كاملاً', parameters: S({ path: str, content: str }, ['path', 'content']) },
  { name: 'edit_file', description: 'استبدال نص محدد داخل ملف (يجب أن يظهر مرة واحدة بالضبط)', parameters: S({ path: str, old_text: str, new_text: str }, ['path', 'old_text', 'new_text']) },
  { name: 'check_js', description: 'فحص أخطاء الصياغة في ملف .js أو في سكربتات ملف .html', parameters: S({ path: str }, ['path']) },
  { name: 'run_command', description: 'تنفيذ أمر shell داخل المشروع', parameters: S({ command: str }, ['command']) },
  { name: 'done', description: 'إنهاء المهمة مع ملخص', parameters: S({ summary: str }, ['summary']) },
] }];

const SKIP = ['node_modules', '.git', 'android', 'ios', 'dist', 'vendor'];
const DANGER = /\b(rm|sudo|git\s+push|git\s+reset|git\s+checkout|mkfs|dd|chmod|chown|curl|wget|npm\s+publish)\b|>\s*\//;

function walk(dir, out = []) {
  for (const d of fs.readdirSync(dir, { withFileTypes: true })) {
    if (SKIP.includes(d.name) || d.name.startsWith('.')) continue;
    const f = path.join(dir, d.name);
    if (d.isDirectory()) walk(f, out); else if (fs.statSync(f).size < 3e6) out.push(f);
  }
  return out;
}

function checkJs(file) {
  const vm = require('vm');
  const src = fs.readFileSync(file, 'utf8');
  const blocks = file.endsWith('.html')
    ? [...src.matchAll(/<script(?![^>]*\bsrc=)([^>]*)>([\s\S]*?)<\/script>/gi)].filter((m) => !/type=["']?(module|application\/json|text\/template)/i.test(m[1])).map((m) => ({ code: m[2], line: src.slice(0, m.index).split('\n').length }))
    : [{ code: src, line: 1 }];
  const errs = [];
  for (const b of blocks) {
    try { new vm.Script(b.code); } catch (e) {
      const ln = (String(e.stack).match(/evalmachine\.<anonymous>:(\d+)/) || [])[1];
      errs.push(e.message + (ln ? ' — السطر ' + (b.line + +ln - 1) : ''));
    }
  }
  return errs.length ? 'أخطاء:\n' + errs.join('\n') : 'سليم ✓ (' + blocks.length + ' سكربت)';
}

async function run({ task, key, model, root, ask, log, maxSteps = 40 }) {
  const safe = (p) => { const f = path.resolve(root, p || '.'); if (f !== root && !f.startsWith(root + path.sep)) throw new Error('مسار خارج المشروع'); return f; };
  const rel = (f) => path.relative(root, f);

  async function tool(name, a) {
    try {
      switch (name) {
        case 'list_dir':
          return fs.readdirSync(safe(a.path), { withFileTypes: true }).filter((d) => !SKIP.includes(d.name))
            .map((d) => d.isDirectory() ? d.name + '/' : d.name + ' (' + fs.statSync(path.join(safe(a.path), d.name)).size + 'b)').join('\n');
        case 'read_file': {
          const lines = fs.readFileSync(safe(a.path), 'utf8').split('\n');
          const from = Math.max(1, a.from || 1), to = Math.min(lines.length, a.to || from + 599);
          return lines.slice(from - 1, to).map((l, i) => (from + i) + '\t' + l.slice(0, 2000)).join('\n') + (to < lines.length ? `\n...[الملف ${lines.length} سطراً، اقرأ from=${to + 1}]` : '');
        }
        case 'search': {
          const re = new RegExp(a.pattern, 'i'), hits = [];
          for (const f of walk(safe(a.path || '.'))) {
            fs.readFileSync(f, 'utf8').split('\n').forEach((l, i) => { if (hits.length < 80 && re.test(l)) hits.push(rel(f) + ':' + (i + 1) + ': ' + l.trim().slice(0, 200)); });
          }
          return hits.join('\n') || 'لا نتائج';
        }
        case 'write_file':
          fs.mkdirSync(path.dirname(safe(a.path)), { recursive: true });
          fs.writeFileSync(safe(a.path), a.content); log('  ✏️  كتب ' + a.path); return 'تم';
        case 'edit_file': {
          const f = safe(a.path), t = fs.readFileSync(f, 'utf8'), n = t.split(a.old_text).length - 1;
          if (n !== 1) return `خطأ: النص موجود ${n} مرة (المطلوب مرة واحدة بالضبط، وسّع النص)`;
          fs.writeFileSync(f, t.replace(a.old_text, () => a.new_text)); log('  ✏️  عدّل ' + a.path); return 'تم';
        }
        case 'check_js': { const r = checkJs(safe(a.path)); log('  🔍 فحص ' + a.path + ': ' + r.split('\n')[0]); return r; }
        case 'run_command': {
          log('  ⚙️  ' + a.command);
          if (DANGER.test(a.command) && (await ask('  ⚠️  أمر حساس، تنفيذ؟ (y/n) ')).toLowerCase() !== 'y') return 'رفض المستخدم تنفيذ الأمر';
          return execSync(a.command, { cwd: root, encoding: 'utf8', timeout: 300000, stdio: 'pipe' }).slice(-8000) || '(بدون مخرجات)';
        }
      }
      return 'أداة غير معروفة';
    } catch (e) { return 'خطأ: ' + (((e.stdout || '') + (e.stderr || '')) || e.message).slice(-8000); }
  }

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${key}`;
  const contents = [{ role: 'user', parts: [{ text: task }] }];
  for (let step = 1; step <= maxSteps; step++) {
    let data;
    for (let tries = 0; ; tries++) {
      const res = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ systemInstruction: { parts: [{ text: SYSTEM }] }, contents, tools }) });
      data = await res.json();
      if (res.ok) break;
      if ((res.status === 429 || res.status >= 500) && tries < 3) { log('  ⏳ Gemini مشغول، إعادة المحاولة...'); await new Promise((r) => setTimeout(r, 15000 * (tries + 1))); continue; }
      throw new Error('Gemini: ' + (data.error?.message || res.status));
    }
    const reply = data.candidates?.[0]?.content;
    if (!reply || !reply.parts) throw new Error('لا رد من النموذج');
    contents.push(reply);
    reply.parts.filter((x) => x.text && x.text.trim()).forEach((x) => log('💬 ' + x.text.trim()));
    const calls = reply.parts.filter((x) => x.functionCall);
    if (!calls.length) return { summary: '' };
    const results = [];
    for (const { functionCall: fc } of calls) {
      if (fc.name === 'done') return { summary: fc.args.summary };
      results.push({ functionResponse: { name: fc.name, response: { result: await tool(fc.name, fc.args || {}) } } });
    }
    contents.push({ role: 'user', parts: results });
  }
  throw new Error('وصل للحد الأقصى من الخطوات');
}

module.exports = { run, checkJs };
