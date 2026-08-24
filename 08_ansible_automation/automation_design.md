# طراحی خودکارسازی Deployment با Ansible

## ۱. هدف

هدف این مرحله تبدیل تمام عملیات دستی مراحل قبل به یک فرآیند تکرارپذیر و قابل‌استفاده مجدد است. اجرای فایل `site.yml` باید این نتیجه را ایجاد کند:

```text
AlmaLinux Ansible Controller
          |
          | SSH + Ansible
          v
Ubuntu Deployment Server
          |
          +-- Docker Compose
          |     +-- MariaDB
          |     +-- Flask Backend
          |     +-- Nginx Proxy
          |
          +-- Self-Signed TLS Certificate
          +-- HTTP to HTTPS Redirect
```

---

## ۲. عملیات قابل خودکارسازی

### آماده‌سازی فایل‌ها

- بررسی وجود فایل‌های Source روی Controller
- ایجاد Deployment Directory
- ایجاد پوشه‌های Application، Nginx، Secret و Certificate
- کپی Dockerfile
- کپی Application Code
- کپی فایل Dependencies
- تولید فایل `.env` از Template
- تولید فایل `docker-compose.yml` از Template

### مدیریت Secret

- ایجاد Password تصادفی MariaDB فقط در صورت نبودن فایل قبلی
- تنظیم مالکیت `root`
- تنظیم Group برابر GID مورد استفاده Backend Container
- تنظیم Permission برابر `0640`
- جلوگیری از ورود Certificateها و Secretها به Docker Build Context

### Docker Deployment

- Build کردن Backend Image
- Pull کردن MariaDB و Nginx Imageها
- اجرای MariaDB و Backend
- انتظار برای Healthy شدن سرویس‌ها
- اجرای Nginx Proxy
- ثبت و نمایش وضعیت Containerها

### Nginx و TLS

- ساخت Private Key
- ساخت CSR
- ساخت Self-Signed Certificate
- تولید Nginx Configuration از Jinja Template
- ایجاد ساختار `sites-available` و `sites-enabled` در Deployment Directory
- فعال‌سازی Site با Symbolic Link
- حذف Default Site
- تست Configuration
- Reload کردن Nginx داخل Container

### Verification

- بررسی Portهای ۸۰ و ۴۴۳
- بررسی وضعیت Containerها
- بررسی Nginx Configuration
- بررسی Certificate و Expiry Date
- تست Redirect از HTTP به HTTPS
- تست HTTPS روی Ubuntu
- تست از AlmaLinux Controller
- ذخیره نتیجه در `verification.txt`

---

## ۳. ترتیب اجرای Playbookها

ترتیب اجرای Automation:

1. `deploy_app.yml`
2. `deploy_nginx.yml`
3. `verify.yml`

این ترتیب در `site.yml` با `import_playbook` ثابت شده است.

### دلیل ترتیب

- ابتدا Directoryها، Source، Compose و Secret آماده می‌شوند.
- سپس Database و Backend Build و اجرا می‌شوند.
- پس از آماده‌شدن Backend، Certificate و Nginx Configuration ساخته می‌شوند.
- Nginx بعد از آماده‌شدن Backend و Certificate اجرا می‌شود.
- Verification در پایان کل Stack را بررسی می‌کند.

---

## ۴. Variables

### `app_vars.yml`

متغیرهای مربوط به:

- Deployment Path
- Deployment User و Group
- مسیر Source روی Controller
- Image Nameها
- Database Name
- Portها
- Docker Compose Timeout
- Secret Group و GID

### `nginx_vars.yml`

متغیرهای مربوط به:

- Domain
- IP سرور
- نام Site
- مسیرهای `sites-available` و `sites-enabled`
- مسیر Private Key، CSR و Certificate
- اندازه RSA Key
- مدت اعتبار Certificate
- TLS Protocolها
- TLS Cipherها

جداکردن Variables از Playbookها باعث می‌شود Automation برای Environment یا Domain دیگر با تغییر چند مقدار قابل استفاده مجدد باشد.

---

## ۵. Handlers

Handler اصلی:

```text
Reload containerized Nginx
```

این Handler توسط تغییر در موارد زیر Notify می‌شود:

- Private Key
- CSR
- Certificate
- Nginx Template
- Symbolic Link مربوط به Site
- حذف Default Site

