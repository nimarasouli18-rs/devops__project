# مستند مشارکت اعضای تیم

## ۱. معرفی تیم

این پروژه توسط یک تیم سه‌نفره انجام شده است. مسئولیت اصلی هر عضو بر اساس یکی از حوزه‌های Ansible، Docker و Nginx/SSL تقسیم شده است.

نام اعضا در نسخه نهایی باید در محل‌های مشخص‌شده جایگزین شوند.

| عضو | نام و نام خانوادگی | مسئولیت اصلی | سهم پیشنهادی |
|---|---|---|---:|
| عضو اول | ناصر رحمتی | Ansible و Automation | 33.3٪ |
| عضو دوم | نیما رسولی | Docker و Docker Compose | 33.3٪ |
| عضو سوم | فاطمه محمدی | Nginx و SSL/TLS | 33.3٪ |

## ۲. اصول تقسیم کار

تقسیم وظایف بر اساس این اصول انجام شد:

- هر عضو مالک اصلی یک حوزه تخصصی بود.
- طراحی Interface بین حوزه‌ها به‌صورت مشترک انجام شد.
- تست End-to-End به‌صورت تیمی انجام شد.
- مستندسازی هر بخش ابتدا توسط مسئول همان بخش نوشته و سپس توسط سایر اعضا بازبینی شد.
- تصمیم‌های مشترک در مورد مسیرها، Portها، Domain، Secret و ساختار Repository با توافق تیم انجام شد.

## ۳. عضو اول — مسئول Ansible و Automation

### نام

```text
ناصر رحمتی
```

### وظایف اصلی

- نصب و پیکربندی Ansible روی AlmaLinux Controller
- حل تداخل نسخه‌های Ansible و Python
- ایجاد و مدیریت Inventory
- تنظیم Python Interpreter
- تست SSH و `ansible.builtin.ping`
- جمع‌آوری Facts
- نوشتن `server_setup.yml`
- نصب Packageهای ضروری روی Ubuntu
- نصب Docker Engine و Docker Compose Plugin
- مدیریت Docker Service و Containerd
- اضافه‌کردن کاربر Deployment به گروه Docker
- پیکربندی UFW
- ایجاد Playbook انتقال فایل‌ها
- ایجاد Playbook استقرار Application
- ایجاد Playbook Nginx و SSL
- تعریف Variables
- تعریف Templates
- تعریف Handlers
- ساخت `site.yml`
- تعریف Verification
- ثبت خروجی‌های Playbook
- طراحی Error Handling با `block` و `rescue`
- بررسی Idempotency و Check Mode

### فایل‌ها و بخش‌های تحت مسئولیت

```text
02_ansible_setup/
05_deployment/
08_ansible_automation/
```

فایل‌های مهم:

```text
inventory
server_setup.yml
verification.yml
deploy_app.yml
deploy_nginx.yml
verify.yml
site.yml
app_vars.yml
nginx_vars.yml
run_automation.sh
```

### چالش‌های عضو

- تداخل Ansible قدیمی و نسخه نصب‌شده با pipx
- تفاوت Python Controller و Target
- محدودیت Check Mode هنگام نصب Docker Repository
- هشدار Factهای Deprecated
- حفظ Idempotency در تولید Secret و Certificate
- نمایش‌ندادن Secretها در Log با `no_log`
- مدیریت خطاهای Docker Compose داخل Ansible
- خطای `No such image: sha256:...`
- جمع‌آوری Logها و خطای اصلی در Rescue Block
- هماهنگی Handlerهای Nginx کانتینری با Docker Compose

### راه‌حل‌های ارائه‌شده

- تثبیت Ansible روی Python 3.12
- استفاده از `ansible_facts`
- تفکیک Syntax Check، Check Mode و اجرای واقعی
- استفاده از `community.docker.docker_compose_v2`
- استفاده از `community.crypto`
- کنترل Permission فایل‌های حساس
- استفاده از `register`، `assert`، `debug`، `block` و `rescue`
- کنترل نسخه Docker Compose
- جلوگیری از حذف Volume هنگام Recreate کردن Stack

## ۴. عضو دوم — مسئول Docker و Docker Compose

### نام

```text
نیما رسولی
```

### وظایف اصلی

