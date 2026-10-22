// قياس بانِي بمزوّد متوافق مع OpenAI (DeepSeek افتراضياً): يحوّل طلبات Gemini التي يرسلها بانِي إلى المزوّد ويعيد الرد بصيغة Gemini
// المتغيرات: ALT_KEY (إلزامي)، ALT_URL، ALT_MODEL، ALT_MAX_TOKENS
const URL_ = process.env.ALT_URL || 'https://api.deepseek.com/chat/completions';
const MODEL = process.env.ALT_MODEL || 'deepseek-chat';
const MAX = +(process.env.ALT_MAX_TOKENS || 8192);
let usage = { in: 0, out: 0, calls: 0 };
process.on('exit', () => console.log('ALT usage', JSON.stringify(usage)));
module.exports = async (ctx) => {
  await ctx.route(/generativelanguage\.googleapis\.com/, async (route) => {
    const req = route.request();
    if (req.method() !== 'POST') return route.fulfill({ json: { models: [{ name: 'models/' + MODEL }] } });
    const b = JSON.parse(req.postData() || '{}');
    const text = c => ((c && c.parts) || []).map(p => p.text || '').join('');
    const json = (b.generationConfig || {}).responseMimeType === 'application/json';
    const messages = [{ role: 'system', content: text(b.systemInstruction) + (json ? '\n\nأعد JSON صالحاً فقط.' : '') }]
      .concat((b.contents || []).map(c => ({ role: c.role === 'model' ? 'assistant' : 'user', content: text(c) })));
    let r, d;
    for (let t = 0; t < 4; t++) {
      try {
        r = await fetch(URL_, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + process.env.ALT_KEY },
          body: JSON.stringify({ model: MODEL, messages, max_tokens: MAX, ...(json ? { response_format: { type: 'json_object' } } : {}) }) });
        d = await r.json();
        if (r.ok) break;
      } catch (e) { d = { error: { message: String(e) } }; }
      await new Promise(s => setTimeout(s, 5000 * (t + 1)));
    }
    if (!r || !r.ok) return route.fulfill({ status: 503, json: { error: { code: 503, message: (d && d.error && d.error.message) || 'alt provider error' } } });
    const ch = (d.choices || [])[0] || {}, u = d.usage || {};
    usage.in += u.prompt_tokens || 0; usage.out += u.completion_tokens || 0; usage.calls++;
    route.fulfill({ json: { candidates: [{ content: { role: 'model', parts: [{ text: (ch.message && ch.message.content) || '' }] }, finishReason: ch.finish_reason === 'length' ? 'MAX_TOKENS' : 'STOP' }],
      usageMetadata: { promptTokenCount: u.prompt_tokens || 0, candidatesTokenCount: u.completion_tokens || 0 } } });
  });
};
