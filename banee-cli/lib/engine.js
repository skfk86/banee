// يشغّل محرك بانِي الحقيقي (www/index.html) في متصفح خفي: نفس المحلل والمخطط والشاشات والفحص ووكيل الإصلاح
// ثم يصدّر مشروع أندرويد Capacitor بنفس دالة التصدير في التطبيق (androidFiles + الأيقونات + شاشة البداية)
const fs = require('fs'), os = require('os'), path = require('path');

function enginePath() {
  const cands = [path.resolve(__dirname, '../engine/index.html'), path.resolve(__dirname, '../../www/index.html')];
  const f = cands.find((p) => fs.existsSync(p));
  if (!f) throw new Error('لم أجد محرك بانِي. شغّل: npm run sync-engine');
  return f;
}

// نسخة محلية: بلا خادم (المفتاح مفتاح المستخدم) وخارج www حتى لا يتصل Firebase
function prepareEngine() {
  const html = fs.readFileSync(enginePath(), 'utf8').replace(/^var PROXY_URL = '[^']*';/m, "var PROXY_URL = '';");
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'banee-'));
  const f = path.join(dir, 'banee.html');
  fs.writeFileSync(f, html);
  return f;
}

async function build(o) {
  const { idea, kit, key, out, ask, log } = o;
  let chromium;
  try { ({ chromium } = require('playwright')); } catch (e) { throw new Error('ثبّت المتصفح: npm i && npx playwright install chromium'); }
  const b = await chromium.launch();
  try {
    const ctx = await b.newContext({ viewport: { width: 390, height: 844 } });
    await ctx.route(/gstatic\.com\/firebasejs/, (r) => r.abort());
    await ctx.addInitScript(([k, name]) => {
      if (sessionStorage.getItem('cli')) return; sessionStorage.setItem('cli', '1');
      localStorage.setItem('buser', JSON.stringify({ uid: 'cli', name, email: 'cli@banee.app' }));
      localStorage.setItem('bprofile', JSON.stringify({ plan: 'business', name }));
      localStorage.setItem('bgkey', k); localStorage.setItem('bonb', '1');
    }, [key, os.userInfo().username || 'مطوّر']);
    const p = await ctx.newPage();
    p.on('console', (m) => { if (o.verbose && /^AGENT/.test(m.text())) log('🤖 ' + m.text()); });
    p.on('response', async (r) => {
      if (/generativelanguage/.test(r.url()) && r.status() !== 200) {
        let t = ''; try { t = (await r.text()).slice(0, 300); } catch (e) {}
        log('⚠️  Gemini ' + r.status() + ' ' + t.replace(/\s+/g, ' '));
      }
    });
    await p.goto('file://' + prepareEngine());
    await p.waitForTimeout(2500);
    await p.evaluate(([kit, idea]) => {
      goTo('build');
      if (kit && KITS[kit]) pickKit(document.querySelector('[data-kit=' + kit + ']'));
      if (idea) { const t = document.getElementById('adesc'); t.value = idea; t.dispatchEvent(new Event('input')); }
      buildApp();
    }, [kit || '', idea || '']);

    const t0 = Date.now(), MAX = (o.maxMin || 110) * 60000;
    let shown = {}, approved = false, resumes = 0, st;
    while (Date.now() - t0 < MAX) {
      await p.waitForTimeout(3000);
      st = await p.evaluate(() => {
        if (typeof RQ !== 'undefined' && RQ && RQ.data && document.getElementById('req-modal').classList.contains('on')) { rqStart(); return { rq: 1 }; }
        const a = S.apps[0]; if (!a) return { none: 1 };
        return { status: a.status, err: a.error || '', id: a.id, steps: (a.steps || []).map((s) => ({ s: s.state || '-', l: s.label })) };
      });
      if (st.rq || st.none) continue;
      for (const s of st.steps) {
        const k = s.l + '|' + s.s;
        if (shown[k]) continue; shown[k] = 1;
        if (s.s === 'done') log('  ✓ ' + s.l); else if (s.s === 'cur') log('  … ' + s.l); else if (s.s === 'err') log('  ✗ ' + s.l);
      }
      if (st.status === 'review' && !approved) {
        const bp = await p.evaluate(() => {
          const pl = S.apps[0].ck.plan;
          return { name: pl.name, summary: pl.summary || '', roles: (pl.roles || []).map((r) => r.name), screens: pl.screens.map((s) => s.title), cols: (pl.collections || []).map((c) => c.name),
            pay: !!(document.getElementById('bp-bk') || document.getElementById('bp-bn')) };
        });
        log('\n📐 المخطط: ' + bp.name + (bp.summary ? ' — ' + bp.summary : ''));
        if (bp.roles.length) log('   الأدوار: ' + bp.roles.join('، '));
        log('   الشاشات (' + bp.screens.length + '): ' + bp.screens.join('، '));
        if (bp.cols.length) log('   البيانات: ' + bp.cols.join('، '));
        const pay = {};
        if (bp.pay) {
          log('   يحتاج التطبيق بيانات الدفع (بنكك):');
          pay.bk = o.yes ? '' : await ask('   رقم حساب بنكك (Enter للتخطي): ');
          pay.bn = o.yes ? '' : await ask('   اسم صاحب الحساب: ');
        }
        if (!o.yes) {
          const a = (await ask('\nأوافق على المخطط وأكمل البناء؟ (y/n) ')).toLowerCase();
          if (a !== 'y') { log('أُلغي البناء.'); return null; }
        }
        await p.evaluate(([bk, bn, id]) => {
          const ek = document.getElementById('bp-bk'), en = document.getElementById('bp-bn');
          if (ek && !ek.value) ek.value = bk || '0000000'; if (en && !en.value) en.value = bn || 'صاحب المتجر';
          approvePlan(id);
        }, [pay.bk || '', pay.bn || '', st.id]);
        approved = true; log('\n🔨 يبني الشاشات ويفحصها...');
      }
      if (st.status === 'failed' && resumes < 3) {
        resumes++; log('⏸️  توقف: ' + st.err + ' — أتابع من حيث توقف بعد دقيقة (' + resumes + '/3)');
        await p.waitForTimeout(60000); await p.evaluate((id) => retryApp(id), st.id); continue;
      }
      if (st.status === 'ready' || st.status === 'failed') break;
    }
    if (!st || st.status !== 'ready') throw new Error('لم يكتمل البناء: ' + ((st && st.err) || 'انتهى الوقت'));

    // ── التصدير: نفس ملفات زر «مشروع أندرويد» في بانِي ──
    const files = await p.evaluate(async (o) => {
      const app = S.apps[0];
      const name = o.name || app.name;
      const slug = slugify(o.slug || latinize(name));
      const cfg = { appName: name, appId: o.appId || ('com.banee.' + slug.replace(/-/g, '_').replace(/^(\d)/, 'a$1')), slug, version: '1.0',
        admobAppId: o.admob || 'ca-app-pub-3940256099942544~3347511713' };
      app.android = cfg; app.cloudOff = true;
      const fs = androidFiles(app, cfg);
      fs.forEach((x) => { if (x.path === 'www/index.html') x.data = appCode(app, false); });
      const img = await Promise.all([canvasBytes(drawIcon(app, 1024)), canvasBytes(drawIcon(app, 1024, 'fg')), canvasBytes(drawIcon(app, 1024, 'bg')),
        canvasBytes(drawSplash(app, 2732)), canvasBytes(drawSplash(app, 2732, true))]);
      ['icon-only', 'icon-foreground', 'icon-background', 'splash', 'splash-dark'].forEach((n, i) => fs.push({ path: 'assets/' + n + '.png', data: img[i] }));
      const b64 = (u) => { let s = ''; for (let i = 0; i < u.length; i += 0x8000) s += String.fromCharCode.apply(null, u.subarray(i, i + 0x8000)); return btoa(s); };
      return { cfg, files: fs.map((x) => typeof x.data === 'string' ? { path: x.path, text: x.data } : { path: x.path, b64: b64(new Uint8Array(x.data)) }) };
    }, { name: o.name, appId: o.appId, admob: o.admob, slug: o.slug });

    const dir = path.resolve(out || files.cfg.slug);
    if (fs.existsSync(dir) && fs.readdirSync(dir).length) throw new Error('المجلد غير فارغ: ' + dir);
    for (const f of files.files) {
      const fp = path.join(dir, f.path);
      if (!fp.startsWith(dir)) continue;
      fs.mkdirSync(path.dirname(fp), { recursive: true });
      fs.writeFileSync(fp, f.text !== undefined ? f.text : Buffer.from(f.b64, 'base64'));
    }
    return { dir, cfg: files.cfg, count: files.files.length, minutes: ((Date.now() - t0) / 60000).toFixed(1) };
  } finally { await b.close(); }
}

module.exports = { build, enginePath };
