# تقرير الاختبار الحقيقي لبانِي

- التطبيق: **أكسفورد بالعربي**
- النتيجة: **ready** 
- الزمن: 17.8 دقيقة
- رحلات مختبرة: رحلة التعلّم (13 خطوات)، تحدي المعلم (11 خطوات)
- المراجعة الشاملة: وُجدت 3 وأُصلحت 3
- **التصميم: 5.1 / 10** (أضعف شاشة 3)
  - home: 4 — اقتطاع المحتوى وتداخله: البطاقة الأخيرة للدورة التدريبية مقطوعة بشكل كامل بواسطة شريط التنقل السفلي، مما يجعل المحتوى غير قابل للوصول. يُصلح ذلك بضمان وجود مسافة كافية أسفل المحتوى القابل للتمرير أو إعادة ترتيب العناصر.
  - course: 6.5 — تكرار الزر الأساسي (CTA Overload): تكرار زر 'ابدأ الدرس' المصمت في كل بطاقة يخلق تلوثاً بصرياً ويشتت المستخدم؛ الحل هو جعل البطاقة بالكامل قابلة للنقر مع إبقاء زر بارز فقط للدرس الحالي واستبدال البقية بأيقونة سهم أو حالة الدرس.
  - lesson: 3 — خطأ حرج في تجربة المستخدم ومنطق التطبيق: الشاشة تعرض حالة 'جاري التحميل' وحالة 'الدرس غير موجود' في نفس الوقت، مما يسبب ارتباكاً كبيراً للمستخدم. يجب عرض حالة واحدة فقط في كل مرة. (الحل: يجب التأكد من أن التطبيق يعرض إما حالة التحميل أو حالة الخطأ/عدم العثور على المحتوى، وليس كليهما معاً).
  - challenges: 7 — عدم توازن الحشو (Padding) داخل البطاقة العلوية مع وجود مساحة فارغة مهدرة على اليسار؛ يُصلح بموازنة الهوامش أو إضافة عنصر رسومي بسيط يكمل المعنى.
  - teach: 5 — تكرار بصري مزعج لعنوان 'لوحة المعلم' (في الشريط العلوي، والبانر الأخضر، وشريط التنقل السفلي)؛ يجب حذف البانر التكراري واستغلال المساحة لمؤشرات أداء رئيسية (KPIs)، وإلغاء شريط التنقل إن كان يحتوي عنصراً واحداً فقط.

## المراحل
- done · هوية «حماس لغوي» · الخطة: ٨ شاشات · ٧ مجموعات · ٣٦ عنصر محتوى
- done · المحتوى: ٣٦ عنصر مكتوب كاملاً
- done · الهيكل جاهز: التنقّل، البيانات، الدخول، التصميم
- done · ٨ شاشات مكتوبة
- done · الفحص: ٤ شاشات بها ملاحظات، راجعها في الاستوديو · رحلات المستخدم: ٠ من ٢ تعمل كاملة · المراجعة: أُصلحت ٣ من ٣ · التصميم: ٥.٨ من ١٠ (حُسّنت ٣ شاشات) · وكيل الإصلاح: أصلح ٣ في ٢٠ خطوة
- done · جاهز للمعاينة والتحميل

## ملاحظات التشغيل المتبقية
- **home**: تصميم: النص "٠ أيام" غير مقروء: تباين 2.1:1 — لونه #f59e0b والخلفية #ffffff من العنصر <div class="card">. الخلفية فاتحة: استخدم var(--text) للنص، أو أزل خلفية ذلك العنصر إن كان داخل hero.
- **course**: تصميم: النص "٠ أيام" غير مقروء: تباين 2.1:1 — لونه #f59e0b والخلفية #ffffff من العنصر <div class="card">. الخلفية فاتحة: استخدم var(--text) للنص، أو أزل خلفية ذلك العنصر إن كان داخل hero. / رحلة «رحلة التعلّم» توقفت عند الخطوة ٣: لم يُعثر على [data-act=open-course][data-id=courses-1] (الزر غير موجود أو اسمه مختلف) — الظاهر الآن: الشاشة course (#/course/courses-1) بدور student؛ الأزرار: openLesson، openQuiz؛ الحقول: لا شيء
- **lesson**: تصميم: النص "٠ أيام" غير مقروء: تباين 2.1:1 — لونه #f59e0b والخلفية #ffffff من العنصر <div class="card">. الخلفية فاتحة: استخدم var(--text) للنص، أو أزل خلفية ذلك العنصر إن كان داخل hero.
- **me**: تصميم: النص "٠ أيام" غير مقروء: تباين 2.1:1 — لونه #f59e0b والخلفية #ffffff من العنصر <div class="card">. الخلفية فاتحة: استخدم var(--text) للنص، أو أزل خلفية ذلك العنصر إن كان داخل hero.
- **challenges**: تصميم: النص "٠ أيام" غير مقروء: تباين 2.1:1 — لونه #f59e0b والخلفية #ffffff من العنصر <div class="card">. الخلفية فاتحة: استخدم var(--text) للنص، أو أزل خلفية ذلك العنصر إن كان داخل hero. / رحلة «تحدي المعلم» توقفت عند الخطوة ٣: لم يُعثر على [data-act=new-challenge] (الزر غير موجود أو اسمه مختلف) — الظاهر الآن: الشاشة challenges (#/challenges) بدور student؛ الأزرار: لا شيء؛ الحقول: لا شيء

## أخطاء صفحة بانِي
- UI.vibrate is not a function @     at about:srcdoc:2380:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2380:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2385:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2380:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2376:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2376:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2375:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2376:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2376:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2376:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2376:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2375:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2376:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2376:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2376:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)
- UI.vibrate is not a function @     at about:srcdoc:2376:14 |     at HTMLDivElement.<anonymous> (about:srcdoc:1880:140)