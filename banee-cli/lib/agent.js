// وكيل التعديل: يعمل داخل مشروع موجود، يقرأ ويعدّل وينفّذ أوامر، ثم يفحص عمله ويصلح أخطاءه
const fs = require('fs'), path = require('path');
const { execSync } = require('child_process');

// التعليمات العامة (instructions.md) + تعليمات المشروع (BANEE.md في مجلد المشروع إن وُجد)
function systemPrompt(root) {
  let t = fs.readFileSync(path.join(__dirname, 'instructions.md'), 'utf8');
  for (const name of ['BANEE.md', 'banee.md']) {
    const f = path.join(root, name);
    if (fs.existsSync(f)) { t += '\n\n# تعليمات هذا المشروع (من ' + name + '، لها الأولوية على العامة)\n\n' + fs.readFileSync(f, 'utf8').slice(0, 20000); break; }
  }
  return t;
}

const TTY = process.stdout.isTTY && !process.env.NO_COLOR;
const C = (code) => (t) => TTY ? '\x1b[' + code + 'm' + t + '\x1b[0m' : t;
const dim = C('2'), red = C('31'), green = C('32'), yellow = C('33'), cyan = C('36'), bold = C('1');

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
  { name: 'todo', description: 'قائمة مهام للعمل متعدد الخطوات (٣ خطوات أو أكثر): أرسل القائمة كاملة في كل مرة مع حالة كل بند. بند واحد فقط in_progress في كل وقت.', parameters: S({ items: { type: 'array', items: S({ text: str, status: { type: 'string', enum: ['pending', 'in_progress', 'completed'] } }, ['text', 'status']) } }, ['items']) },
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

