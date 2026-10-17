# نظام طلب المطعم الذكي — واجهة + خادم + قاعدة بيانات

نظام كامل لطلب الطعام من الطاولة عبر QR: **واجهة عميل**، **لوحة كاشير/إدارة**، و**خادم REST حقيقي**
مع قاعدة بيانات **SQLite** — كل ذلك بلا أي مكتبة خارجية أو CDN.

- **الواجهة:** `smart-restaurant.html` — ملف HTML واحد (HTML + CSS + Vanilla JS)، عربي بالكامل مع RTL صحيح
  واتجاه LTR للأرقام والأسعار والمصطلحات الإنجليزية.
- **الخادم:** مجلد `server/` — Node.js فقط (`node:http` + `node:sqlite` + `node:crypto`) بلا `npm install`.
- **قاعدة البيانات:** SQLite حقيقية على القرص مع ترحيلات (Migrations) وفهارس وقيود سلامة.

> **المتطلب الوحيد:** Node.js إصدار **24 أو أحدث** (`node --version`). لا npm ولا أي حزمة.

---

## 1) التشغيل السريع

```bash
# من جذر المشروع
npm start                 # أو: node server/server.js
```

ثم افتح: **http://localhost:8787/**

| الأمر | الوصف |
|---|---|
| `npm start` | تشغيل الخادم والواجهة على `http://localhost:8787/` |
| `npm run dev` | تشغيل مع إعادة التحميل التلقائي (`node --watch`) |
| `npm run reset` | إعادة بناء قاعدة البيانات من بيانات الديمو |
| `npm test` | تشغيل مجموعة اختبارات الـ API (بلا اعتماديات) |
| `npm run admin` | إنشاء/تعديل حساب مالك من سطر الأوامر |
| `npm run backup` | نسخة احتياطية من قاعدة البيانات |

على Windows: انقر مرتين على `start-server.cmd`. على Linux/macOS: `./start-server.sh`.

| العنوان | الوصف |
|---|---|
| `http://localhost:8787/` | الواجهة + الـ API من **نفس المصدر** (الجلسة كوكي HttpOnly بلا تعقيدات CORS) |
| `http://<IP-الشبكة>:8787/` | للهاتف عبر QR على نفس الشبكة المحلية |
| `http://localhost:8787/?local=1` | تشغيل الواجهة في وضع الديمو المحلي (localStorage) بلا خادم |
| `/api/health` | فحص صحة الخادم |

> عند تقديم الواجهة من الخادم يُضبط `srs.apiBase` تلقائيًا (مرة واحدة) فتتحوّل إلى `RestAdapter`.
> للعودة للوضع المحلي: `?local=1` أو أفرغ حقل `Base URL` في تبويب «التكامل / API».

---

## 2) المسارات

| المسار | الوصف |
|---|---|
| `#/` | صفحة الدخول (Landing): شعار + اسم + وصف مختصر + زرّان (عميل / إدارة) |
| `#/register` | تسجيل العميل (اسم + رقم جوال + رقم طاولة) — يقبل `?table=N` من رمز QR |
| `#/menu` | المنيو (تصنيفات، بحث، ترتيب، فتح صنف، إضافة للسلة) |
| `#/cart` | السلة (كميات، ملاحظات، كوبون/نقاط) |
| `#/checkout` | مراجعة الطلب والتأكيد |
| `#/success/:id` | نجاح الطلب + رقم الطلب + الوقت المتوقع |
| `#/track/:id` | تتبّع الطلب خطوة بخطوة |
| `#/profile` | ملف العميل (نقاط الولاء، المكافآت، سجل الطلبات) |
| `#/admin` و`#/admin/<tab>` | لوحة الكاشير/الإدارة (**10 تبويبات**) — محمية |

> **QR للطاولة:** يُمرَّر رقم الطاولة في الرابط (`?table=5#/register`) ويُتحقق منه مقابل جدول `tables`
> على الخادم قبل قبول الطلب. توليد صورة QR الفعلية يتم عبر خدمة طباعة/الخادم؛ داخل اللوحة أداة تحاكي ذلك للاختبار.

