/**
 * بانِي — خادم Gemini على Google Apps Script
 * ------------------------------------------------------------
 * - مفتاح Gemini محفوظ هنا فقط (Script Properties ← GEMINI_KEY)، ولا يصل للتطبيق أبداً.
 * - يقبل فقط مستخدمي بانِي المسجّلين في Firebase.
 * - يتحقق من اشتراك Google Play مباشرة من Google (Play Developer API).
 * - يخصم الرصيد حسب الرموز المستهلكة فعلاً، ويوقف تلقائياً من يتجاوز حدود الغش.
 * - يوقف كل الطلبات إذا تجاوز إنفاق اليوم الحد الذي تحدده.
 */

// ═════════════ الإعدادات ═════════════
var CFG = {
  PROJECT_ID: 'bani-b28a0',
  FIREBASE_API_KEY: 'AIzaSyADAJ2MGzx58Bh-8gudT_JUBmBExYLrn6Q', // مفتاح Firebase العام (ليس سراً)
  PACKAGE_NAME: 'com.alloush.banee',
  POINT_USD: 0.00075,            // قيمة النقطة الواحدة بالدولار
  DAILY_CAP_USD: 5,              // أقصى إنفاق يومي لكل المستخدمين معاً
  MAX_OUTPUT_TOKENS: 12000,      // حتى لا يتجاوز الطلب حد الـ 60 ثانية
  ABUSE: { perMinute: 40, perHour: 300, monthPoints: 66000 }, // لا يصلها أي مستخدم حقيقي
  FREE_MODEL: 'gemini-3.5-flash-lite'
};

// الرصيد الشهري لكل خطة (نقاط). المجانية رصيد مرة واحدة.
var PLANS = {
  free:     { points: 600,   product: null },
  starter:  { points: 4000,  product: 'banee_starter' },
  pro:      { points: 8500,  product: 'banee_pro' },
  business: { points: 22000, product: 'banee_business' }
};
// حزم الرصيد الإضافي (منتجات Google Play استهلاكية)
var PACKS = { banee_credits_small: 1360, banee_credits_large: 4000 };

// أسعار Gemini بالدولار لكل مليون رمز. عدّلها إذا غيّرت Google الأسعار، والخطط تبقى رابحة تلقائياً.
var PRICES = {
  'gemini-3.8-flash':         { in: 0.75, out: 3.75 },
  'gemini-3.7-flash':         { in: 0.75, out: 3.75 },
  'gemini-3.6-flash':         { in: 0.75, out: 3.75 },
  'gemini-3.5-flash':         { in: 1.50, out: 9.00 },
  'gemini-3.5-flash-lite':    { in: 0.30, out: 2.50 },
  'gemini-3.1-flash-lite':    { in: 0.25, out: 1.50 },
  'gemini-flash-latest':      { in: 1.50, out: 9.00 },   // نفترض الأغلى احتياطاً
  'gemini-flash-lite-latest': { in: 0.30, out: 2.50 },
  'gemini-2.5-flash':         { in: 0.30, out: 2.50 },
  'gemini-2.5-flash-lite':    { in: 0.10, out: 0.40 }
};

// ═════════════ نقطة الدخول ═════════════
function doPost(e) {
  var t0 = Date.now();
  try {
    var req = JSON.parse((e && e.postData && e.postData.contents) || '{}');
    var user = verifyUser(req.idToken);
    if (!user) return out({ ok: false, error: { code: 'auth', message: 'سجّل دخولك مرة أخرى' } });
    user.planToken = typeof req.planToken === 'string' ? req.planToken.slice(0, 400) : '';

    if (req.refresh && user.planToken) CacheService.getScriptCache().remove('plan:' + user.uid + ':' + hash(user.planToken).slice(0, 12)); // بعد شراء أو تجديد
    if (req.op === 'balance') return out({ ok: true, credits: creditsView(user, loadState(user)) });
    if (req.op === 'topup') return out(topup(user, req));
    if (req.op === 'ask') return out(askGemini(user, req, t0));
    return out({ ok: false, error: { code: 'bad_request', message: 'طلب غير معروف' } });
  } catch (err) {
    console.error(err);
    return out({ ok: false, error: { code: 'server', message: 'خطأ في الخادم، حاول مرة أخرى' } });
  }
}
function doGet() { return out({ ok: true, service: 'banee', time: new Date().toISOString() }); }
function out(obj) { return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON); }
function prop(k) { return PropertiesService.getScriptProperties().getProperty(k); }

