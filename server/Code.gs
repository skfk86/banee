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
  FREE_MODEL: 'gemini-3.5-flash-lite',
  // ── برنامج المؤسسين: أنت تتحمل تكلفة أول المستخدمين، بميزانية تحددها أنت ولا تتجاوزها أبداً ──
  FOUNDERS: 0,              // ضع رقماً (مثلاً 100) إذا أردت لاحقاً رصيداً مجانياً لأول المستخدمين
  FOUNDER_POINTS: 1500,     // رصيدهم المجاني (يكفي لبناء تطبيق كامل وتجربته)
  FREE_BUDGET_USD: 40,      // سقف أمان: أقصى ما تدفعه إجمالاً على التجارب المجانية (٣٠٠ نقطة ≈ ٠٫٢٢$ للشخص)
  FREE_DAILY_USD: 2,        // أقصى ما يُصرف يومياً على التجارب المجانية
  // ── قدرات التطبيقات المبنية ──
  NET_PER_HOUR: 120,        // طلبات البيانات الحية لكل مستخدم في الساعة
  APP_AI_PER_HOUR: 20,      // أسئلة الذكاء الاصطناعي لكل مستخدم في كل تطبيق في الساعة (تُخصم من رصيد صاحب التطبيق)
  APP_AI_MODEL: 'gemini-3.5-flash-lite',
  PUSH_PER_DAY: 10,         // إشعارات يرسلها صاحب التطبيق يومياً
  // ── إعلانات بانِي للمستخدمين غير المشتركين ──
  AD_POINTS: 5,             // نقاط كل إعلان بمكافأة (≈ قيمة الإعلان الفعلية، فلا خسارة). عدّلها بعد معرفة دخلك من AdMob
  AD_PER_DAY: 10,           // أقصى إعلانات بمكافأة لكل حساب يومياً
  AD_MIN_GAP_MS: 20000      // أقل مدة بين مكافأتين (طول الإعلان)
};