---

## 3) الحسابات وبيانات الديمو

**دخول لوحة الإدارة** (`#/admin`) — كلمة المرور لكل مستخدم = `اسم المستخدم + 123`:

| المستخدم | كلمة المرور | الدور | ملاحظات |
|---|---|---|---|
| `owner` | `owner123` | مالك | كل الصلاحيات (14) |
| `manager` | `manager123` | مدير | كل شيء عدا إدارة المالك |
| `cashier` | `cashier123` | كاشير | لا `settings.manage` |
| `kitchen` | `kitchen123` | مطبخ | لا `orders.cancel` |

> كلمات المرور في الخادم تُخزَّن مجزّأة بـ **scrypt**، والجلسة كوكي `HttpOnly`. حسابات `...123` أعلاه هي
> بيانات **الديمو** فقط؛ غيّرها قبل النشر (`npm run admin` / `npm run passwd`).

**عملاء ديمو** (أرقام قابلة للاستخدام في شاشة التسجيل/الدخول السريع):

- `+966500000001` خالد العبدالله — 30 نقطة
- `+966500000002` نورة السالم — 126 نقطة
- `+966500000003` محمد فهد — عميل جديد

**طلبات ديمو:** `ORD-1001`…`ORD-1004` بحالات متنوعة، والطلبات الجديدة تبدأ من `ORD-1005`.

---

## 4) نموذج البيانات

الكيانات: `Categories · Products · Tables · Customers · Orders · OrderItems · OrderStatusHistory ·
LoyaltyTransactions · Rewards · AdminUsers · RestaurantSettings`.

كل الكيانات لها معرّفات فريدة (`id`) — **لا تعتمد الهوية على الاسم إطلاقًا**.

- **Product:** `id, catId, name, emoji, price, desc, image, avail, popular, rating, prep, addons[{id,name,price}], sold, tags[]`
- **Customer:** `id, name, phone(فريد), pointsBalance, totalOrders, totalSpent, tags[], coupons[], createdAt`
- **Order:** `id, number(فريد), customerId, tableNumber, type, status, items[], subtotal, discount, tax, serviceFee, total, couponCode, estimatedMinutes, estimatedReadyAt, paymentMethod, notes, version, pointsAwarded, createdAt/updatedAt/deliveredAt, history[]`
- **LoyaltyTransaction:** `id, customerId, orderId, type(earn|redeem|adjust), points, rewardId, by, note, at`
- **RestaurantSettings:** `restaurantName, tagline, logoEmoji, phone, address, googleMapsUrl, currency, taxRate, serviceFeeRate, prepTimeDefault, prepTimeMax, tablesCount, openHours, accent, loyalty{...}`

### آلة حالات الطلب

```
pending → accepted → preparing → ready → delivered
   └────────────── cancelled (من أي حالة غير نهائية، مع سبب إلزامي) ──────────────┘
```

كل انتقال يُسجَّل في `OrderStatusHistory` مع المنفّذ والوقت، وحقل `version` يكشف تعارض التحديث المتزامن (`CONFLICT`).

### قواعد الولاء

- الصيغة قابلة للضبط: `perOrder` (نقاط ثابتة للطلب) أو `perCurrency` (نقاط لكل وحدة عملة قبل الضريبة).
- **النقاط تُمنح فقط بعد «تم التسليم»**، وقيد `UNIQUE(order_id, type)` يمنع الاحتساب المزدوج على مستوى قاعدة البيانات.
- حد أدنى للشراء (`minOrderForPoints`) وحد أدنى للاستبدال (`redeemThreshold`)، وكل حركة في سجل تدقيق.

---

## 5) مخطط قاعدة البيانات (SQLite)

المخطط الحقيقي في `server/db.js`:

