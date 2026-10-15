# تقرير الاختبار الحقيقي لبانِي

- التطبيق: **مزرعتي للدواجن**
- النتيجة: **ready** 
- الزمن: 4.1 دقيقة
- رحلات مختبرة: تسجيل الإنتاج اليومي (7 خطوات)، إضافة تنبيه للمالك (7 خطوات)
- المراجعة الشاملة: وُجدت 0 وأُصلحت 0

## المراحل
- done · هوية «حصاد الريف» · الخطة: ٤ شاشات · ٣ مجموعات
- done · لا يحتاج التطبيق محتوى جاهزاً
- done · الهيكل جاهز: التنقّل، البيانات، الدخول، التصميم
- done · ٤ شاشات مكتوبة
- done · الفحص: ١ شاشات بها ملاحظات، راجعها في الاستوديو · رحلات المستخدم: ٢ من ٢ تعمل كاملة · المراجعة الشاملة: لا مشاكل · وكيل الإصلاح: أصلح ٤ في ٨ خطوة
- done · جاهز للمعاينة والتحميل

## ملاحظات التشغيل المتبقية

## أخطاء صفحة بانِي
- Failed to execute 'closest' on 'Element': '() => {
            const currentData = {
              eggProduction: form.querySelector('[name=eggProduction]').value,
              mortality: form.querySelector('[name=mortality]').value,
              feedConsumed: form.querySelector('[name=feedConsumed]').value,
              notes: form.querySelector('[name=notes]').value
            };
            Store.set('newRecord', currentData);
          }' is not a valid selector. @             const currentData = { |               eggProduction: form.querySelector('[name=eggProduction]').value,
- Failed to execute 'closest' on 'Element': '() => {
            const currentData = {
              eggProduction: form.querySelector('[name=eggProduction]').value,
              mortality: form.querySelector('[name=mortality]').value,
              feedConsumed: form.querySelector('[name=feedConsumed]').value,
              notes: form.querySelector('[name=notes]').value
            };
            Store.set('newRecord', currentData);
          }' is not a valid selector. @             const currentData = { |               eggProduction: form.querySelector('[name=eggProduction]').value,
- Failed to execute 'closest' on 'Element': '() => {
            const currentData = {
              eggProduction: form.querySelector('[name=eggProduction]').value,
              mortality: form.querySelector('[name=mortality]').value,
              feedConsumed: form.querySelector('[name=feedConsumed]').value,
              notes: form.querySelector('[name=notes]').value
            };
            Store.set('newRecord', currentData);
          }' is not a valid selector. @             const currentData = { |               eggProduction: form.querySelector('[name=eggProduction]').value,
- Failed to execute 'closest' on 'Element': '() => {
            const currentData = {
              eggProduction: form.querySelector('[name=eggProduction]').value,
              mortality: form.querySelector('[name=mortality]').value,
              feedConsumed: form.querySelector('[name=feedConsumed]').value,
              notes: form.querySelector('[name=notes]').value
            };
            Store.set('newRecord', currentData);
          }' is not a valid selector. @             const currentData = { |               eggProduction: form.querySelector('[name=eggProduction]').value,
- Failed to execute 'closest' on 'Element': 'async (e) => {
          e.preventDefault();
          const btn = el.querySelector('#save-btn');
          UI.busy(btn, true);
    
          try {
            const eggProduction = Number(form.querySelector('[name=eggProduction]').value) || 0;
            const mortality = Number(form.querySelector('[name=mortality]').value) || 0;
            const feedConsumed = Number(form.querySelector('[name=feedConsumed]').value) || 0;
            const notes = form.querySelector('[name=notes]').value.trim();
            const currentDate = new Date().toISOString().split('T')[0];
    
            await Data.records.create({
              userId: Auth.user.uid,
              workerName: Auth.user.name || 'عامل المزرعة',
              date: currentDate,
              eggProduction,
              mortality,
              feedConsumed,
              notes,
              order: Date.now()
            });
    
            Store.set('newRecord', { eggProduction: '', mortality: '', feedConsumed: '', notes: '' });
    
            UI.toast('تم حفظ التقرير اليومي بنجاح', 'success');
            App.go('/');
          } catch (err) { try { (window.__caught = window.__caught || []).push(String(err && (err.message || err.code) || err).slice(0, 200)); if (window.__caught.length > 8) window.__caught.shift(); } catch (__e) {}
            console.error(err);
            UI.toast('حدث خطأ أثناء حفظ التقرير، يجدر المحاولة مجدداً', 'error');
            UI.busy(btn, false);
          }
        }' is not a valid selector. @           e.preventDefault(); |           const btn = el.querySelector('#save-btn');
