# تقرير الاختبار الحقيقي لبانِي

- التطبيق: **عيادتي التخصصية**
- النتيجة: **ready** 
- الزمن: 9.5 دقيقة
- رحلات مختبرة: حجز موعد والدفع (9 خطوات)، تأكيد الحضور (5 خطوات)، كتابة التشخيص (10 خطوات)
- المراجعة الشاملة: وُجدت 2 وأُصلحت 2
- **التصميم: 6.5 / 10** (أضعف شاشة 6)
  - appointments: 7 — The spacing between the tab bar items and the content above could be improved for better rhythm.
  - medicalRecords: 6 — مشاكل حرجة في اتجاه RTL في شريط العنوان: عنوان الصفحة "السجل الطبي" محاذٍ لليسار، بينما يجب أن يكون محاذياً لليمين أو في المنتصف لتطبيق RTL صحيح. زر الرجوع (->) موجود على اليمين ويشير إلى الأمام، بينما يجب أن يكون على اليسار ويشير إلى الخلف (<-) في سياق RTL. كيف يُصلح: يجب محاذاة عنوان الصفحة لليمين أو المنتصف. يجب نقل زر الرجوع إلى اليسار وتغيير الأيقونة لتشير إلى الخلف (<-).

## المراحل
- done · هوية «عناية ورعاية» · الخطة: ٩ شاشات · ٤ مجموعات · ٦ عنصر محتوى
- done · المحتوى: ٦ عنصر مكتوب كاملاً
- done · الهيكل جاهز: التنقّل، البيانات، الدخول، التصميم
- done · ٩ شاشات مكتوبة
- done · الفحص: ٦ شاشات بها ملاحظات، راجعها في الاستوديو · رحلات المستخدم: ٠ من ٣ تعمل كاملة · المراجعة: أُصلحت ٢ من ٢ · التصميم: ٥.٩ من ١٠ (حُسّنت ٢ شاشات) · وكيل الإصلاح: لم يجد تحسيناً آمناً
- done · جاهز للمعاينة والتحميل

## ملاحظات التشغيل المتبقية
- **doctor**: تصميم: صورة لا تُحمَّل: https://images.unsplash.com/photo-1594824813572-2d0a0f02787e. استخدم صورة من بيانات التطبيق أو أيقونة بديلة. / رحلة «حجز موعد والدفع» توقفت عند الخطوة ٣: لم يُعثر على [data-act=view-provider][data-id=providers-1] (الزر غير موجود أو اسمه مختلف) — الظاهر الآن: الشاشة notifications (#/notifications) بدور patient؛ الأزرار: go-notice؛ الحقول: لا شيء / رحلة «حجز موعد والدفع» توقفت عند الخطوة ٣: لم يُعثر على [data-act=view-provider][data-id=providers-1] (الزر غير موجود أو اسمه مختلف) — الظاهر الآن: الشاشة doctor (#/doctor/providers-1) بدور secretary؛ الأزرار: back؛ الحقول: #patient-phone، #patient-reason / رحلة «تأكيد الحضور» توقفت عند الخطوة ٣: لم يُعثر على text:تأكيد الحجز (الزر غير موجود أو اسمه مختلف) — الظاهر الآن: الشاشة doctor (#/doctor/providers-1) بدور patient؛ الأزرار: back؛ الحقول: #patient-phone، #patient-reason / رحلة «تأكيد الحضور» توقفت عند الخطوة ٣: لم يُعثر على text:تأكيد الحجز (الزر غير موجود أو اسمه مختلف) — الظاهر الآن: الشاشة doctor (#/doctor/providers-1) بدور secretary؛ الأزرار: back؛ الحقول: #patient-phone، #patient-reason / رحلة «كتابة التشخيص» توقفت عند الخطوة ٣: لم يُعثر على [data-act=visit][data-id=providers-1] (الزر غير موجود أو اسمه مختلف) — الظاهر الآن: الشاشة doctor (#/doctor/providers-1) بدور patient؛ الأزرار: back؛ الحقول: #patient-phone، #patient-reason
- **appointments**: تصميم: صورة لا تُحمَّل: https://images.unsplash.com/photo-1594824813572-2d0a0f02787e. استخدم صورة من بيانات التطبيق أو أيقونة بديلة.
- **visit**: رحلة «كتابة التشخيص» توقفت عند الخطوة ٣: لم يُعثر على [data-act=visit][data-id=providers-1] (الزر غير موجود أو اسمه مختلف) — الظاهر الآن: الشاشة visit (#/visit/providers-1) بدور doctor؛ الأزرار: لا شيء؛ الحقول: لا شيء

## أخطاء صفحة بانِي
- Failed to execute 'closest' on 'Element': '() => checkFormValidity()' is not a valid selector. @     at HTMLInputElement.<anonymous> (about:srcdoc:1180:94)
- Failed to execute 'closest' on 'Element': '() => checkFormValidity()' is not a valid selector. @     at HTMLInputElement.<anonymous> (about:srcdoc:1180:94)
- Failed to execute 'closest' on 'Element': '() => checkFormValidity()' is not a valid selector. @     at HTMLInputElement.<anonymous> (about:srcdoc:1180:94)
- Failed to execute 'closest' on 'Element': '() => checkFormValidity()' is not a valid selector. @     at HTMLInputElement.<anonymous> (about:srcdoc:1180:94)
- Failed to execute 'closest' on 'Element': '() => checkFormValidity()' is not a valid selector. @     at HTMLInputElement.<anonymous> (about:srcdoc:1180:94)
- Failed to execute 'closest' on 'Element': '() => {
          checkFormValidity();
        }' is not a valid selector. @           checkFormValidity(); |         }' is not a valid selector.
- Failed to execute 'closest' on 'Element': '() => checkFormValidity()' is not a valid selector. @     at HTMLInputElement.<anonymous> (about:srcdoc:1180:94)
- Failed to execute 'closest' on 'Element': '() => checkFormValidity()' is not a valid selector. @     at HTMLInputElement.<anonymous> (about:srcdoc:1180:94)
- Failed to execute 'closest' on 'Element': '() => {
          checkFormValidity();
        }' is not a valid selector. @           checkFormValidity(); |         }' is not a valid selector.
- Failed to execute 'closest' on 'Element': '() => checkFormValidity()' is not a valid selector. @     at HTMLInputElement.<anonymous> (about:srcdoc:1180:94)
- Failed to execute 'closest' on 'Element': '() => checkFormValidity()' is not a valid selector. @     at HTMLInputElement.<anonymous> (about:srcdoc:1180:94)
- Failed to execute 'closest' on 'Element': '() => checkFormValidity()' is not a valid selector. @     at HTMLInputElement.<anonymous> (about:srcdoc:1180:94)