```sql
categories(id PK, name, emoji, sort, active)
products(id PK, category_id, name, description, emoji, price REAL, image_url,
         prep_minutes, available, popular, rating, sold, tags_json)
product_addons(id, product_id, name, price REAL, sort, PK(product_id, id))
tables(id PK, number UNIQUE, area, seats, status, current_order_id)
customers(id PK, name, phone UNIQUE, points_balance, total_orders, total_spent,
          notes, tags_json, coupons_json, created_at)
orders(id PK, number UNIQUE, customer_id, table_number, status, type, subtotal, discount,
       tax, service_fee, total, coupon_code, estimated_minutes, estimated_ready_at,
       notes, version, source, points_awarded, cancel_reason,
       created_at, updated_at, accepted_at, ready_at, delivered_at, cancelled_at)
order_items(id PK, order_id, product_id, name, emoji, unit_price, qty, notes, line_total)
order_item_addons(id PK, order_item_id, addon_id, name, price)
order_status_history(id PK, order_id, status, note, by_user, at)
loyalty_transactions(id PK, customer_id, order_id, type, points, reward_id, note, by_user, at)
                     -- UNIQUE INDEX (order_id, type) WHERE order_id IS NOT NULL  يمنع منح النقاط مرتين
rewards(id PK, name, cost_points, type, value, product_id, active, description)
admin_users(id PK, name, username UNIQUE, password_hash, role, active, created_at)
settings(key PK, value_json)
audit_logs(id PK, level, area, message, meta_json, at)
counters(key PK, value)      -- عدّاد أرقام الطلبات المتسلسلة
sessions(token PK, admin_id, role, created_at, expires_at, user_agent, ip)
```

- **الترحيلات:** يُتتبَّع الإصدار في `PRAGMA user_version` وتُطبَّق مرة واحدة عند الإقلاع.
  الترحيل رقم ١ يحذف تلقائيًا أي مخلفات لتكامل واتساب من قواعد بيانات أقدم، والترحيل ٢ ينشئ الفهارس.
- **الوضع:** `journal_mode = WAL` و`foreign_keys = ON` و`busy_timeout = 5000` تلقائيًا.
- **الملف الافتراضي:** `server/data/restaurant.db`.

---

## 6) عقد الـ API (REST)

كل دالة واجهة لها مقابل في كائن `Api` بنفس التوقيع؛ وعند ضبط `CONFIG.apiBase` يتحوّل التطبيق تلقائيًا إلى `RestAdapter`.

| Method | Endpoint | الوظيفة | الحماية |
|---|---|---|---|
| `GET` | `/api/health` | صحة الخادم والإصدار | 🔓 |
| `GET` | `/api/settings` | إعدادات المطعم | 🔓 |
| `PATCH` | `/api/settings` | تعديل الإعدادات | 🧩 `settings.manage` |
| `GET/POST/PATCH/DELETE` | `/api/categories` · `/api/products` · `/api/tables` · `/api/rewards` | إدارة المنيو والطاولات والمكافآت | 🧩 حسب المورد |
| `POST` | `/api/uploads` | **رفع صورة صنف** (multipart) وإرجاع مسارها | 🧩 `menu.manage` |
| `DELETE` | `/api/uploads/:name` | حذف صورة مرفوعة | 🧩 `menu.manage` |
| `GET` | `/api/customers/by-phone?phone=` | جلب العميل برقم الجوال (هوية فريدة) | 🔓 |
| `POST/PATCH` | `/api/customers` | إنشاء/تعديل عميل | 🔓 / 🧩 |
| `POST` | `/api/orders` | إنشاء طلب + إعادة حساب السعر/الضريبة **على الخادم** | 🔓 |
| `GET` | `/api/orders?status=&customer=&since=` | قراءة الطلبات (تحديث لحظي) | 🔓 (قراءة إدارية 🧩) |
| `PATCH` | `/api/orders/:id/status` | تغيير الحالة (`{status, note, version}`) | 🔐 `orders.*` |
| `PATCH` | `/api/orders/:id/eta` | تعديل وقت التجهيز | 🔐 `orders.edit` |
| `POST` | `/api/loyalty/transactions` | تسجيل حركة نقاط | 🧩 `points.manage` |
| `POST` | `/api/loyalty/redeem` | استبدال مكافأة → كوبون | 🔓 |
| `POST` | `/api/loyalty/redeem-balance` | خصم كامل رصيد العميل وتصفيره مع سجل تدقيق | 🧩 `points.manage` |
| `POST` | `/api/auth/login` · `/api/auth/logout` · `GET /api/auth/me` | جلسة اللوحة | 🔓 |
| `PATCH` | `/api/auth/password` | تغيير كلمة مرور المستخدم الحالي بعد التحقق من الحالية | 🔐 |
| `GET/POST/PATCH/DELETE` | `/api/admin/users` | إدارة حسابات لوحة الإدارة | 🧩 `settings.manage` |
| `GET` | `/api/reports/summary` | ملخص المبيعات والأصناف الأكثر مبيعًا | 🧩 `reports.view` |
| `GET` | `/api/logs` | سجل الأحداث والأخطاء | 🧩 `logs.view` |