Handler دو عملیات را به‌ترتیب انجام می‌دهد:

1. اجرای `nginx -t` داخل Container فعال
2. اجرای `nginx -s reload` داخل Container

Handler فقط وقتی Configuration یا Certificate تغییر کند اجرا می‌شود و اگر چند Task آن را Notify کنند، در هر Play فقط یک بار اجرا خواهد شد.

---

## ۶. Templates

### `templates/docker-compose.yml.j2`

Compose Stack نهایی را ایجاد می‌کند و شامل موارد زیر است:

- MariaDB
- Flask Backend
- Nginx Proxy
- Health Checkها
- Networks
- Named Volume
- Docker Secret
- Portهای ۸۰ و ۴۴۳
- Certificate Mountها

### `templates/nginx.conf.j2`

Configuration نهایی Nginx را با Variables زیر ایجاد می‌کند:

- Domain
- Certificate Filename
- Private Key Filename
- TLS Protocolها
- TLS Cipherها

### `templates/app.env.j2`

Environment Variables غیرحساس Docker Compose را ایجاد می‌کند.

---

## ۷. Dependencyها

Dependencyهای اصلی:

- Docker Engine
- Docker Compose Plugin
- Python روی Managed Node
- `python3-cryptography`
- Collection `community.docker`
- Collection `community.crypto`
- فایل‌های مرحله `04_docker`

فایل `requirements.yml` Collectionهای مورد نیاز را تعریف می‌کند.

---

## ۸. Error Handling

در `deploy_app.yml` عملیات Build و Run داخل `block` قرار گرفته است.

در صورت شکست:

1. آخرین Compose Logها جمع‌آوری می‌شوند.
2. Logها در خروجی نمایش داده می‌شوند.
3. Playbook با پیام مشخص متوقف می‌شود.

همچنین قبل از Deployment وجود فایل‌های Source با `stat` و `assert` بررسی می‌شود.

Nginx Configuration پیش از استفاده در Container اصلی با یک Container موقت و دستور `nginx -t` اعتبارسنجی می‌شود.

---

## ۹. Idempotency

Playbookها تا حد ممکن Idempotent طراحی شده‌اند:

- Directoryها فقط در صورت نیاز ایجاد می‌شوند.
- فایل‌ها فقط در صورت تغییر کپی یا Template می‌شوند.
- Password دیتابیس در اجرای مجدد تغییر نمی‌کند.
- Private Key و Certificate بدون نیاز بازتولید نمی‌شوند.
- Handler فقط هنگام تغییر اجرا می‌شود.
- Docker Compose وضعیت موجود را با وضعیت تعریف‌شده تطبیق می‌دهد.

---

## ۱۰. Check Mode و Diff Mode

برای Dry Run می‌توان از دستور زیر استفاده کرد:

```bash
ansible-playbook -i inventory ../08_ansible_automation/site.yml --check --diff --ask-become-pass
```

Check Mode یک شبیه‌سازی است. عملیات Runtime مانند اجرای Container، تست HTTP و جمع‌آوری Log در Check Mode اجرا نمی‌شوند. بهترین نتیجه Check Mode زمانی به دست می‌آید که ساختار اولیه Deployment از قبل روی سرور وجود داشته باشد.

---

## ۱۱. تفاوت Nginx کانتینری با Nginx روی Host

در این پروژه Nginx داخل Container اجرا می‌شود. برای حفظ الزامات آموزشی، ساختار زیر در Deployment Directory ایجاد شده است:

```text
nginx/
├── sites-available/
│   └── myapp.conf
└── sites-enabled/
    └── myapp.conf -> ../sites-available/myapp.conf
```

هر دو Directory به Nginx Container Mount می‌شوند. بنابراین Symbolic Link داخل Container نیز معتبر است.

معادل عملیات Host-based:

| Nginx روی Host | معماری Containerized |
|---|---|
| `/etc/nginx/sites-available` | `/opt/nginx-flask-mysql/nginx/sites-available` |
| `/etc/nginx/sites-enabled` | `/opt/nginx-flask-mysql/nginx/sites-enabled` |
| `systemctl reload nginx` | `docker compose exec proxy nginx -s reload` |
| `nginx -t` | `docker compose exec proxy nginx -t` |
