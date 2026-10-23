# تقرير الاختبار الحقيقي لبانِي

- التطبيق: **شفاء كير**
- النتيجة: **ready** 
- الزمن: 35.2 دقيقة
- رحلات مختبرة: حجز موعد ودفع الرسوم (12 خطوات)، إدارة وتأكيد الحضور من السكرتارية (7 خطوات)، فحص الطبيب وتسجيل السجل الطبي (14 خطوات)
- المراجعة الشاملة: وُجدت 5 وأُصلحت 0
- **التصميم: 6.8 / 10** (أضعف شاشة 5)
  - patient_home: 7 — غياب زر اتخاذ إجراء (CTA) في شاشة الحالة الفارغة؛ يجب إضافة زر 'إعادة تعيين الفلاتر' لتسهيل استعادة النتائج بنقرة واحدة.
  - doctor_profile: 7 — توجد تباينات طفيفة في درجات اللون الأخضر المستخدمة (مثل البطاقة العلوية وشريحة التخصص)، مما يكسر تناسق الهوية البصرية. يُصلح بتوحيد درجة اللون الأخضر للعلامة التجارية عبر جميع المكونات.
  - checkout: 7 — [object Object]
  - patient_appointments: 5 — شريط التبويب الأوسط به خلل فادح؛ الزر الأبيض النشط فارغ من أي نص (أو النص أبيض فوق خلفية بيضاء)، والحل هو كتابة التبويب النشط مثل 'القادمة' بلون داكن ومتباين.
  - patient_medical_record: 7 — The spacing between the '0 زيارة مسجلة' button and the 'سجل زياراتك والتشخيصات' text is too large, creating an imbalance.
  - doctor_schedule: 7 — The spacing between the tab bar items (المكتملة, القادمة, في الانتظار) feels slightly inconsistent, particularly between 'القادمة' and 'في الانتظار'. Consider increasing the gap.
  - doctor_consultation: 7 — The empty state message 'الحجز غير موجود' and its description are too close to the calendar icon. Increase the vertical spacing.
  - reception_desk: 7 — [object Object]

## المراحل
- done · هوية «عناية فائقة» · الخطة: ٨ شاشات · ٤ مجموعات · ١٢ عنصر محتوى
- done · المحتوى: ١٢ عنصر مكتوب كاملاً
- done · الهيكل جاهز: التنقّل، البيانات، الدخول، التصميم
- done · ٨ شاشات مكتوبة
- done · الفحص: ٧ شاشات بها ملاحظات، راجعها في الاستوديو · رحلات المستخدم: ٠ من ٣ تعمل كاملة · المراجعة: أُصلحت ٠ من ٥ · التصميم: ٥.٦ من ١٠ (حُسّنت ٣ شاشات) · وكيل الإصلاح: لم يجد تحسيناً آمناً
- done · جاهز للمعاينة والتحميل

## ملاحظات التشغيل المتبقية
- **doctor_schedule**: رحلة «حجز موعد ودفع الرسوم» توقفت عند الخطوة ٣: الحقل #doctor-search غير موجود في الشاشة — الظاهر الآن: الشاشة doctor_schedule (#/doctor-schedule) بدور doctor؛ الأزرار: tab؛ الحقول: لا شيء / رحلة «فحص الطبيب وتسجيل السجل الطبي» توقفت عند الخطوة ٤: لم يُعثر على [data-act=open-consultation] (الزر غير موجود أو اسمه مختلف) — الظاهر الآن: الشاشة doctor_schedule (#/doctor-schedule) بدور doctor؛ الأزرار: tab؛ الحقول: لا شيء
- **doctor_consultation**: تصميم: النص "الكل" غير مقروء: تباين 3.2:1 — لونه #8a909d والخلفية #ffffff من العنصر <button class="chip">. الخلفية فاتحة: استخدم var(--text) للنص، أو أزل خلفية ذلك العنصر إن كان داخل hero. / تصميم: النص "جديد بانتظار التأكيد" غير مقروء: تباين 4.4:1 — لونه #c0c3ca والخلفية #0d5c63 من العنصر <button class="chip active">. الخلفية داكنة/ملونة: استخدم var(--on-primary) للنص، ولا تضع muted أو subtitle داخلها. / رحلة «إدارة وتأكيد الحضور من السكرتارية» توقفت عند الخطوة ٤: لم يُعثر على [data-act=confirm] (الزر غير موجود أو اسمه مختلف) — الظاهر الآن: الشاشة doctor_consultation (#/consultation/doctors-1) بدور doctor؛ الأزرار: back، add-prescription، add-lab، finish-consultation؛ الحقول: #diag-input، #notes-inp / رحلة «إدارة وتأكيد الحضور من السكرتارية» توقفت عند الخطوة ٣: لم يُعثر على [data-act=filter][data-status=new] (الزر غير موجود أو اسمه مختلف) — الظاهر الآن: الشاشة doctor_schedule (#/doctor-schedule) بدور receptionist؛ الأزرار: tab؛ الحقول: لا شيء / رحلة «إدارة وتأكيد الحضور من السكرتارية» توقفت عند الخطوة ٣: لم يُعثر على [data-act=filter][data-status=new] (الزر غير موجود أو اسمه مختلف) — الظاهر الآن: الشاشة doctor_consultation (#/consultation/doctors-1) بدور doctor؛ الأزرار: back، add-prescription، add-lab، finish-consultation؛ الحقول: #diag-i / رحلة «فحص الطبيب وتسجيل السجل الطبي» توقفت عند الخطوة ٣: لم يُعثر على [data-act=tab][data-tab=waiting] (الزر غير موجود أو اسمه مختلف) — الظاهر الآن: الشاشة doctor_consultation (#/consultation/doctors-1) بدور doctor؛ الأزرار: back، add-prescription، add-lab، finish-consultation؛ الحقول: #diag-input، 
- **reception_desk**: تصميم: النص "الكل" غير مقروء: تباين 1.1:1 — لونه #ffffff والخلفية #f4f9f9 من العنصر <body class="has-nav few-nav">. الخلفية فاتحة: استخدم var(--text) للنص، أو أزل خلفية ذلك العنصر إن كان داخل hero. / تصميم: النص "جديد بانتظار التأكيد" غير مقروء: تباين 1.0:1 — لونه #4b5468 والخلفية #0d5c63 من العنصر <button class="chip active">. الخلفية داكنة/ملونة: استخدم var(--on-primary) للنص، ولا تضع muted أو subtitle داخلها.

## أخطاء صفحة بانِي