**صيغة الخطأ:** `{ "code": "...", "message": "..." }` مع رمز HTTP المناسب.

> **مهم:** التحقق النهائي من الأسعار والتوفّر والإضافات وحساب الضريبة يحدث **على الخادم دائمًا**؛
> أي `price` يُرسل من المتصفح **يُتجاهل** — وهذا يمنع التلاعب.

---

## 7) رفع صور الأصناف

في اللوحة: `إدارة المنيو > تعديل الصنف > صورة الصنف` يوجد **زر «رفع صورة»** (استُبدل حقل رابط الصورة بنظام رفع فعلي).

- نقطة النهاية: `POST /api/uploads` بجسم `multipart/form-data` وحقل `file` (أو `image`).
- تتطلب جلسة إدارية بصلاحية `menu.manage`.
- التحقق **بفحص البايتات السحرية (Magic Bytes)** لا بالامتداد: JPG · PNG · WEBP · GIF · AVIF/HEIC فقط
  (SVG مرفوض عمدًا لخطر XSS)، مع حدّ حجم `MAX_UPLOAD_MB` (افتراضي ٥ م.ب).
- تُخزَّن بأسماء عشوائية غير قابلة للتخمين وتُقدَّم من `/uploads/<file>` مع `Cache-Control: immutable`.
- الاستجابة: `{ url, name, mime, bytes }`، ويُحفظ `url` النسبي في حقل `image` للصنف، وتُعرض الصورة
  عبر `assetUrl()` التي تُحلّ المسارات النسبية مقابل `CONFIG.apiBase`.
- عند استبدال صورة صنف أو حذفه يُحذف الملف القديم تلقائيًا.
- في وضع الديمو بلا خادم يُستخدم Data URL محليًا حتى تعمل المعاينة بلا فقدان أي ميزة.
- **الصيغة الوحيدة المرفوضة عمدًا:** SVG (خطر XSS).

---

## 8) الإعدادات (Environment)

انسخ `server/.env.example` إلى `server/.env` وعدّل ما تحتاجه (يُقرأ تلقائيًا، ومتغيّرات البيئة تتقدّم على الملف):

| المتغير | الافتراضي | الوصف |
|---|---|---|
| `PORT` | `8787` | منفذ الخادم |
| `HOST` | `0.0.0.0` | عنوان الاستماع |
| `ALLOWED_ORIGINS` | — | مصادر إضافية مسموحة (مفصولة بفواصل) |
| `TRUST_PROXY` | `0` | `1` خلف وكيل عكسي لقراءة IP الحقيقي |
| `COOKIE_SECURE` | `0` | `1` عند HTTPS لتفعيل `Secure` على الكوكي |
| `CSP` | — | سياسة أمان المحتوى (يُنصح بها عند النشر العام) |
| `DATA_DIR` | `server/data` | مجلد قاعدة البيانات |
| `DB_FILE` | `<DATA_DIR>/restaurant.db` | مسار قاعدة البيانات |
| `UPLOAD_DIR` | `<DATA_DIR>/uploads` | مجلد صور الأصناف |
| `MAX_JSON_BODY_MB` | `2` | أقصى حجم لجسم JSON (م.ب) |
| `MAX_UPLOAD_MB` | `5` | أقصى حجم لصورة مرفوعة (م.ب) |
| `RATE_LIMIT_PER_MIN` | `600` | أقصى عدد طلبات لكل IP في الدقيقة |
| `LOGIN_LIMIT_PER_5MIN` | `12` | أقصى محاولات دخول لكل IP في 5 دقائق |
| `SEED_DEMO` | `1` | تعبئة بيانات الديمو عند أول تشغيل (`0` للإنتاج) |
| `ADMIN_USERNAME` / `ADMIN_PASSWORD` | `owner` / `owner123` | حساب المالك الأول (غيّره!) |
| `LOG_LEVEL` | `info` | مستوى التسجيل |

