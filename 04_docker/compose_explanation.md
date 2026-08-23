# توضیح فایل Docker Compose

## ۱. هدف فایل

فایل `docker-compose.yml` برای اجرای یک Web Application چندسرویسی طراحی شده است. این Stack از سه سرویس اصلی تشکیل می‌شود:

- `proxy`: وب‌سرور و Reverse Proxy مبتنی بر Nginx
- `backend`: اپلیکیشن Flask
- `db`: پایگاه داده MariaDB

معماری کلی ارتباط سرویس‌ها به شکل زیر است:

```text
Client
  |
  | HTTP
  v
Nginx Proxy
  |
  | frontnet
  v
Flask Backend
  |
  | backnet
  v
MariaDB
```

فقط سرویس Nginx از طریق Host در دسترس قرار می‌گیرد. Backend و Database فقط داخل Networkهای Docker قابل دسترسی هستند.

---

## ۲. نسخه Compose

```yaml
version: "3.8"
```

این مقدار برای تطبیق با الزامات پروژه آموزشی در فایل قرار گرفته است.

در نسخه‌های جدید Docker Compose، فیلد `version` دیگر نقش تعیین‌کننده‌ای در قابلیت‌های فایل ندارد و Compose از Compose Specification استفاده می‌کند. به همین دلیل ممکن است برای این خط هشدار `obsolete` نمایش داده شود، اما وجود آن مانع اجرای فایل نمی‌شود.

---

## ۳. سرویس Database

نام سرویس پایگاه داده:

```yaml
db:
```

این سرویس وظیفه نگهداری اطلاعات اپلیکیشن را بر عهده دارد.

### ۳.۱. Image پایگاه داده

```yaml
image: "${MARIADB_IMAGE:-mariadb:10.11.18-jammy}"
```

نام و نسخه Image از متغیر `MARIADB_IMAGE` داخل فایل `.env` خوانده می‌شود.

اگر این متغیر تعریف نشده باشد، مقدار پیش‌فرض زیر استفاده خواهد شد:

```text
mariadb:10.11.18-jammy
```

---

### ۳.۲. Restart Policy

```yaml
restart: unless-stopped
```

در صورت Crash شدن Container یا Restart شدن Docker، سرویس به‌صورت خودکار دوباره اجرا می‌شود.

اگر مدیر سیستم Container را به‌صورت دستی متوقف کند، Docker آن را تا زمان اجرای مجدد به‌طور خودکار Start نخواهد کرد.

---

### ۳.۳. متغیرهای محیطی MariaDB

```yaml
environment:
  MARIADB_DATABASE: "${MARIADB_DATABASE:-example}"
  MARIADB_ROOT_PASSWORD_FILE: /run/secrets/db-password
```

متغیر `MARIADB_DATABASE` نام دیتابیس اولیه را مشخص می‌کند.

نام دیتابیس از فایل `.env` خوانده می‌شود و مقدار پیش‌فرض آن برابر است با:

```text
example
```

متغیر `MARIADB_ROOT_PASSWORD_FILE` به MariaDB اعلام می‌کند که رمز عبور کاربر Root را از فایل زیر بخواند:

```text
/run/secrets/db-password
```

به این ترتیب Password مستقیماً داخل فایل Compose یا Environment Variable قرار نمی‌گیرد.

---

### ۳.۴. Docker Secret

```yaml
secrets:
  - db-password
```

Secret با نام `db-password` داخل Container در این مسیر Mount می‌شود:

```text
/run/secrets/db-password
```

فایل اصلی Secret روی Host در مسیر زیر قرار دارد:

```text
./secrets/db_password.txt
```

این فایل نباید داخل Git Repository ثبت شود.

---

### ۳.۵. Volume پایگاه داده

```yaml
volumes:
  - db-data:/var/lib/mysql
```

Named Volume با نام `db-data` برای نگهداری دائمی اطلاعات MariaDB استفاده می‌شود.