function createSession({ key, model, root, ask, log, maxSteps = 40 }) {
  const safe = (p) => { const f = path.resolve(root, p || '.'); if (f !== root && !f.startsWith(root + path.sep)) throw new Error('مسار خارج المشروع'); return f; };
  const rel = (f) => path.relative(root, f);

  async function tool(name, a) {
    try {
      switch (name) {
        case 'todo': {
          const ic = { pending: '☐', in_progress: yellow('◐'), completed: green('☑') };
          log('');
          for (const it of a.items || []) log('  ' + (ic[it.status] || '☐') + ' ' + (it.status === 'completed' ? dim(it.text) : it.status === 'in_progress' ? bold(it.text) : it.text));
          log('');
          return 'تم تحديث القائمة';
        }
        case 'list_dir':
          log(dim('  ● عرض ' + (a.path || '.')));
          return fs.readdirSync(safe(a.path), { withFileTypes: true }).filter((d) => !SKIP.includes(d.name))
            .map((d) => d.isDirectory() ? d.name + '/' : d.name + ' (' + fs.statSync(path.join(safe(a.path), d.name)).size + 'b)').join('\n');
        case 'read_file': {
          log(dim('  ● قرأ ' + a.path + (a.from || a.to ? ' (' + (a.from || 1) + '–' + (a.to || '') + ')' : '')));
          const lines = fs.readFileSync(safe(a.path), 'utf8').split('\n');
          const from = Math.max(1, a.from || 1), to = Math.min(lines.length, a.to || from + 599);
          return lines.slice(from - 1, to).map((l, i) => (from + i) + '\t' + l.slice(0, 2000)).join('\n') + (to < lines.length ? `\n...[الملف ${lines.length} سطراً، اقرأ from=${to + 1}]` : '');
        }
        case 'search': {
          const re = new RegExp(a.pattern, 'i'), hits = [];
          for (const f of walk(safe(a.path || '.'))) {
            fs.readFileSync(f, 'utf8').split('\n').forEach((l, i) => { if (hits.length < 80 && re.test(l)) hits.push(rel(f) + ':' + (i + 1) + ': ' + l.trim().slice(0, 200)); });
          }
          log(dim('  ● بحث «' + a.pattern + '» — ' + hits.length + ' نتيجة'));
          return hits.join('\n') || 'لا نتائج';
        }
        case 'write_file':
          fs.mkdirSync(path.dirname(safe(a.path)), { recursive: true });
          const existed = fs.existsSync(safe(a.path));
          fs.writeFileSync(safe(a.path), a.content);
          log('  ' + cyan('●') + ' ' + (existed ? 'استبدل ' : 'أنشأ ') + bold(a.path) + dim(' (' + a.content.split('\n').length + ' سطراً)'));
          return 'تم';
        case 'edit_file': {
          const f = safe(a.path), t = fs.readFileSync(f, 'utf8'), n = t.split(a.old_text).length - 1;
          if (n !== 1) return `خطأ: النص موجود ${n} مرة (المطلوب مرة واحدة بالضبط، وسّع النص)`;
          fs.writeFileSync(f, t.replace(a.old_text, () => a.new_text));
          const line = t.slice(0, t.indexOf(a.old_text)).split('\n').length;
          const o = a.old_text.split('\n'), nw = a.new_text.split('\n');
          log('  ' + cyan('●') + ' عدّل ' + bold(a.path) + dim(' (سطر ' + line + ', ' + red('-' + o.length) + ' ' + green('+' + nw.length) + ')'));
          const show = (arr, sign, col) => { arr.slice(0, 8).forEach((l) => log('    ' + col(sign + ' ' + l.slice(0, 140)))); if (arr.length > 8) log(dim('    … ' + (arr.length - 8) + ' سطراً أخرى')); };
          show(o, '-', red); show(nw, '+', green);
          return 'تم';
        }
        case 'check_js': { const r = checkJs(safe(a.path)); const ok = r.startsWith('سليم'); log('  ' + (ok ? green('✓') : red('✗')) + ' فحص ' + a.path + (ok ? '' : '\n    ' + red(r.split('\n').slice(1, 4).join('\n    ')))); return r; }
        case 'run_command': {
          log('  ' + cyan('●') + ' ' + bold('$ ' + a.command));
          if (DANGER.test(a.command) && (await ask('  ⚠️  أمر حساس، تنفيذ؟ (y/n) ')).toLowerCase() !== 'y') return 'رفض المستخدم تنفيذ الأمر';
          const out = execSync(a.command, { cwd: root, encoding: 'utf8', timeout: 300000, stdio: 'pipe' });
          const tail = out.trim().split('\n').slice(-4); if (out.trim()) tail.forEach((l) => log(dim('    ' + l.slice(0, 140))));
          return out.slice(-8000) || '(بدون مخرجات)';
        }
      }
      return 'أداة غير معروفة';
    } catch (e) {
      const msg = (((e.stdout || '') + (e.stderr || '')) || e.message);
      log('    ' + red(msg.trim().split('\n').slice(-3).join('\n    ').slice(0, 400)));
      return 'خطأ: ' + msg.slice(-8000);
    }
  }

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${key}`;
  let contents = [];

  async function call() {
    for (let tries = 0; ; tries++) {
      const res = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ systemInstruction: { parts: [{ text: systemPrompt(root) }] }, contents, tools }) });
      const data = await res.json();
      if (res.ok) return data;
      if ((res.status === 429 || res.status >= 500) && tries < 3) { log(dim('  ⏳ Gemini مشغول، إعادة المحاولة...')); await new Promise((r) => setTimeout(r, 15000 * (tries + 1))); continue; }
      throw new Error('Gemini: ' + (data.error?.message || res.status));
    }
  }

  // رسالة واحدة من المستخدم؛ المحادثة كلها محفوظة في contents فيتذكر الوكيل ما سبق
  async function send(text) {
    const mark = contents.length;
    contents.push({ role: 'user', parts: [{ text }] });
    try {
      for (let step = 1; step <= maxSteps; step++) {
        const data = await call();
        const reply = data.candidates?.[0]?.content;
        if (!reply || !reply.parts) throw new Error('لا رد من النموذج');
        contents.push(reply);
        reply.parts.filter((x) => x.text && x.text.trim() && !x.thought).forEach((x) => log('\n' + x.text.trim()));
        const calls = reply.parts.filter((x) => x.functionCall);
        if (!calls.length) return { summary: '' };
        const results = []; let summary = null;
        for (const { functionCall: fc } of calls) {
          if (fc.name === 'done') { summary = fc.args.summary || ''; results.push({ functionResponse: { name: 'done', response: { result: 'تم' } } }); continue; }
          results.push({ functionResponse: { name: fc.name, response: { result: await tool(fc.name, fc.args || {}) } } });
        }
        contents.push({ role: 'user', parts: results });
        if (summary !== null) return { summary };
      }
      return { summary: '⏹️ وصلت للحد الأقصى من الخطوات في هذه الرسالة، قل «كمّل» لأتابع' };
    } catch (e) { contents = contents.slice(0, mark); throw e; } // لا نترك المحادثة في حالة مكسورة
  }

  return { send, reset: () => { contents = []; }, size: () => contents.length };
}

async function run(o) { return createSession(o).send(o.task); }

module.exports = { run, createSession, checkJs, systemPrompt, colors: { dim, red, green, yellow, cyan, bold } };
