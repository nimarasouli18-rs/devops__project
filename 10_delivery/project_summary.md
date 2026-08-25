# خلاصه نهایی پروژه

## ۱. معرفی پروژه

این پروژه با هدف طراحی و پیاده‌سازی یک فرآیند کامل برای استقرار خودکار یک Web Application چندسرویسی انجام شد. اپلیکیشن مرجع از Repository رسمی `docker/awesome-compose` و نمونه `nginx-flask-mysql` انتخاب شد و سپس برای تطبیق با الزامات پروژه، Dockerfile، Docker Compose، Nginx، SSL/TLS و Playbookهای Ansible آن توسعه داده شدند.

معماری نهایی شامل اجزای زیر است:

- AlmaLinux به‌عنوان Ansible Controller
- Ubuntu 22.04.5 LTS به‌عنوان سرور مقصد
- Nginx Container به‌عنوان Reverse Proxy
- Flask و Gunicorn به‌عنوان Backend
- MariaDB به‌عنوان Database
- Docker Compose برای مدیریت سرویس‌ها
- Ansible برای آماده‌سازی و استقرار خودکار
- Self-Signed Certificate برای فعال‌سازی HTTPS آزمایشی

## ۲. اهداف محقق‌شده

در طول پروژه موارد زیر پیاده‌سازی شدند:

- جمع‌آوری و مستندسازی اطلاعات سرور مقصد
- نصب و پیکربندی Ansible روی AlmaLinux Controller
- تعریف Inventory و تست ارتباط با Ubuntu
- آماده‌سازی خودکار Ubuntu با Ansible
- نصب Docker Engine و Docker Compose Plugin
- پیکربندی UFW برای پورت‌های `22`، `80` و `443`
- انتخاب و تحلیل پروژه مناسب از GitHub
- طراحی Dockerfile چندمرحله‌ای
- اجرای Backend با Gunicorn و کاربر Non-root
- طراحی Docker Compose شامل Backend، Database و Reverse Proxy
- تعریف Health Check برای تمام سرویس‌ها
- تعریف Named Volume برای Persistence دیتابیس
- استفاده از Networkهای جداگانه `frontnet` و `backnet`
- مدیریت Password دیتابیس با Docker Secret
- تنظیم Nginx به‌صورت Container
- پیکربندی Forwarded Headerها و Error Handling
- فعال‌سازی Domain آزمایشی `myapp.test`
- ایجاد Self-Signed Certificate دارای SAN
- Redirect کردن HTTP به HTTPS
- تبدیل مراحل Deployment به Automation واحد با Ansible
- ایجاد مستندات معماری، استقرار و رفع اشکال

## ۳. چالش‌های اصلی و راه‌حل‌ها

### ۳.۱. تداخل نسخه‌های Ansible

#### چالش

روی AlmaLinux یک نسخه قدیمی Ansible با Python 3.9 نصب بود. پس از نصب نسخه جدید با `pipx`، فرمان‌های موجود در `~/.local/bin` همچنان نسخه قدیمی را اجرا می‌کردند.

#### راه‌حل

- بررسی مستقیم محیط `pipx`
- حذف نسخه User-level قدیمی
- بازسازی Symlinkهای `pipx`
- پاک‌کردن Command Cache شِل
- تثبیت اجرای Ansible با Python 3.12

وضعیت نهایی:

```text
Ansible Community: 14.3.1
Ansible Core: 2.21.3
Python: 3.12.13
```

---

### ۳.۲. محدودیت Check Mode در Bootstrap اولیه

#### چالش

در اجرای اولیه Playbook با `--check`، تسک افزودن Repository داکر واقعاً اجرا نشد؛ بنابراین تسک بعدی نتوانست Package مربوط به `docker-ce` را پیدا کند.

#### راه‌حل

- استفاده از `--syntax-check` برای بررسی ساختار
- اجرای واقعی Bootstrap بدون `--check`
- استفاده مجدد از Check Mode پس از آماده‌شدن Repository و Packageها
- ثبت این محدودیت در Troubleshooting Guide

---

### ۳.۳. خطای YAML و Factهای Deprecated

#### چالش

پس از جایگزینی Factهای قدیمی با `ansible_facts`، یک خطای Indentation در YAML ایجاد شد. همچنین Ansible درباره `INJECT_FACTS_AS_VARS` هشدار می‌داد.

#### راه‌حل

- اصلاح Indentation
- ساده‌سازی Expression مربوط به Architecture
- استفاده از `ansible_facts["distribution"]` و `ansible_facts["architecture"]`
- غیرفعال‌کردن تزریق Factهای Top-level در `ansible.cfg`

---

### ۳.۴. دسترسی به Docker Socket روی Controller

#### چالش

فرمان‌های `docker compose pull` و `docker compose build` با خطای زیر متوقف شدند:

```text
permission denied while trying to connect to the docker API
```

#### راه‌حل