---

## 9) النشر

### أ) تشغيل مباشر
```bash
npm start                 # Node 24+ فقط، بلا npm install
```

### ب) Docker
```bash
docker compose up -d --build
```
- البيانات (قاعدة البيانات + الصور) محفوظة في حجم Docker دائم `restaurant-data`.
- في `docker-compose.yml` يُضبط `SEED_DEMO=0` و`ADMIN_USERNAME/ADMIN_PASSWORD` للتهيئة الأولى.
- **غيّر `ADMIN_PASSWORD` قبل أول تشغيل.**

### ج) تهيئة الإنتاج والنسخ الاحتياطي
```bash
node server/cli.js admin owner "كلمة-مرور-قوية" owner "مالك المطعم"   # إنشاء المالك
node server/cli.js passwd owner "كلمة-جديدة"                          # تغيير كلمة المرور
node server/cli.js backup                                             # نسخة احتياطية من القاعدة
node server/cli.js list                                               # عرض المستخدمين
```

### د) مثال Nginx (وكيل عكسي + HTTPS)
```nginx
server {
  listen 443 ssl;
  server_name restaurant.example.com;
  # ssl_certificate ...
  client_max_body_size 6m;          # أكبر من MAX_UPLOAD_MB قليلًا
  location / {
    proxy_pass http://127.0.0.1:8787;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```
ثم اضبط `TRUST_PROXY=1` و`COOKIE_SECURE=1` و`CSP` في `.env`.

---

## 10) الأمان

- **حدّ المعدّل:** لكل IP (`RATE_LIMIT_PER_MIN`) وحدّ خاص بمحاولات الدخول (`LOGIN_LIMIT_PER_5MIN`).
- **ترويسات أمنية:** `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `CSP` (اختياري).
- **المصادقة:** كلمات المرور مجزّأة بـ scrypt، والجلسة كوكي `HttpOnly` + `SameSite=Lax` (لا توكن في المتصفح).
- **RBAC:** كل مسار إداري يتطلب صلاحية محددة (`menu.manage`, `orders.*`, `settings.manage`, …).
- **التحقق من المدخلات:** نوع الملف وحجمه على الخادم، ومنع التلاعب بالأسعار، ومنع Path Traversal في `/uploads`.
- **قاعدة البيانات:** قيود `UNIQUE` و`foreign_keys` وقيد منع النقاط المزدوجة على مستوى القاعدة.

---

## 11) التصميم وإمكانية الوصول

- هوية **Premium Light** (خلفية عاجية + زيتوني `#52734D` + كراميل `#D9A15B`) قابلة للتغيير عبر متغيّرات CSS
  وإعداد `accent` (gold/emerald/ocean/rose).
- واجهة عميل **Mobile-first** ولوحة إدارة **Desktop-first**، بلا تمرير أفقي من 320px إلى 1440px.
- احترام `prefers-reduced-motion`، حالات تحميل/فراغ/خطأ/نجاح، أزرار كبيرة، تباين AA/AAA، ودعم لوحة المفاتيح و`aria`.
- خطوط النظام فقط (بلا خطوط أو أيقونات خارجية).

---

## 12) التحقق والاختبار