// ═════════════ التحقق من المستخدم (Firebase) ═════════════
function verifyUser(idToken) {
  if (!idToken || idToken.length < 100) return null;
  var cache = CacheService.getScriptCache(), ck = 'tok:' + hash(idToken);
  var hit = cache.get(ck); if (hit) return JSON.parse(hit);
  var r = UrlFetchApp.fetch('https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=' + CFG.FIREBASE_API_KEY, {
    method: 'post', contentType: 'application/json', payload: JSON.stringify({ idToken: idToken }), muteHttpExceptions: true
  });
  if (r.getResponseCode() !== 200) return null;
  var u = (JSON.parse(r.getContentText()).users || [])[0];
  if (!u || !u.localId) return null;
  var user = { uid: u.localId, email: u.email || '' };
  cache.put(ck, JSON.stringify(user), 600);
  return user;
}

// ═════════════ الخطة: من Google Play مباشرة ═════════════
function userPlan(user, token) {
  var cache = CacheService.getScriptCache(), ck = 'plan:' + user.uid + ':' + (token ? hash(token).slice(0, 12) : '-');
  var hit = cache.get(ck); if (hit) return JSON.parse(hit);
  var plan = { name: 'free', period: 'free' };
  try {
    // رمز الاشتراك يرسله التطبيق، ونتحقق منه هنا مباشرة مع Google Play: لا يمكن تزويره
    if (token) {
      var owner = prop('tokOwner:' + hash(token));
      if (!owner || owner === user.uid) {
        var sub = playGet('purchases/subscriptionsv2/tokens/' + encodeURIComponent(token));
        var active = sub && /SUBSCRIPTION_STATE_(ACTIVE|IN_GRACE_PERIOD)/.test(sub.subscriptionState || '');
        var acct = sub && sub.externalAccountIdentifiers && sub.externalAccountIdentifiers.obfuscatedExternalAccountId;
        if (active && (!acct || acct === user.uid)) {
          var item = (sub.lineItems || [])[0] || {};
          var name = planByProduct(item.productId);
          if (name) {
            plan = { name: name, period: String(item.expiryTime || sub.latestOrderId || '') };
            if (!owner) PropertiesService.getScriptProperties().setProperty('tokOwner:' + hash(token), user.uid);
          }
        }
      }
    }
  } catch (err) { console.warn('plan check', err); }
  cache.put(ck, JSON.stringify(plan), 21600); // ٦ ساعات
  return plan;
}
function planByProduct(id) { for (var k in PLANS) if (PLANS[k].product === id) return k; return null; }
function playGet(path) {
  var r = UrlFetchApp.fetch('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/' + CFG.PACKAGE_NAME + '/' + path, {
    headers: { Authorization: 'Bearer ' + ScriptApp.getOAuthToken() }, muteHttpExceptions: true
  });
  if (r.getResponseCode() !== 200) { console.warn('play', r.getResponseCode(), r.getContentText().slice(0, 300)); return null; }
  return JSON.parse(r.getContentText());
}

// ═════════════ الرصيد ═════════════
function loadState(user) {
  var token = user.planToken || '';
  var raw = prop('u:' + user.uid);
  var s = raw ? JSON.parse(raw) : { used: 0, bonus: 0, period: '', total: 0, blocked: false, email: user.email };
  var plan = userPlan(user, token);
  if (s.period !== plan.period) { s.period = plan.period; s.used = 0; } // تجديد شهري = رصيد جديد
  s.plan = plan.name;
  return s;
}
function saveState(user, s) { PropertiesService.getScriptProperties().setProperty('u:' + user.uid, JSON.stringify(s)); }
function creditsView(user, s) {
  var allow = PLANS[s.plan].points;
  return { plan: s.plan, allowance: allow, used: Math.round(s.used), bonus: Math.round(s.bonus || 0), remaining: Math.max(0, Math.round(allow - s.used + (s.bonus || 0))), blocked: !!s.blocked };
}