مسیر داده MariaDB داخل Container:

```text
/var/lib/mysql
```

حذف یا Recreate شدن Container باعث حذف اطلاعات داخل این Volume نمی‌شود.

برای حذف کامل داده‌ها باید Volume نیز به‌صورت صریح حذف شود.

---

### ۳.۶. پورت داخلی Database

```yaml
expose:
  - "3306"
```

پورت `3306` فقط داخل Networkهای Docker در دسترس است.

برای Database هیچ Port Mapping روی Host تعریف نشده است؛ بنابراین MariaDB مستقیماً از بیرون سرور قابل دسترسی نیست.

---

### ۳.۷. Network پایگاه داده

```yaml
networks:
  - backnet
```

Database فقط عضو Network داخلی `backnet` است.

این جداسازی باعث می‌شود سرویس Nginx مستقیماً به Database دسترسی نداشته باشد.

---

### ۳.۸. Health Check پایگاه داده

```yaml
healthcheck:
  test:
    - CMD
    - healthcheck.sh
    - --connect
    - --innodb_initialized
  interval: 5s
  timeout: 5s
  retries: 10
  start_period: 30s
```

Health Check بررسی می‌کند که:

- MariaDB قابل اتصال باشد.
- InnoDB به‌طور کامل مقداردهی اولیه شده باشد.
- Database آماده پاسخ‌گویی به Backend باشد.

تنظیمات Health Check:

| گزینه | مقدار | توضیح |
|---|---:|---|
| `interval` | 5 ثانیه | فاصله بین هر بررسی |
| `timeout` | 5 ثانیه | حداکثر زمان هر بررسی |
| `retries` | 10 | تعداد تلاش‌های ناموفق پیش از Unhealthy شدن |
| `start_period` | 30 ثانیه | زمان اولیه برای راه‌اندازی MariaDB |

---

## ۴. سرویس Backend

نام سرویس Backend:

```yaml
backend:
```

این سرویس اپلیکیشن Flask را اجرا می‌کند.

### ۴.۱. نام Image

```yaml
image: nginx-flask-mysql-backend:1.0
```

Image ساخته‌شده برای Backend با این نام و Tag در Docker ثبت می‌شود:

```text
nginx-flask-mysql-backend:1.0
```

---

### ۴.۲. تنظیمات Build

```yaml
build:
  context: .
  dockerfile: Dockerfile
  target: runtime
```

مقادیر Build:

| گزینه | مقدار | توضیح |
|---|---|---|
| `context` | `.` | پوشه `04_docker` به‌عنوان Build Context |
| `dockerfile` | `Dockerfile` | فایل مورد استفاده برای Build |
| `target` | `runtime` | Stage نهایی Multi-stage Dockerfile |

استفاده از `runtime` باعث می‌شود فقط Stage نهایی و فایل‌های لازم وارد Image اجرایی شوند.

---

### ۴.۳. Restart Policy

```yaml
restart: unless-stopped
```

Backend در صورت Crash یا Restart شدن Docker به‌صورت خودکار دوباره اجرا می‌شود.

---

### ۴.۴. فعال‌سازی Init Process

```yaml
init: true
```

Docker یک Init Process سبک داخل Container اجرا می‌کند.

این Init Process به مدیریت صحیح Signalها و پاک‌سازی Child Processها کمک می‌کند.

---

### ۴.۵. اتصال Secret به Backend

```yaml
secrets:
  - db-password
```

Backend نیز Password دیتابیس را از مسیر زیر می‌خواند:

```text
/run/secrets/db-password
```

این مسیر با کد فعلی `hello.py` سازگار است.

---

### ۴.۶. پورت داخلی Backend

```yaml
expose:
  - "8000"
```

اپلیکیشن Flask با Gunicorn داخل Container روی پورت `8000` اجرا می‌شود.