// الرصيد الشهري لكل خطة (نقاط). المجانية رصيد مرة واحدة.
var PLANS = {
  free:     { points: 300,   product: null },   // تجربة مجانية مرة واحدة لكل حساب
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
    if (req.op === 'adReward') return out(adReward(user));
    // ── قدرات التطبيقات المبنية ببانِي (يستدعيها مستخدمو تلك التطبيقات) ──
    if (req.op === 'fetch') return out(netFetch(user, req));
    if (req.op === 'appAsk') return out(appAsk(user, req, t0));
    if (req.op === 'push') return out(pushSend(user, req));
    if (req.op === 'fcmApp') return out(fcmApp(user, req));
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
  var s = raw ? JSON.parse(raw) : null;
  if (!s) {
    var n = Number(prop('usersCount') || 0) + 1;
    PropertiesService.getScriptProperties().setProperty('usersCount', String(n));
    s = { used: 0, bonus: 0, period: '', total: 0, blocked: false, email: user.email, no: n, founder: n <= CFG.FOUNDERS, joined: new Date().toISOString() };
    PropertiesService.getScriptProperties().setProperty('u:' + user.uid, JSON.stringify(s));
  }
  var plan = userPlan(user, token);
  if (s.period !== plan.period) { s.period = plan.period; s.used = 0; } // تجديد شهري = رصيد جديد
  s.plan = plan.name;
  return s;
}
function saveState(user, s) { PropertiesService.getScriptProperties().setProperty('u:' + user.uid, JSON.stringify(s)); }
function planPoints(s) { return s.plan === 'free' && s.founder ? CFG.FOUNDER_POINTS : PLANS[s.plan].points; }
function creditsView(user, s) {
  var allow = planPoints(s);
  var today = Utilities.formatDate(new Date(), 'UTC', 'yyyy-MM-dd');
  return { adsLeft: s.plan === 'free' ? Math.max(0, CFG.AD_PER_DAY - (s.adDay === today ? s.adN || 0 : 0)) : 0, adPoints: CFG.AD_POINTS, plan: s.plan, founder: !!s.founder, no: s.no || 0, allowance: allow, used: Math.round(s.used), bonus: Math.round(s.bonus || 0), remaining: Math.max(0, Math.round(allow - s.used + (s.bonus || 0))), blocked: !!s.blocked };
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
    // المجانيون (الذين لا رصيد إضافي مدفوع لهم) يُصرف عليهم من ميزانيتك المحددة فقط
    if (s.plan === 'free' && !(s.bonus > 0)) {
      if (Number(prop('free:total') || 0) >= CFG.FREE_BUDGET_USD) return { ok: false, error: { code: 'free_ended', message: 'انتهت المقاعد المجانية. اشترك لتكمل البناء من حيث توقف.' }, credits: v };
      if (Number(prop('freeday:' + day) || 0) >= CFG.FREE_DAILY_USD) return { ok: false, error: { code: 'free_day', message: 'انتهت حصة اليوم المجانية. عُد غداً لتكمل من حيث توقفت، أو اشترك لتكمل الآن.' }, credits: v };
    }
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
  var model = s.plan === 'free' && !(s.bonus > 0) ? CFG.FREE_MODEL : (PRICES[req.model] ? req.model : 'gemini-3.7-flash');
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
    var fromPlan = Math.min(pts, Math.max(0, planPoints(s2) - s2.used));
    s2.used += pts; if (pts > fromPlan) { s2.bonus = Math.max(0, (s2.bonus || 0) - (pts - fromPlan)); s2.used -= (pts - fromPlan); }
    s2.total = (s2.total || 0) + 1; s2.email = user.email; s2.last = new Date().toISOString();
    saveState(user, s2);
    var today = Utilities.formatDate(new Date(), 'UTC', 'yyyy-MM-dd'), dk = 'day:' + today;
    PropertiesService.getScriptProperties().setProperty(dk, String(Number(prop(dk) || 0) + usd));
    if (s2.plan === 'free' && fromPlan > 0) {
      var freeUsd = usd * fromPlan / pts;
      PropertiesService.getScriptProperties().setProperty('free:total', String(Number(prop('free:total') || 0) + freeUsd));
      PropertiesService.getScriptProperties().setProperty('freeday:' + today, String(Number(prop('freeday:' + today) || 0) + freeUsd));
    }
    s = s2;
  } finally { lock2.releaseLock(); }
  logRow(user, model, req.role || '', inT, outT, usd);
  return { ok: true, data: data, model: model, cost: { points: Math.round(pts), ms: Date.now() - t0 }, credits: creditsView(user, s) };
}

// ═════════════ قدرات التطبيقات المبنية ═════════════
function hit(key, limit, ttl) {
  var c = CacheService.getScriptCache(), n = Number(c.get(key) || 0) + 1;
  c.put(key, String(n), ttl); return n <= limit;
}
function fsDoc(path, idToken) {
  var r = UrlFetchApp.fetch('https://firestore.googleapis.com/v1/projects/' + CFG.PROJECT_ID + '/databases/(default)/documents/' + path + (idToken ? '' : '?key=' + CFG.FIREBASE_API_KEY), {
    headers: idToken ? { Authorization: 'Bearer ' + idToken } : {}, muteHttpExceptions: true
  });
  if (r.getResponseCode() !== 200) return null;
  return JSON.parse(r.getContentText());
}
function fsVal(v) {
  if (!v) return null;
  if ('stringValue' in v) return v.stringValue; if ('integerValue' in v) return Number(v.integerValue); if ('doubleValue' in v) return v.doubleValue;
  if ('booleanValue' in v) return v.booleanValue; if ('mapValue' in v) { var o = {}, f = v.mapValue.fields || {}; for (var k in f) o[k] = fsVal(f[k]); return o; }
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(fsVal); return null;
}
function appMeta(appId) {
  if (!/^[\w-]{3,80}$/.test(appId || '')) return null;
  var c = CacheService.getScriptCache(), k = 'appm:' + appId, hitv = c.get(k);
  if (hitv) return JSON.parse(hitv);
  var d = fsDoc('apps/' + appId); if (!d || !d.fields) return null;
  var m = { owner: fsVal(d.fields.owner), name: fsVal(d.fields.name) };
  c.put(k, JSON.stringify(m), 600); return m;
}

