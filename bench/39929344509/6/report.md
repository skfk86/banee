# تقرير الاختبار الحقيقي لبانِي

- التطبيق: **مذاق فاخر**
- النتيجة: **ready** 
- الزمن: 3.6 دقيقة
- رحلات مختبرة: حجز وطلب مسبق (13 خطوات)
- المراجعة الشاملة: وُجدت 1 وأُصلحت 1
- **التصميم: null / 10** (أضعف شاشة null)

## المراحل
- done · هوية «ذوق فاخر» · الخطة: ٥ شاشات · ٥ مجموعات · ٢٠ عنصر محتوى
- done · المحتوى: ٢٠ عنصر مكتوب كاملاً
- done · الهيكل جاهز: التنقّل، البيانات، الدخول، التصميم
- done · ٥ شاشات مكتوبة
- done · جُرّبت كل الشاشات وأُصلحت ٣، لا أخطاء · رحلات المستخدم: ١ من ١ تعمل كاملة · المراجعة: أُصلحت ١ من ١ · التصميم: ٥ من ١٠ (حُسّنت ٣ شاشات)
- done · جاهز للمعاينة والتحميل

## ملاحظات التشغيل المتبقية

## أخطاء صفحة بانِي
- Failed to execute 'closest' on 'Element': 'async (e) => {
          e.preventDefault();
          const form = e.target;
          const userName = form.userName.value.trim();
          const phone = form.phone.value.trim();
          const guests = parseInt(form.guests.value) || 2;
          const occasion = form.occasion.value.trim();
          const date = form.date.value;
          const time = form.time.value;
    
          if (!userName || !phone || !date || !time) {
            UI.toast('يرجى تعبئة كافة الحقول الإجبارية', 'error');
            return;
          }
    
          const cart = Store.get('cart', { items: [], total: 0 });
          const btn = form.querySelector('button[type=submit]');
          UI.busy(btn, true);
    
          try {
            await Data.bookings.create({
              userId: Auth.user.uid,
              userName: userName,
              phone: phone,
              guests: guests,
              date: date,
              time: time,
              occasion: occasion,
              tableId: selectedTableId || '',
              hostId: '',
              status: 'new',
              items: cart.items,
              total: cart.total,
              order: Date.now()
            });
    
            // تفريغ السلة
            Store.set('cart', { items: [], total: 0 });
    
            UI.toast('تم تأكيد الحجز بنجاح!', 'success');
            App.go('/my-bookings');
          } catch (err) { try { (window.__caught = window.__caught || []).push(String(err && (err.message || err.code) || err).slice(0, 200)); if (window.__caught.length > 8) window.__caught.shift(); } catch (__e) {}
            console.error(err);
            UI.toast('حدث خطأ أثناء حفظ الحجز، حاول مرة أخرى', 'error');
          } finally {
            UI.busy(btn, false);
          }
        }' is not a valid selector. @           e.preventDefault(); |           const form = e.target;
- Failed to execute 'closest' on 'Element': 'async (e) => {
          e.preventDefault();
          const form = e.target;
          const userName = form.userName.value.trim();
          const phone = form.phone.value.trim();
          const guests = parseInt(form.guests.value) || 2;
          const occasion = form.occasion.value.trim();
          const date = form.date.value;
          const time = form.time.value;
    
          if (!userName || !phone || !date || !time) {
            UI.toast('يرجى تعبئة كافة الحقول الإجبارية', 'error');
            return;
          }
    
          const cart = Store.get('cart', { items: [], total: 0 });
          const btn = form.querySelector('button[type=submit]');
          UI.busy(btn, true);
    
          try {
            await Data.bookings.create({
              userId: Auth.user.uid,
              userName: userName,
              phone: phone,
              guests: guests,
              date: date,
              time: time,
              occasion: occasion,
              tableId: selectedTableId || '',
              hostId: '',
              status: 'new',
              items: cart.items,
              total: cart.total,
              order: Date.now()
            });
    
            Store.set('cart', { items: [], total: 0 });
    
            UI.toast('تم تأكيد الحجز بنجاح!', 'success');
            App.go('/my-bookings');
          } catch (err) { try { (window.__caught = window.__caught || []).push(String(err && (err.message || err.code) || err).slice(0, 200)); if (window.__caught.length > 8) window.__caught.shift(); } catch (__e) {}
            console.error(err);
            UI.toast('حدث خطأ أثناء حفظ الحجز، حاول مرة أخرى', 'error');
          } finally {
            UI.busy(btn, false);
          }
        }' is not a valid selector. @           e.preventDefault(); |           const form = e.target;
- Failed to execute 'closest' on 'Element': 'async (e) => {
          e.preventDefault();
          const form = e.target;
          const userName = form.userName.value.trim();
          const phone = form.phone.value.trim();
          const guests = parseInt(form.guests.value) || 2;
          const occasion = form.occasion.value.trim();
          const date = form.date.value;
          const time = form.time.value;
    
          if (!userName || !phone || !date || !time) {
            UI.toast('يرجى تعبئة كافة الحقول الإجبارية', 'error');
            return;
          }
    
          const cart = Store.get('cart', { items: [], total: 0 });
          const btn = form.querySelector('button[type=submit]');
          UI.busy(btn, true);
    
          try {
            await Data.bookings.create({
              userId: Auth.user.uid,
              userName: userName,
              phone: phone,
              guests: guests,
              date: date,
              time: time,
              occasion: occasion,
              tableId: selectedTableId || '',
              hostId: '',
              status: 'new',
              items: cart.items,
              total: cart.total,
              order: Date.now()
            });
    
            Store.set('cart', { items: [], total: 0 });
    
            UI.toast('تم تأكيد الحجز بنجاح!', 'success');
            App.go('/my-bookings');
          } catch (err) { try { (window.__caught = window.__caught || []).push(String(err && (err.message || err.code) || err).slice(0, 200)); if (window.__caught.length > 8) window.__caught.shift(); } catch (__e) {}
            console.error(err);
            UI.toast('حدث خطأ أثناء حفظ الحجز، حاول مرة أخرى', 'error');
          } finally {
            UI.busy(btn, false);
          }
        }' is not a valid selector. @           e.preventDefault(); |           const form = e.target;