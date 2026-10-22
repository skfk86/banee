# بانِي — تطبيق أندرويد

صف تطبيقك بالعربي، ونبنيه لك كاملاً. Capacitor 7 + Firebase (`bani-b28a0`) + اشتراكات Google Play.

---

## ١. إعداد Firebase (مرة واحدة)

في [Firebase Console](https://console.firebase.google.com/project/bani-b28a0):

1. **Authentication ← Sign-in method ← Email/Password ← Enable**.
2. **Firestore Database ← Create database ← Production mode**، واختر منطقة قريبة.
3. **Firestore ← Rules**: الصق محتوى ملف `firestore.rules` كاملاً ثم **Publish**.

أو من Termux:

```bash
npm install -g firebase-tools
firebase login --no-localhost
firebase deploy --only firestore:rules
```

> **مهم:** القواعد هي ما يمنع أي مستخدم من قراءة مشاريع غيره. لا تنشر التطبيق قبل نشرها.

---

## ١-أ. روابط المشاركة (مرة واحدة)

زر «مشاركة» في الاستوديو يعطي كل تطبيق رابطاً مثل `https://skfk86.github.io/banee/a/#xxxxxxxx` يفتحه أي شخص من المتصفح، وفي أسفله «صُنع ببانِي».
صفحة العرض (`site/`) تُنشر تلقائياً على GitHub Pages عبر `.github/workflows/pages.yml`.

1. GitHub ← المستودع ← Settings ← Pages ← Source: **GitHub Actions**.
2. Firestore ← Rules: الصق `firestore.rules` كاملاً ← Publish.
3. Authentication ← Sign-in method ← **Anonymous** مفعّل (تستخدمه نسخة الويب لقاعدة البيانات التجريبية).

---

## ١-ب٠. البناء السحابي للـ APK (مرة واحدة)

زر «ابنِ APK وثبّته على جوالك» يبني تطبيق المستخدم على GitHub Actions (`.github/workflows/cloud-apk.yml`) وينشره كإصدار في هذا المستودع العام.

1. GitHub ← Settings ← Developer settings ← **Fine-grained token**: المستودع `skfk86/banee` فقط، صلاحية **Contents: Read and write**.
2. Apps Script ← Project Settings ← Script Properties: أضف `GH_TOKEN` بقيمة الرمز، ثم انشر نسخة جديدة من الخادم.
3. سير العمل يعمل من الفرع الافتراضي `main` فقط: ادمج التغييرات فيه.
4. انشر القواعد الجديدة: `firebase deploy --only firestore:rules`.

الحد الافتراضي ٣ بناءات لكل مستخدم يومياً (`APK_PER_DAY` في `server/Code.gs`).

---

## ١-ب. خادم Gemini (مهم قبل البناء)

بانِي لا تحتوي أي مفتاح. الذكاء الاصطناعي يمر عبر خادم مجاني على Google Apps Script يحمل مفتاحك ويحسب رصيد كل مستخدم.
اتبع **`server/README.md`**، ثم ضع رابط الخادم في `www/index.html`:

```js
var PROXY_URL = 'https://script.google.com/macros/s/....../exec';
```

إذا تركته فارغاً، يطلب بانِي من كل مستخدم مفتاح Gemini الخاص به (مفيد لتجربتك أنت فقط).

---

## ٢. البناء على GitHub

```bash
pkg install git unzip -y
cd ~/storage/downloads
unzip banee-android.zip -d banee
cd banee
git init && git add . && git commit -m "بانِي الإصدار الأول"
git branch -M main
git remote add origin https://github.com/اسم_حسابك/banee.git
git push -u origin main
```

بعد ٥–١٠ دقائق تجد `banee-debug.apk` في **Releases**.

### مفتاح التوقيع (ضروري للاشتراكات)

اشتراكات Google Play **لا تعمل في نسخة debug** ولا في APK مثبّت يدوياً. تعمل فقط في نسخة موقّعة مرفوعة على Play (ولو في الاختبار الداخلي).

```bash
keytool -genkey -v -keystore release.jks -alias banee -keyalg RSA -keysize 2048 -validity 10000
base64 -w0 release.jks > release.b64
```

في المستودع: **Settings ← Secrets and variables ← Actions** أضف:

| الاسم | القيمة |
|---|---|
| `KEYSTORE_BASE64` | محتوى `release.b64` |
| `KEYSTORE_PASSWORD` | كلمة مرور الملف |
| `KEY_ALIAS` | `banee` |
| `KEY_PASSWORD` | كلمة مرور المفتاح |

احفظ `release.jks` في مكان آمن خارج المستودع. فقدانه يعني أنك لن تستطيع تحديث التطبيق أبداً.

---

## ٣. إعداد الاشتراكات في Google Play Console

1. **حساب التاجر:** Play Console ← Setup ← Payments profile. بدونه لا يمكن إنشاء اشتراكات. (تحقّق من توفره لبلد حسابك.)
2. **أنشئ التطبيق** بالمعرّف `com.alloush.banee` (يمكنك تغييره في `capacitor.config.json` قبل أول رفع فقط).
3. **ارفع `banee-release.aab`** على **Testing ← Internal testing**. الاشتراكات لا تظهر قبل رفع نسخة فيها مكتبة الدفع.
4. **Monetize ← Products ← Subscriptions** وأنشئ ثلاثة اشتراكات **بنفس هذه المعرّفات حرفياً**:

| Product ID | الاسم | Base plan | السعر المقترح |
|---|---|---|---|
| `banee_starter` | مبتدئ | شهري، تجديد تلقائي | 9 USD |
| `banee_pro` | محترف | شهري، تجديد تلقائي | 19 USD |
| `banee_business` | أعمال | شهري، تجديد تلقائي | 49 USD |

   ثم **Monetize ← Products ← In-app products** وأنشئ حزمتي رصيد:

| Product ID | الاسم | السعر |
|---|---|---|
| `banee_credits_small` | ١٬٣٦٠ نقطة | 3 USD |
| `banee_credits_large` | ٤٬٠٠٠ نقطة | 8 USD |

   فعّل (Activate) الـ Base plan لكل اشتراك. Google تحوّل السعر لعملة كل بلد تلقائياً، والتطبيق يعرض السعر المحلي القادم من Play.

5. **التجربة بدون دفع حقيقي:** Setup ← **License testing** وأضف بريد Gmail الذي على جوالك. ثم ثبّت التطبيق من رابط الاختبار الداخلي، واشترك: ستظهر بطاقة اختبار ولن تُخصم أي أموال.

---

## ٤. كيف يعمل الاشتراك

```
المستخدم يضغط «اشترك» ← نافذة Google Play ← الدفع
        ← المكتبة تؤكد الشراء على الجهاز ← تُقرّ به (acknowledge)
        ← بانِي تكتب الخطة في Firestore: users/{uid}
            plan, planUntil, planToken (رمز الشراء), planOrderId (GPA....)
        ← عند كل فتح للتطبيق: مزامنة مع Google Play (تجديد / إلغاء / انتهاء)
```

- **الرصيد:** المجانية ٦٠٠ نقطة مرة واحدة، مبتدئ ٤٬٠٠٠ شهرياً، محترف ٨٬٥٠٠، أعمال ٢٢٬٠٠٠، مع حزم إضافية لا تنتهي. الخادم يتحقق من كل اشتراك وشراء مباشرة مع Google Play، فلا يمكن تزويرهما.
- **الإلغاء:** من زر «إدارة الاشتراك» الذي يفتح اشتراكات Google Play.
- **جهاز جديد:** زر «استعادة اشتراكي» في نافذة الخطط.

### الأمان

- مفتاح Gemini على الخادم فقط، فلا يمكن استخراجه من ملف APK.
- الخادم يتحقق من الاشتراك وحزم الرصيد مع Google Play مباشرة، ويربط كل شراء بحساب واحد فقط.
- حدود الغش والحد اليومي على الخادم، فلا يمكن تجاوزها بتعديل التطبيق.

---

## ٥. قبل النشر للعامة

- [ ] نشرت `firestore.rules`.
- [ ] جرّبت إنشاء حساب، بناء تطبيق، إغلاق التطبيق وفتحه، ووجدت المشروع محفوظاً.
- [ ] جرّبت الاشتراك بحساب License testing.
- [ ] **أمان البيانات (Data safety):** المعلومات الشخصية (الاسم، البريد) لوظائف التطبيق وإدارة الحساب · المحتوى الذي ينشئه المستخدم (مشاريعه) · سجل المشتريات. لا مشاركة مع جهات خارجية. تشفير أثناء النقل: نعم. حذف البيانات بطلب: نعم.
- [ ] سياسة خصوصية منشورة (يمكنك إنشاؤها من «حزمة Google Play» في الاستوديو لأي تطبيق، والتعديل عليها لبانِي).
- [ ] الحسابات الشخصية الجديدة: اختبار مغلق مع ١٢ مختبِراً لمدة ١٤ يوماً قبل الإنتاج.

---

## الملفات

| الملف | الوظيفة |
|---|---|
| `www/index.html` | بانِي كاملة |
| `capacitor.config.json` | اسم التطبيق ومعرّفه |
| `package.json` | Capacitor 7 + Filesystem + Share + مكتبة اشتراكات Google Play |
| `assets/` | الأيقونة وشاشة البداية |
| `firestore.rules` · `firebase.json` · `.firebaserc` | قواعد الأمان ونشرها |
| `server/` | خادم Gemini على Apps Script ودليله |
| `.github/workflows/build.yml` | بناء APK وAAB تلقائياً |