// ═════════════ الطلب إلى Gemini ═════════════
function askGemini(user, req, t0) {
  var lock = LockService.getScriptLock(); lock.waitLock(10000);
  var s, now = new Date();
  try {
    s = loadState(user);
    if (s.blocked) return { ok: false, error: { code: 'blocked', message: 'أُوقف حسابك لاستخدام غير طبيعي. تواصل مع الدعم.' } };
    var day = Utilities.formatDate(now, 'UTC', 'yyyy-MM-dd');
    var spent = Number(prop('day:' + day) || 0);
    if (spent >= CFG.DAILY_CAP_USD) return { ok: false, error: { code: 'daily_cap', message: 'الخدمة مزدحمة اليوم، حاول غداً' } };
    var v = creditsView(user, s);
    if (v.remaining <= 0) return { ok: false, error: { code: 'no_credits', message: 'نفد رصيدك' }, credits: v };
    // حدود الغش: لا يصلها استخدام حقيقي
    var mk = Utilities.formatDate(now, 'UTC', 'yyyyMMddHHmm'), hk = mk.slice(0, 10);
    if (s.mk !== mk) { s.mk = mk; s.mc = 0; }
    if (s.hk !== hk) { s.hk = hk; s.hc = 0; }
    s.mc++; s.hc++;
    if (s.mc > CFG.ABUSE.perMinute || s.hc > CFG.ABUSE.perHour || s.used > CFG.ABUSE.monthPoints) {
      s.blocked = true; s.blockedAt = now.toISOString(); s.blockReason = 'min=' + s.mc + ' hour=' + s.hc + ' used=' + Math.round(s.used);
      saveState(user, s); logRow(user, 'BLOCKED', s.blockReason, 0, 0, 0);
      return { ok: false, error: { code: 'blocked', message: 'أُوقف حسابك لاستخدام غير طبيعي. تواصل مع الدعم.' } };
    }
    saveState(user, s);
  } finally { lock.releaseLock(); }

  // الموديل: المجانية على موديل اقتصادي، والباقي من القائمة المسموحة فقط
  var model = s.plan === 'free' ? CFG.FREE_MODEL : (PRICES[req.model] ? req.model : 'gemini-3.7-flash');
  var gc = req.generationConfig || {};
  gc.maxOutputTokens = Math.min(Number(gc.maxOutputTokens) || CFG.MAX_OUTPUT_TOKENS, CFG.MAX_OUTPUT_TOKENS);
  var body = { contents: req.contents, generationConfig: gc };
  if (req.systemInstruction) body.systemInstruction = req.systemInstruction;

  var r;
  try {
    r = UrlFetchApp.fetch('https://generativelanguage.googleapis.com/v1beta/models/' + model + ':generateContent', {
      method: 'post', contentType: 'application/json', payload: JSON.stringify(body), muteHttpExceptions: true,
      headers: { 'x-goog-api-key': prop('GEMINI_KEY') }
    });
  } catch (err) {
    return { ok: false, error: { code: 'timeout', message: 'استغرق الطلب وقتاً طويلاً، سنعيد المحاولة' } };
  }
  var code = r.getResponseCode(), data;
  try { data = JSON.parse(r.getContentText()); } catch (e2) { data = {}; }
  if (code !== 200) {
    var busy = code === 429 || code === 503 || code === 500 || code === 404;
    return { ok: false, error: { code: busy ? 'busy' : 'gemini', status: code, message: (data.error && data.error.message) || 'خطأ من Gemini' }, model: model };
  }

  // الخصم حسب الاستهلاك الفعلي (رموز التفكير تُحسب كمخرجات)
  var u = data.usageMetadata || {}, p = PRICES[model];
  var inT = u.promptTokenCount || 0, outT = (u.candidatesTokenCount || 0) + (u.thoughtsTokenCount || 0);
  var usd = (inT * p.in + outT * p.out) / 1e6, pts = usd / CFG.POINT_USD;
  var lock2 = LockService.getScriptLock(); lock2.waitLock(10000);
  try {
    var s2 = loadState(user);
    var fromPlan = Math.min(pts, Math.max(0, PLANS[s2.plan].points - s2.used));
    s2.used += pts; if (pts > fromPlan) { s2.bonus = Math.max(0, (s2.bonus || 0) - (pts - fromPlan)); s2.used -= (pts - fromPlan); }
    s2.total = (s2.total || 0) + 1; s2.email = user.email; s2.last = new Date().toISOString();
    saveState(user, s2);
    var dk = 'day:' + Utilities.formatDate(new Date(), 'UTC', 'yyyy-MM-dd');
    PropertiesService.getScriptProperties().setProperty(dk, String(Number(prop(dk) || 0) + usd));
    s = s2;
  } finally { lock2.releaseLock(); }
  logRow(user, model, req.role || '', inT, outT, usd);
  return { ok: true, data: data, model: model, cost: { points: Math.round(pts), ms: Date.now() - t0 }, credits: creditsView(user, s) };
}

// ═════════════ شراء رصيد إضافي ═════════════
function topup(user, req) {
  var pts = PACKS[req.productId];
  if (!pts || !req.purchaseToken) return { ok: false, error: { code: 'bad_request', message: 'حزمة غير معروفة' } };
  var key = 'pack:' + hash(req.purchaseToken);
  if (prop(key)) return { ok: true, already: true, credits: creditsView(user, loadState(user)) };
  var p = playGet('purchases/products/' + req.productId + '/tokens/' + encodeURIComponent(req.purchaseToken));
  if (!p || p.purchaseState !== 0) return { ok: false, error: { code: 'not_paid', message: 'لم نتمكن من تأكيد الدفع من Google Play' } };
  if (p.obfuscatedExternalAccountId && p.obfuscatedExternalAccountId !== user.uid) return { ok: false, error: { code: 'not_paid', message: 'هذا الشراء مرتبط بحساب آخر' } };
  var lock = LockService.getScriptLock(); lock.waitLock(10000);
  try {
    if (prop(key)) return { ok: true, already: true, credits: creditsView(user, loadState(user)) };
    var s = loadState(user); s.bonus = (s.bonus || 0) + pts; saveState(user, s);
    PropertiesService.getScriptProperties().setProperty(key, user.uid);
    logRow(user, 'TOPUP', req.productId, 0, 0, 0);
    return { ok: true, added: pts, credits: creditsView(user, s) };
  } finally { lock.releaseLock(); }
}

