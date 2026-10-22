// حكم التصميم: يرسل لقطة كل شاشة لنموذج رؤية ويقيّمها من ١٠ بمعايير تطبيقات المتاجر العالمية
// يُستدعى من e2e.js بعد بناء التطبيق وتصويره. يحتاج مفتاح Gemini (لا يعمل في وضع FAKE بلا مفتاح)
const fs = require('fs'), path = require('path');
const RUBRIC = `أنت مدير تصميم في شركة تطبيقات عالمية (مستوى Airbnb وRevolut وApple)، وتقيّم لقطة شاشة واحدة من تطبيق جوال عربي RTL بصرامة.
قيّم من ١ إلى ١٠ حيث: ١٠ = يمكن نشره في المتجر بجانب أفضل التطبيقات العالمية، ٧ = احترافي جيد مع عيوب صغيرة، ٥ = مقبول لكنه عادي، ٣ = يبدو كقالب أو هاوٍ.
المعايير: (١) التسلسل البصري ووضوح الأهم أولاً (٢) المسافات والمحاذاة والإيقاع (٣) الطباعة وأحجام النص وأوزانه (٤) اللون والتباين وتناسق الهوية (٥) جودة المكونات (بطاقات، أزرار، حقول، أيقونات) (٦) اكتمال المحتوى (لا نصوص مكسورة أو undefined أو صناديق فارغة بلا سبب) (٧) الحالات الفارغة والتحميل إن ظهرت (٨) صحة اتجاه RTL.
لا تجامل. حالة فارغة مصممة جيداً لا تُعاقب، لكن الشاشة الفارغة بلا قصد تُعاقب.
أعد JSON فقط: {"score": رقم, "strengths": ["..."], "issues": ["عيب محدد وكيف يُصلح"]} بحد أقصى ٣ نقاط لكل قائمة.`;

async function ask(key, model, b64) {
  const body = { contents: [{ role: 'user', parts: [{ text: RUBRIC }, { inline_data: { mime_type: 'image/png', data: b64 } }] }],
    generationConfig: { responseMimeType: 'application/json', temperature: 0.2 } };
  for (let t = 0; t < 4; t++) {
    try {
      const r = await fetch('https://generativelanguage.googleapis.com/v1beta/models/' + model + ':generateContent', { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key }, body: JSON.stringify(body) });
      const d = await r.json();
      if (r.ok) { const txt = ((d.candidates || [])[0] || {}).content.parts.map(p => p.text || '').join(''); const j = JSON.parse(txt.replace(/^```(json)?|```$/g, '').trim()); if (typeof j.score === 'number') return j; }
    } catch (e) {}
    await new Promise(s => setTimeout(s, 8000 * (t + 1)));
  }
  return null;
}

module.exports = async function judge(dir, key, model) {
  const files = fs.readdirSync(dir).filter(f => /^\d\d-.+\.png$/.test(f) && !/^0[01]-/.test(f)).sort();
  const screens = {};
  for (const f of files) {
    const j = await ask(key, model, fs.readFileSync(path.join(dir, f)).toString('base64'));
    if (j) screens[f.replace(/^\d\d-|\.png$/g, '')] = { score: Math.max(1, Math.min(10, j.score)), strengths: (j.strengths || []).slice(0, 3), issues: (j.issues || []).slice(0, 3) };
  }
  const sc = Object.values(screens).map(x => x.score);
  return { model, score: sc.length ? Math.round(sc.reduce((a, b) => a + b, 0) / sc.length * 10) / 10 : null, min: sc.length ? Math.min(...sc) : null, screens };
};