- بررسی Repositoryهای پیشنهادی
- انتخاب پروژه `nginx-flask-mysql`
- Clone و تحلیل پروژه مرجع
- بررسی Dockerfileهای موجود
- بررسی Compose موجود
- شناسایی Dependencyها و Portها
- طراحی Dockerfile جدید
- پیاده‌سازی Multi-stage Build
- استفاده از Image رسمی Python
- اضافه‌کردن Gunicorn
- ایجاد کاربر Non-root
- تثبیت UID/GID روی `10001`
- ساخت `.dockerignore`
- طراحی Compose سه‌سرویسی
- تعریف MariaDB
- تعریف Backend
- تعریف Nginx Proxy
- تعریف Health Checkها
- تعریف Named Volume
- تعریف Networkهای `frontnet` و `backnet`
- مدیریت Docker Secret
- اجرای Build محلی
- اجرای Stack محلی
- ثبت وضعیت Containerها و Logها
- تست Application با Curl

### فایل‌ها و بخش‌های تحت مسئولیت

```text
03_project_clone/
04_docker/
```

فایل‌های مهم:

```text
Dockerfile
.dockerignore
docker-compose.yml
app/hello.py
app/requirements.txt
build_log.txt
container_status.txt
test_results.txt
dockerfile_explanation.md
compose_explanation.md
```

### چالش‌های عضو

- دسترسی کاربر Controller به Docker Socket
- انتخاب Base Image مناسب
- بهینه‌سازی Layerها
- تفاوت Development Server و Production WSGI Server
- ناسازگاری Permission فایل Secret با UID/GID داخل Container
- Cache شدن Image قدیمی
- Health Checkهای وابسته به Database
- جلوگیری از Publish شدن پورت Backend و Database
- حفظ داده‌های MariaDB هنگام Recreate
- تفکیک Build Context از Secretها

### راه‌حل‌های ارائه‌شده

- عضویت امن کاربر در گروه Docker
- استفاده از Multi-stage Build
- استفاده از Gunicorn
- تعیین UID/GID ثابت
- تنظیم Secret روی `root:10001` و `0640`
- استفاده از `expose` به‌جای `ports` برای سرویس‌های داخلی
- استفاده از Named Volume
- استفاده از Network داخلی برای Database
- تعریف Startup Order با Health Check
- Rebuild بدون Cache هنگام تغییر User
- عدم استفاده از `docker compose down --volumes` در Troubleshooting معمولی

## ۵. عضو سوم — مسئول Nginx و SSL/TLS

### نام

```text
فاطمه محمدی
```

### وظایف اصلی

- طراحی Reverse Proxy
- انتخاب Domain آزمایشی `myapp.test`
- تنظیم `/etc/hosts`
- تعریف `server_name`
- تنظیم Portهای `80` و `443`
- تعریف `proxy_pass`
- تنظیم Headerهای Forwarded
- تنظیم Timeoutها
- اضافه‌کردن Error Handling
- ایجاد Endpoint سلامت Nginx
- تست Configuration با `nginx -t`
- تطبیق الزامات Host-based با Nginx کانتینری
- طراحی ساختار `sites-available` و `sites-enabled`
- تولید Private Key
- تولید CSR
- تولید Self-Signed Certificate
- تعریف SAN برای Domain و IP
- تنظیم TLS 1.2 و TLS 1.3
- تعریف Cipherها
- Redirect کردن HTTP به HTTPS
- Mount کردن Certificateها به‌صورت Read-only
- تست Redirect
- تست HTTPS
- بررسی Certificate ارائه‌شده توسط Nginx

### فایل‌ها و بخش‌های تحت مسئولیت

```text
06_nginx/
07_ssl/
08_ansible_automation/templates/nginx.conf.j2
```

فایل‌های مهم:

```text
nginx_config.txt
nginx_explanation.md
configure_nginx.yml
nginx_ssl_config.txt
docker-compose.ssl.yml
configure_ssl.yml
ssl_explanation.md
templates/nginx.conf.j2
```

### چالش‌های عضو

- الزام مسئله به Nginx نصب‌شده روی Host در برابر معماری Containerized
- جلوگیری از تداخل دو Nginx روی پورت `80`
- مدیریت Configuration با Bind Mount
- پیام Read-only مربوط به Nginx Entrypoint
- Reload کردن Nginx داخل Container
- Trust نشدن Self-Signed Certificate
- تعریف SAN صحیح
- تست HTTPS با Domain داخلی
- عدم فعال‌سازی نامناسب HSTS در Lab
- حفظ امنیت Private Key