// ═════════════ السجل والتقارير (Google Sheets) ═════════════
function sheet(name) {
  var id = prop('SHEET_ID'), ss;
  if (id) ss = SpreadsheetApp.openById(id);
  else { ss = SpreadsheetApp.create('بانِي — الاستهلاك'); PropertiesService.getScriptProperties().setProperty('SHEET_ID', ss.getId()); }
  var sh = ss.getSheetByName(name);
  if (!sh) {
    sh = ss.insertSheet(name);
    if (name === 'log') sh.appendRow(['الوقت', 'uid', 'البريد', 'الموديل/الحدث', 'الدور', 'رموز داخلة', 'رموز خارجة', 'التكلفة $']);
  }
  return sh;
}
function logRow(user, model, role, inT, outT, usd) {
  try { sheet('log').appendRow([new Date(), user.uid, user.email, model, role, inT, outT, Math.round(usd * 1e5) / 1e5]); } catch (e) { console.warn('log', e); }
}
// شغّلها يدوياً أو كل ساعة: ملخص المستخدمين والإنفاق
function report() {
  var all = PropertiesService.getScriptProperties().getProperties(), rows = [];
  Object.keys(all).forEach(function(k){
    if (k.indexOf('u:') !== 0) return;
    var s = JSON.parse(all[k]);
    rows.push([k.slice(2), s.email || '', s.plan || '', Math.round(s.used || 0), Math.round(s.bonus || 0), s.total || 0, s.blocked ? 'موقوف: ' + (s.blockReason || '') : '', s.last || '']);
  });
  var sh = sheet('users'); sh.clear();
  sh.appendRow(['uid', 'البريد', 'الخطة', 'نقاط هذا الشهر', 'رصيد إضافي', 'عدد الطلبات', 'الحالة', 'آخر استخدام']);
  if (rows.length) sh.getRange(2, 1, rows.length, rows[0].length).setValues(rows);
  var days = Object.keys(all).filter(function(k){ return k.indexOf('day:') === 0; }).sort().slice(-31);
  var d = sheet('daily'); d.clear(); d.appendRow(['اليوم', 'الإنفاق $']);
  days.forEach(function(k){ d.appendRow([k.slice(4), Math.round(Number(all[k]) * 100) / 100]); });
}

// ═════════════ أدوات الإدارة (شغّلها من المحرر) ═════════════
function setup() {
  sheet('log'); report();
  ScriptApp.getProjectTriggers().forEach(function(t){ if (t.getHandlerFunction() === 'report') ScriptApp.deleteTrigger(t); });
  ScriptApp.newTrigger('report').timeBased().everyHours(1).create();
  Logger.log('جاهز. جدول المتابعة: ' + SpreadsheetApp.openById(prop('SHEET_ID')).getUrl());
}
function unblock(uid) {
  var raw = prop('u:' + uid); if (!raw) return Logger.log('غير موجود');
  var s = JSON.parse(raw); s.blocked = false; s.mc = 0; s.hc = 0; delete s.blockReason;
  PropertiesService.getScriptProperties().setProperty('u:' + uid, JSON.stringify(s)); Logger.log('أُلغي الإيقاف');
}
function giveCredits(uid, points) {
  var raw = prop('u:' + uid); var s = raw ? JSON.parse(raw) : { used: 0, bonus: 0, period: '', total: 0 };
  s.bonus = (s.bonus || 0) + points; PropertiesService.getScriptProperties().setProperty('u:' + uid, JSON.stringify(s)); Logger.log('الرصيد الإضافي: ' + s.bonus);
}
function testGemini() {
  var r = UrlFetchApp.fetch('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.7-flash:generateContent', {
    method: 'post', contentType: 'application/json', muteHttpExceptions: true, headers: { 'x-goog-api-key': prop('GEMINI_KEY') },
    payload: JSON.stringify({ contents: [{ role: 'user', parts: [{ text: 'قل مرحبا' }] }] })
  });
  Logger.log(r.getResponseCode() + ' ' + r.getContentText().slice(0, 300));
}

function hash(s) {
  return Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, s).map(function(b){ return ('0' + (b & 255).toString(16)).slice(-2); }).join('').slice(0, 32);
}