- اضافه‌کردن کاربر `naser` به گروه `docker`
- Logout و Login مجدد
- خودداری از تغییر ناامن Permission سوکت به `666`
- تست دسترسی با `docker info` و `docker ps`

---

### ۳.۵. دسترسی Backend به Docker Secret

#### چالش

Backend با UID/GID برابر `999` اجرا می‌شد، ولی فایل Secret با مالکیت و Permission متفاوت Mount شده بود. در نتیجه:

```text
Readable: False
```

و Backend در وضعیت `unhealthy` قرار گرفت.

#### راه‌حل

- تعریف UID و GID ثابت `10001` در Dockerfile
- Rebuild کامل Image بدون Cache
- تنظیم فایل Secret با مالکیت `root:10001`
- تنظیم Permission برابر `0640`
- Recreate کردن Containerهای Backend و Proxy
- تست دسترسی بدون نمایش محتوای Secret

نتیجه نهایی:

```text
Process UID: 10001
Process GID: 10001
File UID: 0
File GID: 10001
File mode: 0640
Readable: True
```

پس از اصلاح، هر سه سرویس در وضعیت Healthy قرار گرفتند و Nginx پاسخ `200 OK` برگرداند.

---

### ۳.۶. تطبیق Nginx کانتینری با الزامات Host-based

#### چالش

شرح مسئله بر مبنای نصب Nginx روی Host و استفاده از مسیرهای زیر نوشته شده بود:

```text
/etc/nginx/sites-available
/etc/nginx/sites-enabled
systemctl reload nginx
```

اما معماری پروژه Nginx را داخل Container اجرا می‌کرد.

#### راه‌حل

- عدم نصب Nginx دوم روی Ubuntu Host
- نگهداری Configuration روی Host در مسیر Deployment
- Mount کردن Configuration داخل Container
- اجرای `nginx -t` داخل Container
- استفاده از Recreate یا `nginx -s reload`
- مستندسازی معادل Container-based برای تمام الزامات
- پیاده‌سازی ساختار `sites-available` و `sites-enabled` در مسیر پروژه در مرحله Automation

---

### ۳.۷. SSL/TLS آزمایشی

#### چالش

برای Domain داخلی `myapp.test` امکان دریافت Certificate عمومی وجود نداشت و Browser نیز به Certificate خودامضا اعتماد نمی‌کرد.

#### راه‌حل

- تولید RSA Private Key
- تولید CSR
- تولید Self-Signed Certificate
- افزودن SAN برای Domain و IP
- تنظیم Permission کلید خصوصی روی `0600`
- فعال‌سازی TLS 1.2 و TLS 1.3
- استفاده از `curl -k` فقط در محیط Lab
- عدم فعال‌سازی HSTS در محیط Self-Signed

---

### ۳.۸. خطای Image Metadata در Docker Compose

#### چالش

در آخرین اجرای ثبت‌شده Automation، اعتبارسنجی Compose موفق بود، ولی ماژول `community.docker.docker_compose_v2` هنگام اجرای داخلی `docker compose images --format json` با خطای زیر متوقف شد:

```text
No such image: sha256:...
```

در همان زمان، Logهای موجود نشان می‌دادند Backend پاسخ `200` می‌دهد و MariaDB در وضعیت `ready for connections` قرار دارد. بنابراین شکست مربوط به Metadata یک Image قدیمی بود، نه خرابی Application.

#### راه‌حل تعریف‌شده

- ارتقای Docker Compose Plugin روی Ubuntu به نسخه `5.5.0` یا جدیدتر
- اضافه‌کردن کنترل نسخه Compose به Playbook
- حذف Containerهای قدیمی با `docker compose down --remove-orphans`
- خودداری از حذف Named Volume دیتابیس
- Recreate کردن Stack
- بهبود Rescue Block برای نمایش خطای اصلی

#### اقدام نهایی پیش از Tag

قبل از ایجاد Tag نهایی باید `site.yml` دوباره اجرا شود و نتیجه زیر ثبت گردد:

```text
unreachable=0
failed=0
Overall automation verification: PASSED
```

---

## ۴. راه‌حل‌های معماری پیاده‌سازی‌شده

### ۴.۱. جداسازی Networkها

```text
frontnet:
  proxy <--> backend

backnet:
  backend <--> db
```

Database مستقیماً در دسترس Nginx یا Host قرار نگرفت.

### ۴.۲. Persistence

داده‌های MariaDB داخل Named Volume ذخیره شدند تا Recreate شدن Container باعث حذف اطلاعات نشود.

### ۴.۳. Secret Management

Password دیتابیس:

- داخل Git قرار نگرفت.
- داخل Docker Image کپی نشد.
- در `.env` نگهداری نشد.
- با Permission محدود روی Host نگهداری شد.
- فقط در اختیار سرویس‌های لازم قرار گرفت.

### ۴.۴. Health Check و Startup Order

