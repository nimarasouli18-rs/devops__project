# توضیح پیکربندی Nginx

## ۱. وضعیت مرحله ۶ در معماری فعلی

در مرحله Docker، سرویس Nginx با نام `proxy` به‌صورت Container ایجاد شد و درخواست‌ها را به سرویس Flask با نام `backend` و پورت داخلی `8000` ارسال می‌کند.

بنابراین بخش Reverse Proxy از قبل پیاده‌سازی شده است؛ اما برای تکمیل الزامات مرحله ۶ موارد زیر انجام می‌شوند:

- انتخاب یک Domain آزمایشی
- جایگزینی `server_name _` با Domain مشخص
- تکمیل Headerهای Reverse Proxy
- اضافه‌کردن Error Handling
- اضافه‌کردن Health Endpoint مستقل برای Nginx
- انتقال Configuration جدید به سرور Ubuntu
- تست Configuration داخل Container
- Recreate کردن Container مربوط به Nginx
- ثبت Domain در `/etc/hosts` سیستم محلی
- تست دسترسی با Domain و ثبت نتیجه

---

## ۲. Domain انتخاب‌شده

Domain آزمایشی پروژه:

```text
myapp.test
```

IP سرور مقصد:

```text
192.168.200.54
```

Entry مورد نیاز در فایل `/etc/hosts` سیستم محلی:

```text
192.168.200.54 myapp.test
```

از Domain فقط برای محیط آزمایش داخلی استفاده می‌شود و نیازی به DNS عمومی ندارد.

---

## ۳. پورت‌های مورد استفاده

| بخش | پورت |
|---|---:|
| Nginx روی Host سرور مقصد | 80 |
| Nginx داخل Container | 80 |
| Flask Backend داخل Docker Network | 8000 |
| MariaDB داخل Docker Network | 3306 |

فقط پورت `80` سرویس Nginx روی Host منتشر می‌شود.

پورت‌های Backend و Database مستقیماً روی Host منتشر نمی‌شوند.

---

## ۴. تفاوت با Nginx نصب‌شده روی Host

در شرح مسئله مسیرهای زیر پیشنهاد شده‌اند:

```text
/etc/nginx/sites-available/
/etc/nginx/sites-enabled/
```

و برای مدیریت سرویس نیز این دستور پیشنهاد شده است:

```text
systemctl reload nginx
```

این ساختار مخصوص نصب Debian/Ubuntu Package مربوط به Nginx روی Host است.

در این پروژه Nginx داخل Docker Container اجرا می‌شود؛ بنابراین معادل صحیح آن چنین است:

| روش Host-based | روش Container-based پروژه |
|---|---|
| `/etc/nginx/sites-available/` | فایل `06_nginx/nginx_config.txt` روی Controller |
| Symbolic Link در `sites-enabled` | Bind Mount داخل Compose |
| `/etc/nginx/sites-enabled/...` | `/etc/nginx/conf.d/default.conf` داخل Container |
| `nginx -t` روی Host | `docker compose exec -T proxy nginx -t` |
| `systemctl reload nginx` | Recreate یا Reload کردن Container Nginx |
| نصب Nginx با APT | استفاده از Nginx Official Docker Image |

به همین دلیل ایجاد `sites-available` و `sites-enabled` روی Ubuntu مقصد لازم نیست و باعث ایجاد دو Nginx مستقل و تداخل روی پورت `80` می‌شود.

---

## ۵. محل Configuration

فایل خروجی این مرحله:

```text
06_nginx/nginx_config.txt
```

فایل عملیاتی روی سرور مقصد:

```text
/opt/nginx-flask-mysql/nginx/default.conf
```

مسیر فایل داخل Nginx Container:

```text
/etc/nginx/conf.d/default.conf
```

Docker Compose فایل Host را به‌صورت Read-only داخل Container Mount می‌کند.

---

## ۶. تحلیل Configuration

### Listen روی IPv4

```nginx
listen 80;
```

Nginx را روی پورت HTTP شماره `80` فعال می‌کند.

### Listen روی IPv6

```nginx
listen [::]:80;
```

Nginx را برای اتصال‌های IPv6 روی پورت `80` فعال می‌کند.

### Domain

```nginx
server_name myapp.test;
```

Virtual Host مربوط به Domain آزمایشی پروژه را مشخص می‌کند.

### مخفی‌کردن نسخه Nginx

```nginx
server_tokens off;
```

نمایش نسخه دقیق Nginx در صفحات خطای تولیدشده توسط Nginx را غیرفعال می‌کند.

### حداکثر اندازه Request Body

```nginx
client_max_body_size 10m;
```

حداکثر اندازه Body درخواست را روی ۱۰ مگابایت تنظیم می‌کند.

---

## ۷. Reverse Proxy

```nginx
location / {
    proxy_pass http://backend:8000;
}
```

تمام درخواست‌های مسیر `/` به سرویس Backend ارسال می‌شوند.

نام `backend` از طریق DNS داخلی Docker به Container مربوط به Flask Resolve می‌شود.

Backend داخل Network مشترک `frontnet` روی پورت `8000` در دسترس Nginx است.

---

## ۸. HTTP Version

```nginx
proxy_http_version 1.1;
```

ارتباط Proxy با Backend را با HTTP/1.1 انجام می‌دهد.

---

## ۹. Headerهای Reverse Proxy

### Host

```nginx
proxy_set_header Host $host;
```

Domain اصلی درخواست را برای Backend حفظ می‌کند.

### IP مستقیم Client

```nginx
proxy_set_header X-Real-IP $remote_addr;
```

