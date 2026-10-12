# خادم بانِي على Google Apps Script

مجاني، بدون بطاقة، بحساب Google نفسه الذي تستخدمه لـ Firebase وPlay Console.

```
تطبيق بانِي ──(رمز دخول Firebase + رمز الاشتراك)──▶ Apps Script ──(مفتاحك)──▶ Gemini
                                                    │
                                                    ├─ يتحقق من المستخدم عبر Firebase
                                                    ├─ يتحقق من الاشتراك عبر Google Play مباشرة
                                                    ├─ يخصم النقاط حسب الاستهلاك الفعلي
                                                    ├─ يوقف من يتجاوز حدود الغش تلقائياً
                                                    └─ يوقف الكل إذا تجاوز إنفاق اليوم حدّك
```

> **استخدم نفس حساب Google** الذي يملك مشروع Firebase وحساب Play Console، لأن الخادم يتحقق من الاشتراكات بصلاحياته.

---

## ١. إنشاء المشروع (من متصفح الجوال)

1. افتح [script.google.com](https://script.google.com) ← **New project**، وسمّه `banee-server`.
2. احذف محتوى `Code.gs` والصق محتوى ملف `Code.gs` من هذا المجلد.
3. **Project Settings** (الترس) ← فعّل **Show "appsscript.json" manifest file in editor**.
4. ارجع للمحرر، افتح `appsscript.json` والصق محتوى الملف من هذا المجلد.
5. **Project Settings ← Script Properties ← Add script property**:

| Property | Value |
|---|---|
| `GEMINI_KEY` | مفتاح Gemini من [aistudio.google.com](https://aistudio.google.com/apikey) |

> المفتاح يبقى هنا فقط. لا تضعه في التطبيق ولا في GitHub.

## ٢. التشغيل الأول

في المحرر اختر الدالة **`testGemini`** ← **Run**. وافق على الصلاحيات (ستظهر "Google hasn't verified this app": اضغط Advanced ← Go to banee-server، لأنه سكربتك أنت).
في **Execution log** يجب أن ترى `200` ورد Gemini.

ثم شغّل **`setup`**: ينشئ جدول Google Sheets للمتابعة، ويحدّثه كل ساعة. رابط الجدول يظهر في السجل.

## ٣. النشر

**Deploy ← New deployment ← Select type: Web app**:
- Execute as: **Me**
- Who has access: **Anyone**

انسخ رابط **Web app URL** (ينتهي بـ `/exec`)، وضعه في `www/index.html` لمشروع بانِي:

```js
var PROXY_URL = 'https://script.google.com/macros/s/....../exec';
```

> عند تعديل `Code.gs` لاحقاً: **Deploy ← Manage deployments ← Edit (القلم) ← Version: New version ← Deploy**، حتى يبقى نفس الرابط.

## ٤. الإعدادات (أعلى ملف Code.gs)

| الإعداد | القيمة الحالية | المعنى |
|---|---|---|
| `DAILY_CAP_USD` | 5 | أقصى إنفاق يومي لكل المستخدمين معاً، بعده يتوقف البناء حتى الغد |
| `ABUSE` | ٤٠ طلباً/دقيقة · ٣٠٠/ساعة · ٦٦٬٠٠٠ نقطة/شهر | تجاوز أي منها = إيقاف تلقائي للحساب |
| `PLANS` | ٦٠٠ · ٤٠٠٠ · ٨٥٠٠ · ٢٢٠٠٠ | رصيد كل خطة (المجانية مرة واحدة) |
| `PACKS` | ١٣٦٠ · ٤٠٠٠ | نقاط حزم الرصيد الإضافي |
| `PRICES` | أسعار Gemini | **حدّثها إذا غيّرت Google أسعارها** (المصادر تذكر تضاعف سعر 3.7-flash في يناير ٢٠٢٧) |
| `FREE_MODEL` | gemini-3.5-flash-lite | موديل اقتصادي للمستخدمين المجانيين |

### لماذا الخطط رابحة دائماً
النقطة = ٠٫٠٠٠٧٥$ من تكلفة Gemini الفعلية. رصيد كل خطة = ٤٠٪ من صافيها بعد عمولة Google (١٥٪):

| الخطة | صافيك | أقصى تكلفة Gemini | ربحك الأدنى |
|---|---|---|---|
| مبتدئ ٩$ | ٧٫٦٥$ | ٣٫٠٠$ | ٤٫٦٥$ |
| محترف ١٩$ | ١٦٫١٥$ | ٦٫٣٨$ | ٩٫٧٧$ |
| أعمال ٤٩$ | ٤١٫٦٥$ | ١٦٫٥٠$ | ٢٥٫١٥$ |
| حزمة ٣$ | ٢٫٥٥$ | ١٫٠٢$ | ١٫٥٣$ |
| حزمة ٨$ | ٦٫٨٠$ | ٣٫٠٠$ | ٣٫٨٠$ |

## ٥. المتابعة والإدارة

في جدول **بانِي — الاستهلاك**:
- **log**: كل طلب (المستخدم، الموديل، الرموز، التكلفة) وكل إيقاف أو شراء رصيد.
- **users**: رصيد كل مستخدم وحالته (يتحدث كل ساعة، أو شغّل `report` يدوياً).
- **daily**: الإنفاق اليومي.

من المحرر (غيّر القيمة ثم Run):
- `unblock('uid')`: إلغاء إيقاف حساب.
- `giveCredits('uid', 1000)`: هدية نقاط لمستخدم.

## ٦. حماية إضافية من Google
في [Google Cloud Console](https://console.cloud.google.com/billing) ← Budgets & alerts، ضع **تنبيه ميزانية** لمشروع مفتاح Gemini (مثلاً ٣٠$ شهرياً) يرسل لك بريداً عند ٥٠٪ و٩٠٪.

## ٧. منتجات Google Play المطلوبة
- **اشتراكات:** `banee_starter`، `banee_pro`، `banee_business`.
- **منتجات داخل التطبيق (Managed products، تُستهلك):** `banee_credits_small` (٣$)، `banee_credits_large` (٨$).

## الحدود المعروفة
- كل طلب يجب أن ينتهي خلال ٦٠ ثانية (حد Apps Script). لهذا يكتب بانِي الدروس الطويلة درساً في كل طلب، ويعيد المحاولة تلقائياً إن تجاوز الوقت.
- حوالي ٢٠٬٠٠٠ طلب لـ Gemini يومياً للحساب المجاني. بناء تطبيق ≈ ١٠–٣٠ طلباً.