این پورت روی Host منتشر نشده است و فقط سرویس Nginx از طریق Network داخلی به آن دسترسی دارد.

---

### ۴.۷. Networkهای Backend

```yaml
networks:
  - backnet
  - frontnet
```

Backend عضو دو Network است:

- `frontnet`: برای ارتباط با Nginx
- `backnet`: برای ارتباط با MariaDB

Backend تنها سرویسی است که به هر دو Network متصل است.

---

### ۴.۸. وابستگی به Database

```yaml
depends_on:
  db:
    condition: service_healthy
```

Backend فقط زمانی Start می‌شود که Health Check سرویس `db` موفق شده و MariaDB در وضعیت `healthy` قرار گرفته باشد.

این تنظیم از اجرای زودهنگام Backend پیش از آماده‌شدن Database جلوگیری می‌کند.

---

### ۴.۹. Health Check مربوط به Backend

```yaml
healthcheck:
  test:
    - CMD
    - python
    - -c
    - import urllib.request; urllib.request.urlopen("http://127.0.0.1:8000/", timeout=3).read()
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 20s
```

این Health Check با استفاده از Python Standard Library درخواست HTTP داخلی به آدرس زیر ارسال می‌کند:

```text
http://127.0.0.1:8000/
```

موفق بودن درخواست نشان می‌دهد:

- Gunicorn اجرا شده است.
- اپلیکیشن Flask پاسخ می‌دهد.
- Route اصلی برنامه قابل دسترسی است.

تنظیمات:

| گزینه | مقدار |
|---|---:|
| `interval` | 10 ثانیه |
| `timeout` | 5 ثانیه |
| `retries` | 5 |
| `start_period` | 20 ثانیه |

---

## ۵. سرویس Proxy

نام سرویس Reverse Proxy:

```yaml
proxy:
```

این سرویس با استفاده از Nginx درخواست‌های کاربران را دریافت کرده و به Backend ارسال می‌کند.

### ۵.۱. Image سرویس Nginx

```yaml
image: "${NGINX_IMAGE:-nginx:1.30.4-alpine}"
```

نام Image از متغیر `NGINX_IMAGE` در فایل `.env` خوانده می‌شود.

در صورت تعریف‌نشدن متغیر، مقدار پیش‌فرض زیر استفاده می‌شود:

```text
nginx:1.30.4-alpine
```

---

### ۵.۲. Restart Policy

```yaml
restart: unless-stopped
```

Nginx در صورت Crash شدن یا Restart شدن Docker به‌صورت خودکار دوباره اجرا می‌شود.

---

### ۵.۳. فعال‌سازی Init Process

```yaml
init: true
```

یک Init Process سبک برای مدیریت صحیح Processها و Signalها داخل Container فعال می‌شود.

---

### ۵.۴. Port Mapping

```yaml
ports:
  - "${HTTP_PORT:-8080}:80"
```

پورت داخلی Nginx برابر `80` است.

پورت Host از متغیر `HTTP_PORT` خوانده می‌شود.

مقدار پیش‌فرض:

```text
8080
```

در محیط تست، Application از طریق آدرس زیر در دسترس است:

```text
http://SERVER-IP:8080
```

در Deployment نهایی می‌توان مقدار `HTTP_PORT` را به `80` تغییر داد.

---

### ۵.۵. فایل تنظیمات Nginx

```yaml
volumes:
  - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
```

فایل تنظیمات Nginx از Host به مسیر زیر داخل Container Mount می‌شود:

```text
/etc/nginx/conf.d/default.conf
```

گزینه `ro` به معنی Read-only است؛ بنابراین Container نمی‌تواند فایل تنظیمات روی Host را تغییر دهد.

تنظیمات Nginx درخواست‌ها را به این مقصد ارسال می‌کند:

```text
http://backend:8000
```

نام `backend` توسط DNS داخلی Docker به IP Container Backend Resolve می‌شود.

---

### ۵.۶. Network سرویس Proxy