### راه‌حل‌های ارائه‌شده

- اجرای فقط یک Nginx در Container
- استفاده از Bind Mount Read-only
- اجرای `nginx -t` داخل Container
- استفاده از Recreate یا `nginx -s reload`
- ایجاد Mapping در `/etc/hosts`
- تولید Certificate دارای DNS و IP SAN
- Permission برابر `0600` برای Private Key
- استفاده از `curl -k` فقط برای تست Lab
- فعال‌سازی TLS 1.2 و TLS 1.3
- عدم Publish مستقیم Backend و Database

## ۶. فعالیت‌های مشترک تیم

فعالیت‌های زیر به‌صورت مشترک انجام شدند:

- تعیین معماری کلی
- انتخاب مسیرهای پروژه
- تعیین نام Domain
- تعیین Portها
- بازبینی Security
- تست End-to-End
- بررسی Logها
- تحلیل خطاها
- بازبینی Pull Requestها یا Commitها
- تهیه README
- تهیه Architecture Documentation
- تهیه Deployment Guide
- تهیه Troubleshooting Guide
- آماده‌سازی تحویل نهایی
- بررسی `.gitignore`
- بررسی عدم Commit شدن Secretها
- تولید `git_history.txt`
- تولید `final_structure.txt`

## ۷. ماتریس مسئولیت

| فعالیت | Ansible | Docker | Nginx/SSL |
|---|:---:|:---:|:---:|
| آماده‌سازی Controller | اصلی | بازبین | بازبین |
| آماده‌سازی Ubuntu | اصلی | مشاور | مشاور |
| انتخاب پروژه GitHub | مشارکت | اصلی | مشارکت |
| Dockerfile | بازبین | اصلی | مشارکت |
| Docker Compose | مشارکت | اصلی | مشارکت |
| Secret و Permission | مشارکت | اصلی | بازبین |
| Reverse Proxy | مشارکت | مشارکت | اصلی |
| SSL/TLS | مشارکت | مشارکت | اصلی |
| Ansible Automation | اصلی | بازبین | بازبین |
| Verification | اصلی | مشارکت | مشارکت |
| Documentation | مشترک | مشترک | مشترک |
| Git و تحویل نهایی | مشترک | مشترک | مشترک |

## ۸. روش همکاری پیشنهادی در Git

Branchها:

```text
main
develop
feature/ansible
feature/docker
feature/nginx-ssl
docs/documentation
```

Workflow:

```text
feature branch
      ↓
review by another member
      ↓
merge into develop
      ↓
end-to-end verification
      ↓
merge into main
      ↓
tag v1.0.0
```

## ۹. ثبت چالش‌های فردی

پیش از تحویل نهایی، هر عضو باید در جدول زیر یک توضیح کوتاه شخصی اضافه کند:

| عضو | مهم‌ترین چالش شخصی | مهم‌ترین درس آموخته‌شده |
|---|---|---|
| عضو Ansible | ................................ | ................................ |
| عضو Docker | ................................ | ................................ |
| عضو Nginx/SSL | ................................ | ................................ |

## ۱۰. تأیید نهایی اعضا

| عضو | نام | تأیید | تاریخ |
|---|---|---|---|
| مسئول Ansible | ناصر رحمتی | امضا/تأیید | 1405-05-31 |
| مسئول Docker | نیما رسولی | امضا/تأیید | 1405-05-31 |
| مسئول Nginx/SSL | فاطمه محمدی | امضا/تأیید | 1405-05-31 |

## ۱۱. جمع‌بندی

تقسیم وظایف بر اساس سه حوزه اصلی انجام شد، اما اتصال این حوزه‌ها نیازمند همکاری کامل تیم بود. Docker بدون Automation قابل تحویل نهایی نبود، Ansible بدون ساختار صحیح Docker نمی‌توانست Deployment موفق انجام دهد و Nginx/SSL بدون هماهنگی با Compose و Networkها قابل اجرا نبود.

بنابراین با وجود مالکیت تخصصی هر بخش، نتیجه نهایی حاصل Integration و بازبینی مشترک هر سه عضو است.