// ١) بيانات حية من الإنترنت عبر الخادم (يتجاوز قيود CORS في الجوال)
function netFetch(user, req) {
  var url = String(req.url || '');
  if (!/^https:\/\/[^\s/$.?#].[^\s]*$/i.test(url) || /(localhost|127\.|10\.|192\.168\.|169\.254\.|metadata\.google)/i.test(url)) return { ok: false, error: { code: 'bad_url', message: 'رابط غير مسموح' } };
  if (!hit('net:' + user.uid + ':' + Utilities.formatDate(new Date(), 'UTC', 'yyyyMMddHH'), CFG.NET_PER_HOUR, 3700)) return { ok: false, error: { code: 'rate', message: 'طلبات كثيرة، حاول بعد قليل' } };
  var c = CacheService.getScriptCache(), ck = 'net:' + hash(url), cached = c.get(ck);
  if (cached) return JSON.parse(cached);
  var r;
  try { r = UrlFetchApp.fetch(url, { muteHttpExceptions: true, followRedirects: true, headers: { 'User-Agent': 'Banee/1.0', Accept: 'application/json, text/plain, */*' } }); }
  catch (e) { return { ok: false, error: { code: 'net', message: 'تعذّر الوصول للمصدر' } }; }
  var body = r.getContentText(), type = String((r.getHeaders() || {})['Content-Type'] || (r.getHeaders() || {})['content-type'] || '');
  if (body.length > 300000) body = body.slice(0, 300000);
  var res = { ok: r.getResponseCode() < 400, status: r.getResponseCode(), type: type, body: body };
  var ttl = Math.max(60, Math.min(3600, Number(req.ttl) || 600));
  if (res.ok && body.length < 90000) try { c.put(ck, JSON.stringify(res), ttl); } catch (e) {}
  return res;
}

// ٢) ذكاء اصطناعي داخل التطبيقات المبنية: يُخصم من رصيد صاحب التطبيق
function ownerState(uid) { var raw = prop('u:' + uid); return raw ? JSON.parse(raw) : null; }
function appAsk(user, req, t0) {
  var m = req.appId === 'preview' ? { owner: user.uid } : appMeta(req.appId);
  if (!m || !m.owner) return { ok: false, error: { code: 'no_app', message: 'التطبيق غير مفعّل على سحابة بانِي' } };
  if (!hit('ai:' + req.appId + ':' + user.uid + ':' + Utilities.formatDate(new Date(), 'UTC', 'yyyyMMddHH'), CFG.APP_AI_PER_HOUR, 3700)) return { ok: false, error: { code: 'rate', message: 'وصلت للحد المسموح من الأسئلة هذه الساعة' } };
  var prompt = String(req.prompt || '').slice(0, 6000), system = String(req.system || '').slice(0, 3000);
  if (!prompt) return { ok: false, error: { code: 'bad_request', message: 'السؤال فارغ' } };
  var lock = LockService.getScriptLock(), s; lock.waitLock(10000);
  try {
    s = ownerState(m.owner);
    if (!s) return { ok: false, error: { code: 'owner_credits', message: 'الخدمة غير متاحة حالياً' } };
    if (s.blocked) return { ok: false, error: { code: 'owner_credits', message: 'الخدمة غير متاحة حالياً' } };
    s.plan = s.plan || 'free';
    var remaining = planPoints(s) - (s.used || 0) + (s.bonus || 0);
    if (remaining <= 0) return { ok: false, error: { code: 'owner_credits', message: 'الخدمة غير متاحة حالياً، أبلغ صاحب التطبيق' } };
    var day = Utilities.formatDate(new Date(), 'UTC', 'yyyy-MM-dd');
    if (Number(prop('day:' + day) || 0) >= CFG.DAILY_CAP_USD) return { ok: false, error: { code: 'daily_cap', message: 'الخدمة مزدحمة اليوم، حاول غداً' } };
  } finally { lock.releaseLock(); }
  var body = { contents: [{ role: 'user', parts: [{ text: prompt }] }], generationConfig: { temperature: 0.6, maxOutputTokens: 2000 } };
  if (system) body.systemInstruction = { parts: [{ text: system + '\nأجب بالعربية بوضوح واختصار ما لم يُطلب غير ذلك.' }] };
  if (req.json) body.generationConfig.responseMimeType = 'application/json';
  var r;
  try {
    r = UrlFetchApp.fetch('https://generativelanguage.googleapis.com/v1beta/models/' + CFG.APP_AI_MODEL + ':generateContent', {
      method: 'post', contentType: 'application/json', payload: JSON.stringify(body), muteHttpExceptions: true, headers: { 'x-goog-api-key': prop('GEMINI_KEY') }
    });
  } catch (e) { return { ok: false, error: { code: 'timeout', message: 'استغرق الرد وقتاً طويلاً، حاول مرة أخرى' } }; }
  var data; try { data = JSON.parse(r.getContentText()); } catch (e2) { data = {}; }
  if (r.getResponseCode() !== 200) return { ok: false, error: { code: 'busy', message: 'الخدمة مشغولة، حاول بعد قليل' } };
  var c0 = (data.candidates || [])[0] || {}, text = ((c0.content && c0.content.parts) || []).map(function(p){ return p.thought ? '' : (p.text || ''); }).join('');
  var u = data.usageMetadata || {}, p = PRICES[CFG.APP_AI_MODEL];
  var inT = u.promptTokenCount || 0, outT = (u.candidatesTokenCount || 0) + (u.thoughtsTokenCount || 0);
  var usd = (inT * p.in + outT * p.out) / 1e6, pts = usd / CFG.POINT_USD;
  var lock2 = LockService.getScriptLock(); lock2.waitLock(10000);
  try {
    var s2 = ownerState(m.owner) || s; s2.plan = s2.plan || 'free';
    var fromPlan = Math.min(pts, Math.max(0, planPoints(s2) - (s2.used || 0)));
    s2.used = (s2.used || 0) + fromPlan; if (pts > fromPlan) s2.bonus = Math.max(0, (s2.bonus || 0) - (pts - fromPlan));
    s2.appAi = (s2.appAi || 0) + 1;
    PropertiesService.getScriptProperties().setProperty('u:' + m.owner, JSON.stringify(s2));
    var dk = 'day:' + Utilities.formatDate(new Date(), 'UTC', 'yyyy-MM-dd');
    PropertiesService.getScriptProperties().setProperty(dk, String(Number(prop(dk) || 0) + usd));
  } finally { lock2.releaseLock(); }
  logRow({ uid: m.owner, email: 'app:' + req.appId }, CFG.APP_AI_MODEL, 'appAsk', inT, outT, usd);
  return { ok: true, text: text, points: Math.round(pts) };
}

// ٣) إشعارات من صاحب التطبيق لكل مستخدميه (Firebase Cloud Messaging)
function fcmToken() { return ScriptApp.getOAuthToken(); }
function pushSend(user, req) {
  var m = appMeta(req.appId);
  if (!m || m.owner !== user.uid) return { ok: false, error: { code: 'not_owner', message: 'الإرسال لصاحب التطبيق فقط' } };
  var title = String(req.title || '').slice(0, 80), body = String(req.body || '').slice(0, 240);
  if (!title) return { ok: false, error: { code: 'bad_request', message: 'اكتب عنوان الإشعار' } };
  if (!hit('push:' + req.appId + ':' + Utilities.formatDate(new Date(), 'UTC', 'yyyyMMdd'), CFG.PUSH_PER_DAY, 86400)) return { ok: false, error: { code: 'rate', message: 'وصلت لحد الإشعارات اليومي (' + CFG.PUSH_PER_DAY + ')' } };
  // أجهزة التطبيق: يقرؤها الخادم برمز صاحب التطبيق نفسه، فتطبَّق قواعد الأمان
  var tokens = [], pageToken = '';
  for (var guard = 0; guard < 10; guard++) {
    var d = fsDoc('apps/' + req.appId + '/devices?pageSize=300' + (pageToken ? '&pageToken=' + encodeURIComponent(pageToken) : ''), req.idToken);
    if (!d) break;
    (d.documents || []).forEach(function(doc){ var t = fsVal((doc.fields || {}).token); if (t) tokens.push(t); });
    if (!d.nextPageToken) break; pageToken = d.nextPageToken;
  }
  if (!tokens.length) return { ok: true, sent: 0, devices: 0 };
  var url = 'https://fcm.googleapis.com/v1/projects/' + CFG.PROJECT_ID + '/messages:send', auth = 'Bearer ' + fcmToken(), sent = 0, failed = 0;
  for (var i = 0; i < tokens.length; i += 100) {
    var reqs = tokens.slice(i, i + 100).map(function(t){ return { url: url, method: 'post', contentType: 'application/json', muteHttpExceptions: true, headers: { Authorization: auth },
      payload: JSON.stringify({ message: { token: t, notification: { title: title, body: body }, data: { route: String(req.route || '/'), appId: req.appId }, android: { priority: 'high' } } }) }; });
    UrlFetchApp.fetchAll(reqs).forEach(function(r){ if (r.getResponseCode() === 200) sent++; else { failed++; if (failed === 1) console.warn('fcm', r.getResponseCode(), r.getContentText().slice(0, 300)); } });
  }
  logRow(user, 'PUSH', req.appId, tokens.length, sent, 0);
  return { ok: true, sent: sent, failed: failed, devices: tokens.length };
}

// ٤) تسجيل تطبيق أندرويد في Firebase وإرجاع google-services.json (لازم للإشعارات)
function fcmApp(user, req) {
  var pkg = String(req.packageName || '');
  if (!/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$/.test(pkg)) return { ok: false, error: { code: 'bad_request', message: 'معرّف التطبيق غير صالح' } };
  var m = appMeta(req.appId);
  if (!m || m.owner !== user.uid) return { ok: false, error: { code: 'not_owner', message: 'فعّل قاعدة البيانات أولاً' } };
  var key = 'fcm:' + pkg, saved = prop(key);
  if (saved) { var sv = JSON.parse(saved); if (sv.owner !== user.uid) return { ok: false, error: { code: 'taken', message: 'هذا المعرّف مستخدم لتطبيق آخر' } }; return { ok: true, config: sv.config }; }
  var base = 'https://firebase.googleapis.com/v1beta1/projects/' + CFG.PROJECT_ID, H = { Authorization: 'Bearer ' + ScriptApp.getOAuthToken() };
  var list = UrlFetchApp.fetch(base + '/androidApps?pageSize=100', { headers: H, muteHttpExceptions: true });
  if (list.getResponseCode() !== 200) { console.warn('fb list', list.getResponseCode(), list.getContentText().slice(0, 300)); return { ok: false, error: { code: 'fb_api', message: 'إعداد الإشعارات غير مكتمل في الخادم' } }; }
  var found = (JSON.parse(list.getContentText()).apps || []).filter(function(a){ return a.packageName === pkg; })[0];
  if (!found) {
    var cr = UrlFetchApp.fetch(base + '/androidApps', { method: 'post', contentType: 'application/json', headers: H, muteHttpExceptions: true, payload: JSON.stringify({ packageName: pkg, displayName: String(m.name || pkg).slice(0, 60) }) });
    if (cr.getResponseCode() !== 200) { console.warn('fb create', cr.getResponseCode(), cr.getContentText().slice(0, 300)); return { ok: false, error: { code: 'fb_api', message: 'تعذّر تسجيل التطبيق في Firebase' } }; }
    var op = JSON.parse(cr.getContentText());
    for (var k = 0; k < 10 && !op.done; k++) { Utilities.sleep(1500); op = JSON.parse(UrlFetchApp.fetch('https://firebase.googleapis.com/v1beta1/' + op.name, { headers: H, muteHttpExceptions: true }).getContentText()); }
    if (!op.done || !op.response) return { ok: false, error: { code: 'fb_api', message: 'التسجيل يأخذ وقتاً، حاول بعد دقيقة' } };
    found = op.response;
  }
  var cfg = UrlFetchApp.fetch('https://firebase.googleapis.com/v1beta1/' + found.name + '/config', { headers: H, muteHttpExceptions: true });
  if (cfg.getResponseCode() !== 200) return { ok: false, error: { code: 'fb_api', message: 'تعذّر جلب إعدادات Firebase' } };
  var content = JSON.parse(cfg.getContentText()).configFileContents;
  PropertiesService.getScriptProperties().setProperty(key, JSON.stringify({ owner: user.uid, config: content }));
  return { ok: true, config: content };
}

// ═════════════ مكافأة الإعلان ═════════════
function adReward(user) {
  var lock = LockService.getScriptLock(); lock.waitLock(10000);
  try {
    var s = loadState(user), now = Date.now(), today = Utilities.formatDate(new Date(), 'UTC', 'yyyy-MM-dd');
    if (s.plan !== 'free') return { ok: false, error: { code: 'subscribed', message: 'المشتركون بلا إعلانات' }, credits: creditsView(user, s) };
    if (s.blocked) return { ok: false, error: { code: 'blocked', message: 'أُوقف حسابك. تواصل مع الدعم.' } };
    if (s.adDay !== today) { s.adDay = today; s.adN = 0; }
    if (s.adN >= CFG.AD_PER_DAY) return { ok: false, error: { code: 'ad_limit', message: 'وصلت لحد الإعلانات اليوم، عُد غداً' }, credits: creditsView(user, s) };
    if (s.adLast && now - s.adLast < CFG.AD_MIN_GAP_MS) return { ok: false, error: { code: 'too_fast', message: 'انتظر قليلاً قبل الإعلان التالي' }, credits: creditsView(user, s) };
    s.adN++; s.adLast = now; s.adTotal = (s.adTotal || 0) + 1; s.bonus = (s.bonus || 0) + CFG.AD_POINTS;
    saveState(user, s);
    logRow(user, 'AD', 'reward', 0, CFG.AD_POINTS, 0);
    return { ok: true, added: CFG.AD_POINTS, credits: creditsView(user, s) };
  } finally { lock.releaseLock(); }
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
    rows.push([k.slice(2), s.email || '', (s.plan || '') + (s.founder ? ' (مؤسس #' + s.no + ')' : ''), Math.round(s.used || 0), Math.round(s.bonus || 0), s.total || 0, s.blocked ? 'موقوف: ' + (s.blockReason || '') : '', s.last || '']);
  });
  var sh = sheet('users'); sh.clear();
  sh.appendRow(['uid', 'البريد', 'الخطة', 'نقاط هذا الشهر', 'رصيد إضافي', 'عدد الطلبات', 'الحالة', 'آخر استخدام']);
  var fr = sheet('free'); fr.clear();
  fr.appendRow(['البند', 'القيمة']);
  fr.appendRow(['عدد الحسابات', Number(all.usersCount || 0)]);
  fr.appendRow(['المؤسسون (الحد ' + CFG.FOUNDERS + ')', Math.min(CFG.FOUNDERS, Number(all.usersCount || 0))]);
  fr.appendRow(['ما صرفته على المجانيين $', Math.round(Number(all['free:total'] || 0) * 100) / 100]);
  fr.appendRow(['الميزانية $', CFG.FREE_BUDGET_USD]);
  fr.appendRow(['المتبقي $', Math.max(0, Math.round((CFG.FREE_BUDGET_USD - Number(all['free:total'] || 0)) * 100) / 100)]);
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