```bash
npm test        # أو: node server/test/api.test.js
```
مجموعة اختبارات **بلا أي مكتبة** تُشغّل الخادم الحقيقي على منفذ عشوائي ومجلد بيانات مؤقت، وتغطي:
الصحة، المصادقة والجلسات، RBAC لكل دور، المنيو والمنيو الإداري، رفع الصور (401/415/422/201 + تقديم مطابق
بايت-بالبايت + Traversal)، الملف الشخصي، دورة الطلب الكاملة (pending→delivered والنقاط مرة واحدة)،
الكوبونات، التقارير، السجلات، الإعدادات، الترويسات الأمنية، وحدّ المعدّل (429).

- **فحص صياغة JavaScript** للواجهة عبر `vm.Script`: سليم.
- **التحقق من عدم وجود أي أثر لواتساب** (رموز/مسارات/حقول قاعدة بيانات/رسائل): صفر.
- **تشغيل الواجهة على الخادم فعليًا:** تسجيل عميل → إضافة أصناف → دفع → طلب على الخادم، ورفع صورة صنف،
  ثم دخول اللوحة وتغيير الحالات حتى التسليم ومنح النقاط — بلا أخطاء JavaScript.

---

## 12.5) إزالة واتساب نهائيًا (سجل القرار)

حُذف تكامل واتساب **بالكامل** من الطبقات الثلاث: الواجهة (واجهة الرسائل، القوالب، الموافقة، تبويب السجل،
معرّفات الصلاحيات والرسائل)، والخادم (المسارات والويب هوك والوحدة `whatsapp.js`)، وقاعدة البيانات
(جدول `whatsapp_messages` وأعمدة الموافقة). الترحيل رقم ١ في `server/db.js` يحذفها تلقائيًا من أي قاعدة أقدم.
اعتماد الهوية على **رقم الجوال** فقط، والتواصل مع العميل يظهر عبر شاشة متابعة الطلب.

---

## 13) ملاحظة حول `index.html`

يوجد في المجلد ملف `index.html` منفصل أُنشئ بواسطة عملية أخرى متوازية. لتفادي الكتابة فوق عمل غير مكتمل،
سُمّي تسليم هذا المشروع `smart-restaurant.html`. إن أردت اعتباره الصفحة الرئيسية، انسخه فوق `index.html`
بعد التأكد من أن العمل الآخر لم يعد مطلوبًا. (الخادم يقدّم `smart-restaurant.html` تلقائيًا على `/`.)

---

## 14) البنية

```
.
├─ smart-restaurant.html     الواجهة كاملة (HTML + CSS + JS في ملف واحد)
├─ server/
│  ├─ server.js              خادم HTTP: التوجيه، الترويسات الأمنية، حدّ المعدّل، الكوكيز، تقديم الواجهة والصور
│  ├─ api.js                 جدول المسارات + RBAC + استجابات الأخطاء الموحّدة
│  ├─ repo.js                قواعد العمل: الأسعار، الضريبة، حالات الطلب، الولاء، الكوبونات
│  ├─ db.js                  مخطط SQLite + الترحيلات + الفهارس + تحويل الصفوف
│  ├─ config.js              الإعدادات المركزية + تحميل .env
│  ├─ uploads.js             رفع الصور: تحليل multipart + فحص البايتات السحرية + التخزين الآمن
│  ├─ auth.js                scrypt + الجلسات + خريطة الصلاحيات
│  ├─ seed.js                بيانات الديمو
│  ├─ cli.js                 أدوات: admin / passwd / list / seed / backup / info
│  ├─ test/api.test.js       اختبار تكامل شامل (بلا اعتماديات)
│  ├─ README.md              دليل الباكند التفصيلي
│  └─ .env.example           قالب الإعدادات
├─ package.json              scripts التشغيل/الاختبار/النسخ الاحتياطي
├─ Dockerfile · docker-compose.yml
├─ start-server.cmd · start-server.sh
└─ README.md                 هذا الملف
```

للتفاصيل الكاملة للخادم (المسارات، الأمان، الترحيلات): راجع `server/README.md`.