- Failed to execute 'closest' on 'Element': '() => {
            const currentData = {
              eggProduction: form.querySelector('[name=eggProduction]').value,
              mortality: form.querySelector('[name=mortality]').value,
              feedConsumed: form.querySelector('[name=feedConsumed]').value,
              notes: form.querySelector('[name=notes]').value
            };
            Store.set('newRecord', currentData);
          }' is not a valid selector. @             const currentData = { |               eggProduction: form.querySelector('[name=eggProduction]').value,
- Failed to execute 'closest' on 'Element': '() => {
            const currentData = {
              eggProduction: form.querySelector('[name=eggProduction]').value,
              mortality: form.querySelector('[name=mortality]').value,
              feedConsumed: form.querySelector('[name=feedConsumed]').value,
              notes: form.querySelector('[name=notes]').value
            };
            Store.set('newRecord', currentData);
          }' is not a valid selector. @             const currentData = { |               eggProduction: form.querySelector('[name=eggProduction]').value,
- Failed to execute 'closest' on 'Element': '() => {
            const currentData = {
              eggProduction: form.querySelector('[name=eggProduction]').value,
              mortality: form.querySelector('[name=mortality]').value,
              feedConsumed: form.querySelector('[name=feedConsumed]').value,
              notes: form.querySelector('[name=notes]').value
            };
            Store.set('newRecord', currentData);
          }' is not a valid selector. @             const currentData = { |               eggProduction: form.querySelector('[name=eggProduction]').value,
- Failed to execute 'closest' on 'Element': '() => {
            const currentData = {
              eggProduction: form.querySelector('[name=eggProduction]').value,
              mortality: form.querySelector('[name=mortality]').value,
              feedConsumed: form.querySelector('[name=feedConsumed]').value,
              notes: form.querySelector('[name=notes]').value
            };
            Store.set('newRecord', currentData);
          }' is not a valid selector. @             const currentData = { |               eggProduction: form.querySelector('[name=eggProduction]').value,
- Failed to execute 'closest' on 'Element': 'async (e) => {
          e.preventDefault();
          const btn = el.querySelector('#save-btn');
          UI.busy(btn, true);
    
          try {
            const eggProduction = Number(form.querySelector('[name=eggProduction]').value) || 0;
            const mortality = Number(form.querySelector('[name=mortality]').value) || 0;
            const feedConsumed = Number(form.querySelector('[name=feedConsumed]').value) || 0;
            const notes = form.querySelector('[name=notes]').value.trim();
            const currentDate = new Date().toISOString().split('T')[0];
    
            await Data.records.create({
              userId: Auth.user.uid,
              workerName: Auth.user.name || 'عامل المزرعة',
              date: currentDate,
              eggProduction,
              mortality,
              feedConsumed,
              notes,
              order: Date.now()
            });
    
            Store.set('newRecord', { eggProduction: '', mortality: '', feedConsumed: '', notes: '' });
    
            UI.toast('تم حفظ التقرير اليومي بنجاح', 'success');
            App.go('/');
          } catch (err) { try { (window.__caught = window.__caught || []).push(String(err && (err.message || err.code) || err).slice(0, 200)); if (window.__caught.length > 8) window.__caught.shift(); } catch (__e) {}
            console.error(err);
            UI.toast('حدث خطأ أثناء حفظ التقرير، يجدر المحاولة مجدداً', 'error');
            UI.busy(btn, false);
          }
        }' is not a valid selector. @           e.preventDefault(); |           const btn = el.querySelector('#save-btn');
- Failed to execute 'closest' on 'Element': '() => {
            const currentData = {
              eggProduction: form.querySelector('[name=eggProduction]').value,
              mortality: form.querySelector('[name=mortality]').value,
              feedConsumed: form.querySelector('[name=feedConsumed]').value,
              notes: form.querySelector('[name=notes]').value
            };
            Store.set('newRecord', currentData);
          }' is not a valid selector. @             const currentData = { |               eggProduction: form.querySelector('[name=eggProduction]').value,