```yaml
networks:
  - frontnet
```

Nginx فقط عضو Network `frontnet` است.

این سرویس به `backnet` متصل نیست و در نتیجه نمی‌تواند مستقیماً به MariaDB دسترسی داشته باشد.

---

### ۵.۷. وابستگی به Backend

```yaml
depends_on:
  backend:
    condition: service_healthy
```

Nginx فقط پس از Healthy شدن Backend شروع به کار می‌کند.

ترتیب راه‌اندازی سرویس‌ها در نتیجه به شکل زیر خواهد بود:

```text
MariaDB Healthy
       ↓
Backend Healthy
       ↓
Nginx Proxy Started
```

---

### ۵.۸. Health Check مربوط به Nginx

```yaml
healthcheck:
  test:
    - CMD-SHELL
    - wget -q -O /dev/null http://127.0.0.1/ || exit 1
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 10s
```

این Health Check با استفاده از `wget` یک درخواست HTTP داخلی به Nginx ارسال می‌کند.

پاسخ موفق نشان می‌دهد Nginx در حال اجرا است و می‌تواند درخواست را پردازش کند.

---

## ۶. Volumeها

```yaml
volumes:
  db-data:
    driver: local
```

Named Volume با نام `db-data` توسط Docker ایجاد می‌شود.

نام نهایی آن با توجه به نام پروژه Compose معمولاً به شکل زیر خواهد بود:

```text
nginx-flask-mysql-lab_db-data
```

Driver برابر `local` است؛ بنابراین داده‌ها روی Host محلی Docker ذخیره می‌شوند.

---

## ۷. Secretها

```yaml
secrets:
  db-password:
    file: ./secrets/db_password.txt
```

Secret دیتابیس از فایل زیر خوانده می‌شود:

```text
04_docker/secrets/db_password.txt
```

این Secret به سرویس‌های زیر متصل است:

- `db`
- `backend`

سرویس `proxy` به Password دیتابیس دسترسی ندارد.

---

## ۸. Networkها

### ۸.۱. Network داخلی Database

```yaml
backnet:
  driver: bridge
  internal: true
```

Network `backnet` برای ارتباط Backend و MariaDB استفاده می‌شود.

گزینه زیر:

```yaml
internal: true
```

باعث می‌شود این Network از دسترسی مستقیم خارجی جدا باشد.

اعضای `backnet`:

- `db`
- `backend`

---

### ۸.۲. Network مربوط به Frontend

```yaml
frontnet:
  driver: bridge
```

Network `frontnet` برای ارتباط Nginx و Backend استفاده می‌شود.

اعضای `frontnet`:

- `proxy`
- `backend`

---

## ۹. فایل `.env`

فایل `.env` متغیرهای غیرحساس Compose را نگهداری می‌کند.

نمونه متغیرها:

```text
COMPOSE_PROJECT_NAME=nginx-flask-mysql-lab
HTTP_PORT=8080
MARIADB_IMAGE=mariadb:10.11.18-jammy
MARIADB_DATABASE=example
NGINX_IMAGE=nginx:1.30.4-alpine
```

وظایف متغیرها:

| متغیر | کاربرد |
|---|---|
| `COMPOSE_PROJECT_NAME` | تعیین نام پروژه Compose |
| `HTTP_PORT` | تعیین پورت عمومی Nginx روی Host |
| `MARIADB_IMAGE` | تعیین Image و نسخه MariaDB |
| `MARIADB_DATABASE` | تعیین نام دیتابیس اولیه |
| `NGINX_IMAGE` | تعیین Image و نسخه Nginx |

رمز دیتابیس داخل `.env` ذخیره نمی‌شود و از Docker Secret استفاده می‌شود.

---

## ۱۰. ترتیب اجرای سرویس‌ها

به دلیل استفاده از Health Check و `depends_on`، ترتیب اجرا به‌صورت زیر است:

