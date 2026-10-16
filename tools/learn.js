// يتعلم بانِي من جولات القياس: يجمع أمثلة التطبيقات التي نجحت كل رحلاتها، ودروساً من الأخطاء المتكررة،
// ويكتبها في www/index.html بين علامتي LEARNED. يُشغَّل من سير عمل learn.yml بعد كل قياس.
// الأمان: الأمثلة من قياسنا فقط (لا من مستخدمين)، والدروس نصوص ثابتة من القاموس أدناه — لا يدخل التعليمات نص حر.
const { execSync } = require('child_process'), fs = require('fs');
const sh = c => execSync(c, { encoding: 'utf8', maxBuffer: 1 << 28 });
const files = sh('git ls-tree -r --name-only origin/e2e-bench').split('\n').filter(Boolean);
const runs = {};
for (const f of files) { const m = f.match(/^bench\/(\d+)\/(\d+)\/(report|example)\.json$/); if (m) (runs[m[1] + '/' + m[2]] = runs[m[1] + '/' + m[2]] || {})[m[3]] = f; }
const read = f => { try { return JSON.parse(sh('git show origin/e2e-bench:' + f)); } catch (e) { return null; } };
// قاموس الدروس: نمط الخطأ ← الدرس لكل دور (نصوص ثابتة نكتبها نحن)
const DICT = [
  { re: /لا شيء في|لم تُستدعَ أي عملية حفظ|الحفظ لا يعمل/, roles: { specwriter: 'كل نموذج إدخال يحفظ في المجموعة الصحيحة من العقد، وزر الإرسال type=submit، ولا تضع userId أو الحالة في الحقول.', screen: 'زر الحفظ يجب أن يستدعي Data.X.create فعلاً بعد التحقق، ويُظهر رسالة نجاح، ولا يتوقف بصمت إذا نقص حقل (أظهر UI.toast بالحقل الناقص).' } },
  { re: /الأزرار: لا شيء|القائمة فارغة|لا يظهر للدور|byStatus|visible/, roles: { planner: 'في الأنظمة متعددة الأدوار حدّد visibility لكل مجموعة يشترك فيها دوران، وأضف حقل <role>Id للدور الذي يستلم المهام.', specwriter: 'قائمة الدور الذي يستلم المهام تستخدم show:"visible" مع إجراء take للعنصر الجديد ثم status للمراحل التالية.', screen: 'كل قائمة تعرض ما أنشأه دور آخر تستخدم await Data.X.visible() لا فلتراً خاصاً.' } },
  { re: /is not a function|Cannot read properties|undefined \(reading/, roles: { screen: 'لا تستدعِ دوال غير موجودة في عقد الهيكل، وتحقق من وجود العنصر قبل قراءة خصائصه (x && x.field).' } },
  { re: /الحقل .* غير موجود في الشاشة|لم يُعثر على/, roles: { tester: 'استخدم فقط الأزرار والحقول الظاهرة في خريطة الواجهة، واضغط زر فتح النموذج قبل تعبئة حقوله.' } },
  { re: /الحالة .* ليست من حالات|status بالقيم/, roles: { planner: 'عرّف statuses لكل مجموعة لها مراحل، بقيم إنجليزية صغيرة مرتبة.', specwriter: 'استخدم في status:X وفي when قيم الحالات من العقد حرفياً.' } },
  { re: /غير موجود في orders|غير موجود في \w+ \(الموجود/, roles: { specwriter: 'أسماء الحقول في card وfields وfilter من العقد حرفياً، بلا اختراع.' } },
  { re: /تباين|غير مقروء/, roles: { screen: 'لا تكتب ألواناً ثابتة للنص داخل hero أو فوق خلفية فاتحة، استخدم متغيرات الألوان.' } },
];
const examples = [], counts = {};
for (const k of Object.keys(runs).sort()) {
  const r = runs[k], rep = r.report && read(r.report); if (!rep) continue;
  const msgs = Object.values(rep.runtime || {}).flat().filter(m => !/^تصميم:/.test(m));
  msgs.forEach(m => DICT.forEach((d, i) => { if (d.re.test(m)) counts[i] = (counts[i] || 0) + 1; }));
  const lab = (rep.steps || [])[4] || '', fm = lab.match(/رحلات المستخدم: (\S+) من (\S+)/);
  const allFlows = fm && fm[1] === fm[2];
  if (rep.status === 'ready' && allFlows && !msgs.length && r.example) { const ex = read(r.example); if (ex && ex.plan) examples.push(ex); }
}
// أحدث مثال لكل فكرة، والأفضّل ما فيه مواصفات شاشات
const byIdea = {}; examples.forEach(e => { const key = String(e.idea || e.plan.name).slice(0, 60); if (!byIdea[key] || (e.specs || []).length >= (byIdea[key].specs || []).length) byIdea[key] = e; });
const keep = Object.values(byIdea).slice(-30).map(e => ({ idea: String(e.idea || '').slice(0, 300), plan: e.plan, specs: (e.specs || []).slice(0, 10) }));
const lessons = {};
Object.keys(counts).filter(i => counts[i] >= 2).sort((a, b) => counts[b] - counts[a]).forEach(i => { const d = DICT[i]; Object.keys(d.roles).forEach(r => { (lessons[r] = lessons[r] || []).push(d.roles[r]); }); });
const learned = { examples: keep, lessons, at: new Date().toISOString().slice(0, 10) };
const p = 'www/index.html', s = fs.readFileSync(p, 'utf8');
const out = s.replace(/\/\*LEARNED\*\/[\s\S]*?\/\*\/LEARNED\*\//, () => '/*LEARNED*/var LEARNED = ' + JSON.stringify(learned).replace(/<\//g, '<\\/') + ';/*/LEARNED*/');
if (out === s) { console.log('لا تغيير'); process.exit(0); }
fs.writeFileSync(p, out);
console.log('أمثلة:', keep.length, '| دروس:', JSON.stringify(Object.fromEntries(Object.entries(lessons).map(([k, v]) => [k, v.length]))), '| تكرار الأخطاء:', JSON.stringify(counts));