- Failed to execute 'closest' on 'Element': '() => {
            const currentData = {
              eggProduction: form.querySelector('[name=eggProduction]').value,
              mortality: form.querySelector('[name=mortality]').value,
              feedConsumed: form.querySelector('[name=feedConsumed]').value,
              notes: form.querySelector('[name=notes]').value
            };
            Store.set('newRecord', currentData);
          }' is not a valid selector. @             const currentData = { |               eggProduction: form.querySelector('[name=eggProduction]').value,
- Failed to execute 'closest' on 'Element': '() => {
            const currentData = {
              eggProduction: form.querySelector('[name=eggProduction]').value,
              mortality: form.querySelector('[name=mortality]').value,
              feedConsumed: form.querySelector('[name=feedConsumed]').value,
              notes: form.querySelector('[name=notes]').value
            };
            Store.set('newRecord', currentData);
          }' is not a valid selector. @             const currentData = { |               eggProduction: form.querySelector('[name=eggProduction]').value,
- Failed to execute 'closest' on 'Element': 'async (e) => {
          e.preventDefault();
          const btn = el.querySelector('#save-btn');
          UI.busy(btn, true);
    
          try {
            const eggProduction = Number(form.querySelector('[name=eggProduction]').value) || 0;
            const mortality = Number(form.querySelector('[name=mortality]').value) || 0;
            const feedConsumed = Number(form.querySelector('[name=feedConsumed]').value) || 0;
            const notes = form.querySelector('[name=notes]').value.trim();
            const currentDate = new Date().toISOString().split('T')[0];
    
            await Data.records.create({
              userId: Auth.user.uid,
              workerName: Auth.user.name || 'عامل المزرعة',
              date: currentDate,
              eggProduction,
              mortality,
              feedConsumed,
              notes,
              order: Date.now()
            });
    
            Store.set('newRecord', { eggProduction: '', mortality: '', feedConsumed: '', notes: '' });
    
            UI.toast('تم حفظ التقرير اليومي بنجاح', 'success');
            App.go('/');
          } catch (err) { try { (window.__caught = window.__caught || []).push(String(err && (err.message || err.code) || err).slice(0, 200)); if (window.__caught.length > 8) window.__caught.shift(); } catch (__e) {}
            console.error(err);
            UI.toast('حدث خطأ أثناء حفظ التقرير، يجدر المحاولة مجدداً', 'error');
            UI.busy(btn, false);
          }
        }' is not a valid selector. @           e.preventDefault(); |           const btn = el.querySelector('#save-btn');
- Failed to execute 'closest' on 'Element': 'async (e) => {
          e.preventDefault();
          const btn = el.querySelector('#save-btn');
          UI.busy(btn, true);
    
          try {
            const eggProduction = Number(form.querySelector('[name=eggProduction]').value) || 0;
            const mortality = Number(form.querySelector('[name=mortality]').value) || 0;
            const feedConsumed = Number(form.querySelector('[name=feedConsumed]').value) || 0;
            const notes = form.querySelector('[name=notes]').value.trim();
            const currentDate = new Date().toISOString().split('T')[0];
    
            await Data.records.create({
              userId: Auth.user.uid,
              workerName: Auth.user.name || 'عامل المزرعة',
              date: currentDate,
              eggProduction,
              mortality,
              feedConsumed,
              notes,
              order: Date.now()
            });
    
            Store.set('newRecord', { eggProduction: '', mortality: '', feedConsumed: '', notes: '' });
    
            UI.toast('تم حفظ التقرير اليومي بنجاح', 'success');
            App.go('/');
          } catch (err) { try { (window.__caught = window.__caught || []).push(String(err && (err.message || err.code) || err).slice(0, 200)); if (window.__caught.length > 8) window.__caught.shift(); } catch (__e) {}
            console.error(err);
            UI.toast('حدث خطأ أثناء حفظ التقرير، يجدر المحاولة مجدداً', 'error');
            UI.busy(btn, false);
          }
        }' is not a valid selector. @           e.preventDefault(); |           const btn = el.querySelector('#save-btn');