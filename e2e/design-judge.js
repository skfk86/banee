// حكم التصميم: يرسل لقطة كل شاشة لنموذج رؤية ويقيّمها من ١٠ بمعايير تطبيقات المتاجر العالمية
// يُستدعى من e2e.js بعد بناء التطبيق وتصويره. يحتاج مفتاح Gemini (لا يعمل في وضع FAKE بلا مفتاح)
const fs = require('fs'), path = require('path');
const RUBRIC = `أنت مدير تصميم في شركة تطبيقات عالمية (مستوى Airbnb وRevolut وApple)، وتقيّم لقطة شاشة واحدة من تطبيق جوال عربي RTL بصرامة.
قيّم من ١ إلى ١٠ حيث: ١٠ = يمكن نشره في المتجر بجانب أفضل التطبيقات العالمية، ٧ = احترافي جيد مع عيوب صغيرة، ٥ = مقبول لكنه عادي، ٣ = يبدو كقالب أو هاوٍ.
المعايير: (١) التسلسل البصري ووضوح الأهم أولاً (٢) المسافات والمحاذاة والإيقاع (٣) الطباعة وأحجام النص وأوزانه (٤) اللون والتباين وتناسق الهوية (٥) جودة المكونات (بطاقات، أزرار، حقول، أيقونات) (٦) اكتمال المحتوى (لا نصوص مكسورة أو undefined أو صناديق فارغة بلا سبب) (٧) الحالات الفارغة والتحميل إن ظهرت (٨) صحة اتجاه RTL.
لا تجامل. حالة فارغة مصممة جيداً لا تُعاقب، لكن الشاشة الفارغة بلا قصد تُعاقب.
أعد JSON فقط: {"score": رقم, "strengths": ["..."], "issues": ["عيب محدد وكيف يُصلح"]} بحد أقصى ٣ نقاط لكل قائمة.`;

// الحصة المجانية تنفد عند تشغيل ٨ تطبيقات معاً: ندوّر على كل المفاتيح ثم نماذج بديلة
async function ask(keys, models, b64) {
  const body = { contents: [{ role: 'user', parts: [{ text: RUBRIC }, { inline_data: { mime_type: 'image/png', data: b64 } }] }],
    generationConfig: { responseMimeType: 'application/json', temperature: 0.2 } };
  for (let t = 0; t < keys.length * models.length * 2; t++) {
    const key = keys[t % keys.length], model = models[Math.floor(t / keys.length) % models.length];
    try {
      const r = await fetch('https://generativelanguage.googleapis.com/v1beta/models/' + model + ':generateContent', { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key }, body: JSON.stringify(body) });
      const d = await r.json();
      if (r.ok) { const txt = ((d.candidates || [])[0] || {}).content.parts.map(p => p.text || '').join(''); const j = JSON.parse(txt.replace(/^```(json)?|```$/g, '').trim()); if (typeof j.score === 'number') return j; }
    } catch (e) {}
    await new Promise(s => setTimeout(s, (t + 1) % keys.length ? 1500 : 15000));
  }
  return null;
}

module.exports = async function judge(dir, keys, model) {
  keys = [].concat(keys).filter(Boolean); const models = [model, 'gemini-flash-latest', 'gemini-2.5-flash-lite'].filter((m, i, a) => a.indexOf(m) === i);
  const files = fs.readdirSync(dir).filter(f => /^\d\d-.+\.png$/.test(f) && !/^0[01]-/.test(f)).sort();
  const screens = {};
  for (const f of files) {
    const j = await ask(keys, models, fs.readFileSync(path.join(dir, f)).toString('base64'));
    if (j) screens[f.replace(/^\d\d-|\.png$/g, '')] = { score: Math.max(1, Math.min(10, j.score)), strengths: (j.strengths || []).map(x => typeof x === 'string' ? x : Object.values(x || {}).join(' — ')).slice(0, 3), issues: (j.issues || []).map(x => typeof x === 'string' ? x : Object.values(x || {}).join(' — ')).slice(0, 3) };
  }
  const sc = Object.values(screens).map(x => x.score);
  return { model, score: sc.length ? Math.round(sc.reduce((a, b) => a + b, 0) / sc.length * 10) / 10 : null, min: sc.length ? Math.min(...sc) : null, screens };
};