IP کلاینت متصل‌شده به Nginx را برای Backend ارسال می‌کند.

### زنجیره Proxyها

```nginx
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

IP کلاینت را به زنجیره `X-Forwarded-For` اضافه می‌کند.

### Protocol

```nginx
proxy_set_header X-Forwarded-Proto $scheme;
```

مشخص می‌کند درخواست اصلی از طریق HTTP یا HTTPS دریافت شده است.

### Forwarded Host

```nginx
proxy_set_header X-Forwarded-Host $host;
```

Host اصلی درخواست را به‌صورت صریح برای Backend ارسال می‌کند.

### Forwarded Port

```nginx
proxy_set_header X-Forwarded-Port $server_port;
```

پورت عمومی دریافت درخواست را برای Backend ارسال می‌کند.

---

## ۱۰. Timeoutها

```nginx
proxy_connect_timeout 5s;
```

حداکثر زمان برقراری اتصال Nginx به Backend را مشخص می‌کند.

```nginx
proxy_send_timeout 60s;
```

حداکثر زمان ارسال درخواست به Backend را مشخص می‌کند.

```nginx
proxy_read_timeout 60s;
```

حداکثر زمان انتظار برای دریافت پاسخ از Backend را مشخص می‌کند.

---

## ۱۱. Error Handling

این خط خطاهای مهم Upstream را به Location اختصاصی هدایت می‌کند:

```nginx
error_page 502 503 504 =503 @backend_unavailable;
```

خطاهای مدیریت‌شده:

- `502 Bad Gateway`
- `503 Service Unavailable`
- `504 Gateway Timeout`

برای فعال‌شدن پردازش خطاهای Backend توسط Nginx از این دستور استفاده شده است:

```nginx
proxy_intercept_errors on;
```

Location مربوط به خطای Backend:

```nginx
location @backend_unavailable {
    default_type text/plain;
    add_header Retry-After 30 always;
    return 503 "Service temporarily unavailable\n";
}
```

در صورت در دسترس نبودن Backend، پاسخ ساده و کنترل‌شده با Status Code برابر `503` برگردانده می‌شود.

Header زیر نیز به Client پیشنهاد می‌دهد ۳۰ ثانیه بعد دوباره تلاش کند:

```text
Retry-After: 30
```

---

## ۱۲. Health Endpoint مربوط به Nginx

```nginx
location = /nginx-health {
    access_log off;
    default_type text/plain;
    return 200 "healthy\n";
}
```

این Endpoint فقط وضعیت خود Nginx را بررسی می‌کند و Request را به Backend یا Database ارسال نمی‌کند.

آدرس تست:

```text
http://myapp.test/nginx-health
```

پاسخ مورد انتظار:

```text
healthy
```

Status Code مورد انتظار:

```text
200
```

---

## ۱۳. فعال‌سازی Configuration در Docker

Playbook زیر برای انتقال و فعال‌سازی Configuration استفاده می‌شود:

```text
06_nginx/configure_nginx.yml
```

عملیات Playbook:

1. وجود Deployment Directory را بررسی می‌کند.
2. Configuration جدید را به سرور Ubuntu منتقل می‌کند.
3. فایل را در مسیر عملیاتی Nginx قرار می‌دهد.
4. Configuration را با یک Container موقت Nginx تست می‌کند.
5. Container سرویس `proxy` را Recreate می‌کند.
6. دستور `nginx -t` را داخل Container اصلی اجرا می‌کند.
7. Endpoint مربوط به Health را تست می‌کند.
8. درخواست Domain-based را با Header مناسب تست می‌کند.

به دلیل Bind Mount شدن یک فایل تکی، Recreate کردن Container از Reload ساده مطمئن‌تر است؛ چون ابزارهای انتقال فایل ممکن است فایل مقصد را به‌صورت Atomic Replace کنند.

---

## ۱۴. تنظیم `/etc/hosts`

روی AlmaLinux Controller باید Entry زیر به `/etc/hosts` اضافه شود:

```text
192.168.200.54 myapp.test
```

پس از ثبت Entry، دستور زیر باید IP سرور را نمایش دهد:

```bash
getent hosts myapp.test
```

در Linux معمولاً تغییر فایل `/etc/hosts` بلافاصله اعمال می‌شود و برای `curl` نیازی به Flush کردن Cache وجود ندارد.

اگر تست با Browser روی Windows انجام شود، Entry باید در فایل Hosts همان Windows نیز ثبت شود:

```text
C:\Windows\System32\drivers\etc\hosts
```

---

## ۱۵. تست‌های مورد نیاز

### تست Resolution

```bash
getent hosts myapp.test
```

### تست Nginx Health Endpoint

```bash
curl -i http://myapp.test/nginx-health
```

### تست Application

```bash
curl -i http://myapp.test/
```

پاسخ Application باید شامل Blog Postهای نمونه باشد.

### تست Configuration داخل Container

```bash
docker compose exec -T proxy nginx -t
```

نتیجه مورد انتظار:

```text
syntax is ok
test is successful
```

---

## ۱۶. خروجی‌های نهایی مرحله

```text
06_nginx/
├── nginx_config.txt
├── nginx_explanation.md
├── configure_nginx.yml
├── collect_results.sh
├── hosts_file.txt
└── test_results.txt
```

دو فایل زیر با اجرای واقعی Script روی AlmaLinux Controller ایجاد می‌شوند:

```text
hosts_file.txt
test_results.txt
```

این دو فایل نباید با خروجی ساختگی پر شوند.
