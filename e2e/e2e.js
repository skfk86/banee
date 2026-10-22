// اختبار حقيقي كامل: يفتح بانِي، يبني نظاماً كاملاً بمفتاح Gemini حقيقي، ثم يصوّر كل شاشة ويكتب تقريراً
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const KEYS = [process.env.GEMINI_KEY, process.env.GEMINI_KEY2, process.env.GEMINI_KEY3, process.env.GEMINI_KEY4, process.env.GEMINI_KEY5].filter(Boolean), KEY = KEYS.length ? KEYS[(+process.env.KEY_IDX || 0) % KEYS.length] : '', IDEA = process.env.IDEA || '', KIT = process.env.KIT || (process.env.IDEA ? '' : 'delivery');
const SRC = process.env.SRC || 'e2e.html', OUT = process.env.OUT || 'e2e-out', MAX_MIN = +(process.env.MAX_MIN || 110);
fs.mkdirSync(OUT, { recursive: true });
const log = (...a) => { const s = '[' + new Date().toISOString().slice(11, 19) + '] ' + a.join(' '); console.log(s); fs.appendFileSync(path.join(OUT, 'log.txt'), s + '\n'); };
(async () => {
  if (!KEY && !process.env.FAKE) { console.error('GEMINI_KEY مفقود'); process.exit(1); }
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 390, height: 844 } });
  if (process.env.FAKE) await require(path.resolve(process.env.FAKE))(ctx);
  await ctx.route(/gstatic\.com\/firebasejs/, r => r.abort()); // وضع محلي: بلا تسجيل دخول Firebase
  await ctx.addInitScript(([k, spec]) => {
    if (sessionStorage.getItem('e2e')) return; sessionStorage.setItem('e2e', '1');
    localStorage.setItem('buser', JSON.stringify({ uid: 'e2e', name: 'علوش', email: 'e2e@banee.app' }));
    localStorage.setItem('bprofile', JSON.stringify({ plan: 'business', name: 'علوش' }));
    localStorage.setItem('bgkey', k); localStorage.setItem('bonb', '1');
    if (spec) localStorage.setItem('bspec', '1');
  }, [KEY || 'FAKE', !!process.env.SPEC]);
  const p = await ctx.newPage(); const perr = [];
  p.on('console', m => { if (/^AGENT/.test(m.text())) log(m.text()); }); p.on('pageerror', e => perr.push(e.message + ' @ ' + String(e.stack || '').split('\n').slice(1, 3).join(' | ').slice(0, 300)));
  let lastToast = ''; setInterval(async () => { try { const tx = await p.evaluate(() => { const t = document.querySelector('.toast.on, #toast.on, .toast'); return t ? t.textContent.trim() : ''; }); if (tx && tx !== lastToast) { lastToast = tx; log('رسالة:', tx); } } catch (e) {} }, 1500);
  p.on('response', async r => { const u = r.url(); if (/generativelanguage/.test(u) && r.status() !== 200) { let body = ''; try { body = (await r.text()).slice(0, 1500); } catch (e) {} log('Gemini', r.status(), (u.match(/models\/([^:?]+)/) || [])[1] || '', body.replace(/\s+/g, ' ')); } });
  p.on('requestfailed', r => { if (/generativelanguage/.test(r.url())) log('Gemini طلب فشل:', (r.url().match(/models\/([^:?]+)/) || [])[1] || '', r.failure() && r.failure().errorText); });
  await p.goto('file://' + path.resolve(SRC)); await p.waitForTimeout(2500);
  await p.evaluate(([kit, idea]) => {
    goTo('build');
    if (kit && KITS[kit]) pickKit(document.querySelector('[data-kit=' + kit + ']'));
    if (idea) { const t = document.getElementById('adesc'); t.value = idea; t.dispatchEvent(new Event('input')); }
    buildApp();
  }, [KIT, IDEA]);
  log('بدأ البناء:', await p.evaluate(() => document.getElementById('adesc').value || (S.apps[0] && S.apps[0].desc) || ''));
  const t0 = Date.now(); let last = '', approved = false, approvedAt = 0, resumes = 0;
  while (Date.now() - t0 < MAX_MIN * 60000) {
    await p.waitForTimeout(4000);
    const st = await p.evaluate(() => {
      if (typeof RQ !== 'undefined' && RQ && RQ.data && document.getElementById('req-modal').classList.contains('on')) { rqStart(); return { rq: 1 }; }
      const a = S.apps[0]; if (!a) return { none: 1 };
      return { status: a.status, err: a.error || '', steps: (a.steps || []).map(s => (s.state || '-') + ':' + s.label).join(' | '), id: a.id };
    });
    if (st.rq) { log('أُجيب على أسئلة المحلل تلقائياً'); continue; }
    if (st.none) continue;
    const line = st.status + ' ' + st.steps;
    if (line !== last) { log(line); last = line; }
    if (st.status === 'review' && approved && !approved.warned && Date.now() - approvedAt > 180000) { approved = { warned: 1 }; log('⚠️ ما زال بانتظار المراجعة بعد الموافقة بـ٣ دقائق'); }
    if (st.status === 'review' && !approved) {
      const bp = await p.evaluate(() => { const pl = S.apps[0].ck.plan; return { name: pl.name, roles: (pl.roles || []).map(r => r.name + (r.approve ? '*' : '')), screens: pl.screens.map(s => s.title + ' ' + s.route + (s.roles ? ' [' + s.roles.join(',') + ']' : '')), cols: (pl.collections || []).map(c => c.name), flows: (pl.flows || []).map(f => f.name) }; });
      fs.writeFileSync(path.join(OUT, 'blueprint.json'), JSON.stringify(bp, null, 2));
      log('المخطط:', JSON.stringify(bp));
      await p.screenshot({ path: path.join(OUT, '00-blueprint.png'), fullPage: true });
      await p.evaluate(() => { const bk = document.getElementById('bp-bk'), bn = document.getElementById('bp-bn'); if (bk && !bk.value) bk.value = '1234567'; if (bn && !bn.value) bn.value = 'متجر تجريبي'; });
      approved = true; approvedAt = Date.now(); await p.evaluate(id => approvePlan(id), st.id); log('وافقت على المخطط (وعبّأت بيانات الدفع إن طُلبت)');
    }
    if (st.status === 'failed' && resumes < 3) { resumes++; log('توقف البناء:', st.err, '← ضغطت «متابعة من حيث توقف» (' + resumes + ')'); await p.waitForTimeout(60000); await p.evaluate(id => retryApp(id), st.id); continue; }
    if (st.status === 'ready' || st.status === 'failed') break;
  }
  const rep = await p.evaluate(() => { const a = S.apps[0], ck = a.ck || {}; return { status: a.status, error: a.error || '', name: a.name, steps: a.steps.map(s => s.state + ' · ' + s.label),
    runtime: ck.runtime || {}, flows: (ck.flowTests || []).map(f => f.flow + ' (' + f.steps.length + ' خطوات)'), flowSteps: ck.flowTests || [], reviewIssues: ck.reviewIssues || null, spec: !!ck.spec, specFallback: ck.specFallback || [], flowErr: ck.flowErr || '', agent: { ran: !!ck.agentRan, fixed: ck.agentFixed || 0, steps: ck.agentSteps || 0, log: ck.agentLog || [] }, fixErrors: ck.fixErrors || [], review: { found: ck.reviewCount || 0, fixed: ck.reviewFixed || 0 }, screens: (ck.plan ? ck.plan.screens : []).map(s => ({ id: s.id, route: s.route, roles: s.roles || [], bytes: (ck.screens[s.id] || '').length })) }; });
  // مثال للتعلم: المخطط ومواصفات الشاشات (يختار منها tools/learn.js ما نجح كاملاً)
  try {
    const ex = await p.evaluate(() => { const a = S.apps[0], ck = a.ck || {}, pl = ck.plan; if (!pl) return null;
      const specs = (pl.screens || []).map(s => { const sp = specOf(ck.screens[s.id] || ''); return sp ? { id: s.id, title: s.title, purpose: s.purpose || '', roles: s.roles || [], blocks: sp.blocks } : null; }).filter(Boolean);
      return { idea: ck.req || a.desc || a.name, plan: { name: pl.name, summary: pl.summary, roles: pl.roles, collections: pl.collections, statuses: pl.statuses, visibility: pl.visibility, shared: pl.shared, flows: pl.flows, screens: (pl.screens || []).map(s => ({ id: s.id, route: s.route, title: s.title, nav: s.nav, roles: s.roles, purpose: s.purpose })) }, specs }; });
    if (ex) fs.writeFileSync(path.join(OUT, 'example.json'), JSON.stringify(ex));
  } catch (e) {}
  const mins = ((Date.now() - t0) / 60000).toFixed(1);
  fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(rep, null, 2));
  log('النتيجة:', rep.status, rep.error, '| الزمن:', mins, 'دقيقة');
  if (rep.status === 'ready') {
    const html = await p.evaluate(() => assemble(S.apps[0], {}));
    fs.writeFileSync(path.join(OUT, 'app.html'), html);
    const plan = await p.evaluate(() => ({ screens: S.apps[0].ck.plan.screens, roles: S.apps[0].ck.plan.roles || [], seed: mergedSeed(S.apps[0]), auth: S.apps[0].ck.plan.auth }));
    const ap = await ctx.newPage(); const aerr = [];
    ap.on('pageerror', e => aerr.push(e.message)); ap.on('console', m => { if (m.type() === 'error' && !/Failed to load resource/.test(m.text())) aerr.push(m.text()); });
    await ap.goto('file://' + path.resolve(OUT, 'app.html')); await ap.waitForTimeout(1500);
    if (plan.auth) {
      await ap.evaluate(() => { location.hash = '/register'; }); await ap.waitForTimeout(800);
      if (await ap.$('#f-name')) { await ap.fill('#f-name', 'سارة'); await ap.fill('#f-email', 'sara@test.sd'); await ap.fill('#f-pass', '123456'); await ap.click('[data-act=submit]'); await ap.waitForTimeout(1500); }
      const ro = await ap.$('.role-opt'); if (ro) { await ap.screenshot({ path: path.join(OUT, '01-roles.png') }); await ro.click(); await ap.waitForTimeout(1000); }
    }
    let n = 2;
    for (const s of plan.screens) {
      const sid = await p.evaluate(id => { const a = S.apps[0]; try { return seedIdFor({ seed: mergedSeed(a) }, a.ck.screens[id]); } catch (e) { return 's1'; } }, s.id);
      let route = s.route.replace(/:\w+/g, () => encodeURIComponent(sid || 's1'));
      await ap.evaluate(([r, role]) => { try { window.__banee.setRole(role); } catch (e) {} location.hash = r; }, [route, plan.roles.length > 1 && s.roles && s.roles.length ? s.roles[0] : null]);
      await ap.waitForTimeout(1800);
      await ap.screenshot({ path: path.join(OUT, String(n++).padStart(2, '0') + '-' + s.id + '.png'), fullPage: true });
    }
    fs.writeFileSync(path.join(OUT, 'app-errors.json'), JSON.stringify(aerr, null, 2));
    log('أخطاء أثناء تصفح التطبيق:', aerr.length);
    // حكم التصميم: لقطة كل شاشة تُقيَّم من ١٠ بمعايير التطبيقات العالمية (JUDGE=0 لتعطيله)
    if (KEY && process.env.JUDGE !== '0') {
      try {
        rep.design = await require('./design-judge.js')(OUT, [KEY].concat(KEYS.filter(k => k !== KEY)), process.env.JUDGE_MODEL || 'gemini-2.5-flash');
        fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(rep, null, 2));
        log('التصميم:', rep.design.score, '/ 10 (أضعف شاشة', rep.design.min + ')', JSON.stringify(Object.fromEntries(Object.entries(rep.design.screens).map(([k, v]) => [k, v.score]))));
      } catch (e) { log('تعذّر حكم التصميم:', e.message); }
    }
  }
  // اختبار الوكيل المستقل: نزرع خطأً حقيقياً بين شاشتين (اسم حقل مختلف عند الإنشاء) ونرى هل يتتبّعه ويصلحه
  if (process.env.SABOTAGE && rep.status === 'ready') {
    const sb = await p.evaluate(async () => {
      const a = S.apps[0], plan = a.ck.plan, scr = a.ck.screens; let done = null;
      const allKeys = {};
      for (const s of plan.screens) {
        const js = scr[s.id] || ''; const re = /(?:Data\.\w+\.create|DB\.add)\(/g; let mm;
        while (!done && (mm = re.exec(js))) {
          const win = js.slice(mm.index, mm.index + 900); const km = win.match(/\b([a-z]\w*Id)\s*:/g) || [];
          const k = km.map(x => x.replace(/\s*:$/, '')).find(k => k !== 'userId' && plan.screens.some(o => o.id !== s.id && (scr[o.id] || '').indexOf(k) > -1));
          if (!k) continue;
          const nw = win.replace(new RegExp('\\b' + k + '(\\s*):'), k + 'Ref$1:');
          scr[s.id] = js.slice(0, mm.index) + nw + js.slice(mm.index + 900); done = { screen: s.id, field: k };
        }
        if (done) break;
      }
      if (!done) return { skipped: 'لم أجد موضعاً مناسباً للزرع' };
      a.ck.agentRan = false;
      const res = await runtimeTest(a);
      const before = runtimeIssues(res);
      const r = await agentFix(a, localStorage.getItem('bgkey'), res, (k, x) => console.log('AGENT', k, JSON.stringify(x).slice(0, 300)));
      const fixedBack = (a.ck.screens[done.screen] || '').indexOf(done.field + 'Ref:') < 0;
      return { ...done, issuesBefore: before, issuesAfter: runtimeIssues(r.res), steps: r.steps, fixedField: fixedBack, log: (r.log || []).map(h => h.call + ' → ' + String(h.obs).slice(0, 200)) };
    });
    rep.sabotage = sb; fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(rep, null, 2));
    log('اختبار الوكيل:', JSON.stringify(sb).slice(0, 3000));
  }
  const md = ['# تقرير الاختبار الحقيقي لبانِي', '', '- التطبيق: **' + rep.name + '**', '- النتيجة: **' + rep.status + '** ' + rep.error, '- الزمن: ' + mins + ' دقيقة', '- رحلات مختبرة: ' + rep.flows.join('، '),
    '- المراجعة الشاملة: وُجدت ' + rep.review.found + ' وأُصلحت ' + rep.review.fixed, ...(rep.design ? ['- **التصميم: ' + rep.design.score + ' / 10** (أضعف شاشة ' + rep.design.min + ')', ...Object.entries(rep.design.screens).map(([k, v]) => '  - ' + k + ': ' + v.score + (v.issues[0] ? ' — ' + v.issues[0] : ''))] : []), '', '## المراحل', ...rep.steps.map(s => '- ' + s), '', '## ملاحظات التشغيل المتبقية',
    ...Object.entries(rep.runtime).filter(([k, v]) => v.length).map(([k, v]) => '- **' + k + '**: ' + v.join(' / ')), '', '## أخطاء صفحة بانِي', ...perr.slice(0, 20).map(e => '- ' + e)].join('\n');
  fs.writeFileSync(path.join(OUT, 'report.md'), md);
  if (process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, md + '\n');
  await b.close();
  process.exit(rep.status === 'ready' ? 0 : 1);
})().catch(e => { console.error(e); process.exit(1); });