1. سرویس `db` ایجاد و Start می‌شود.
2. Docker منتظر Healthy شدن MariaDB می‌ماند.
3. سرویس `backend` Start می‌شود.
4. Docker منتظر Healthy شدن Backend می‌ماند.
5. سرویس `proxy` Start می‌شود.
6. Application از طریق پورت تعیین‌شده در `HTTP_PORT` قابل دسترسی خواهد بود.

---

## ۱۱. Portهای مورد استفاده

| سرویس | پورت داخل Container | پورت Host | وضعیت دسترسی |
|---|---:|---:|---|
| MariaDB | 3306 | ندارد | فقط `backnet` |
| Flask Backend | 8000 | ندارد | فقط Networkهای Docker |
| Nginx Proxy | 80 | 8080 پیش‌فرض | قابل دسترسی از Host |

در این طراحی فقط Nginx Port عمومی دارد.

---

## ۱۲. Persistence

اطلاعات MariaDB داخل Named Volume ذخیره می‌شود.

دستور زیر Containerها و Networkها را حذف می‌کند، ولی Volume دیتابیس را نگه می‌دارد:

```bash
docker compose down
```

دستور زیر علاوه بر Containerها و Networkها، Volume دیتابیس را نیز حذف می‌کند:

```bash
docker compose down --volumes
```

استفاده از گزینه `--volumes` باعث حذف اطلاعات Database می‌شود و باید با احتیاط انجام شود.

---

## ۱۳. ملاحظات امنیتی

در این Configuration موارد امنیتی زیر رعایت شده است:

- Database مستقیماً روی Host منتشر نشده است.
- Backend مستقیماً روی Host منتشر نشده است.
- فقط Nginx به‌عنوان نقطه ورود عمومی استفاده می‌شود.
- Password دیتابیس از Docker Secret خوانده می‌شود.
- فایل تنظیمات Nginx به‌صورت Read-only Mount شده است.
- Nginx به Network دیتابیس دسترسی ندارد.
- Network دیتابیس با `internal: true` ایزوله شده است.
- Backend داخل Image با کاربر غیر Root اجرا می‌شود.
- Restart Policy برای هر سه سرویس تنظیم شده است.
- Health Check برای تمام سرویس‌ها تعریف شده است.

---

## ۱۴. دستورات اصلی مدیریت Stack

اعتبارسنجی فایل Compose:

```bash
docker compose --env-file .env -f docker-compose.yml config --quiet
```

ساخت Image مربوط به Backend:

```bash
docker compose --env-file .env -f docker-compose.yml build backend
```

اجرای Stack:

```bash
docker compose --env-file .env -f docker-compose.yml up -d
```

مشاهده وضعیت سرویس‌ها:

```bash
docker compose --env-file .env -f docker-compose.yml ps
```

مشاهده Logها:

```bash
docker compose --env-file .env -f docker-compose.yml logs
```

توقف و حذف Containerها و Networkها:

```bash
docker compose --env-file .env -f docker-compose.yml down
```

---

## ۱۵. جمع‌بندی

فایل `docker-compose.yml` تمام الزامات این مرحله را تأمین می‌کند:

| الزام | پیاده‌سازی |
|---|---|
| Web Application Service | سرویس `backend` |
| Database Service | سرویس `db` |
| Reverse Proxy | سرویس `proxy` |
| Network | `frontnet` و `backnet` |
| Persistence | Named Volume با نام `db-data` |
| Environment Variables | فایل `.env` |
| Port Mapping | پورت Nginx |
| Service Dependencies | `depends_on` با شرط Health |
| Restart Policies | `unless-stopped` |
| Health Checks | برای هر سه سرویس |
| Secret Management | Docker Secret برای Password دیتابیس |

این معماری برای تمرین Docker Compose، جداسازی سرویس‌ها، Persistence، مدیریت Secret، Health Check و آماده‌سازی برای Deployment خودکار با Ansible مناسب است.