ترتیب اجرا:

```text
MariaDB Healthy
      ↓
Backend Healthy
      ↓
Nginx Healthy
```

### ۴.۵. امنیت Backend

Backend:

- با کاربر Non-root اجرا شد.
- UID/GID ثابت داشت.
- فقط روی Network داخلی در دسترس بود.
- Logها را به stdout و stderr ارسال کرد.
- با Gunicorn به‌جای Flask Development Server اجرا شد.

## ۵. درس‌های آموخته‌شده

1. Controller و Target باید از ابتدا نقش‌های کاملاً مشخص داشته باشند.
2. نصب بودن CLI داکر به معنی داشتن Permission برای Docker daemon نیست.
3. Check Mode برای Bootstrapهای زنجیره‌ای محدودیت دارد.
4. File-based Secret در Compose به Permission و UID/GID فایل Host وابسته است.
5. UID/GID داخل Container باید قابل پیش‌بینی و ثابت باشد.
6. Health Check باید علاوه بر وضعیت Process، مسیر واقعی Application را بررسی کند.
7. Named Volume باید هنگام Troubleshooting از Container Lifecycle جدا در نظر گرفته شود.
8. Warningهای MariaDB مانند fallback از `io_uring` همیشه به معنی Failure نیستند.
9. Nginx کانتینری باید با ابزارهای Docker مدیریت شود، نه `systemctl`.
10. خروجی عمومی Rescue Block برای عیب‌یابی کافی نیست و باید خطای اصلی ثبت شود.
11. نسخه Docker Compose می‌تواند روی رفتار ماژول‌های Ansible اثر مستقیم داشته باشد.
12. Secret، Certificate و فایل Environment باید از Git و Build Context خارج باشند.
13. استفاده از `set -o pipefail` هنگام ثبت خروجی با `tee` ضروری است.
14. مستندسازی باید هم معماری ایده‌آل و هم مشکلات واقعی مشاهده‌شده را پوشش دهد.

## ۶. بهبودهای پیشنهادی

### ۶.۱. Health Endpoint مستقل

Route زیر به Backend اضافه شود:

```text
/health
```

این Route نباید داده‌ای در Database تغییر دهد.

### ۶.۲. Certificate معتبر

در Production از یکی از موارد زیر استفاده شود:

- Let's Encrypt
- CA سازمانی
- Certificate عمومی معتبر

### ۶.۳. Ansible Vault

Passwordها و اطلاعات حساس Automation با Ansible Vault مدیریت شوند.

### ۶.۴. Container Registry

Backend در CI Build و به Registry Push شود. Target فقط Image را Pull کند.

### ۶.۵. CI/CD

Pipeline شامل مراحل زیر اضافه شود:

```text
Lint
Test
Build
Security Scan
Push Image
Deploy
Verify
Rollback
```

### ۶.۶. Role-based Ansible Structure

Playbookها به Roleهای زیر تبدیل شوند:

```text
docker
application
database
nginx
ssl
verification
```

### ۶.۷. تست خودکار Ansible

از ابزارهایی مانند Molecule برای تست Roleها استفاده شود.

### ۶.۸. Backup دیتابیس

Backup زمان‌بندی‌شده MariaDB و تست Restore اضافه شود.

### ۶.۹. Monitoring و Logging

موارد زیر اضافه شوند:

- Prometheus
- Grafana
- Loki یا ELK
- Alerting
- Docker Metrics

### ۶.۱۰. Hardening بیشتر

- Read-only Root Filesystem
- Capability Drop
- Resource Limit
- Seccomp/AppArmor
- Image Vulnerability Scan
- Pin کردن Image Digestها

## ۷. وضعیت نهایی تحویل

موارد تأییدشده:

- Build محلی Backend موفق
- اجرای محلی سه سرویس موفق
- وضعیت Healthy برای Database، Backend و Proxy
- پاسخ HTTP برابر `200 OK`
- خواندن امن Docker Secret توسط Backend
- Reverse Proxy فعال
- طراحی و مستندسازی HTTPS
- Playbookهای Automation و Verification ایجادشده
- مستندات کامل پروژه ایجادشده

موردی که باید پیش از Tag نهایی دوباره تأیید شود:

- اجرای مجدد `08_ansible_automation/site.yml` پس از اصلاح/ارتقای Docker Compose
- ثبت `failed=0`
- تولید نهایی `playbook_output.txt` و `verification.txt`

## ۸. جمع‌بندی

پروژه از یک نمونه ساده Docker Compose به یک سناریوی کامل DevOps تبدیل شد که شامل Infrastructure Preparation، Containerization، Reverse Proxy، Persistence، Secret Management، HTTPS، Automation و Documentation است.

مهم‌ترین دستاورد پروژه، صرفاً اجرای Application نبود؛ بلکه ایجاد یک فرآیند قابل‌تکرار، قابل‌بررسی و مستند برای استقرار آن بود.
