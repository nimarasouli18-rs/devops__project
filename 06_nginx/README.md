# مرحله ۶ — پیکربندی Nginx کانتینری

## وضعیت الزامات

| الزام شرح پروژه | وضعیت در این معماری |
|---|---|
| انتخاب Domain | `myapp.test` |
| مشخص‌کردن Application Port | `backend:8000` |
| طراحی Reverse Proxy | انجام شده |
| تنظیم Forwarded Headers | انجام شده |
| Listen روی Port 80 | انجام شده |
| Error Handling | اضافه شده |
| `sites-available` و `sites-enabled` | به‌دلیل Containerized بودن Nginx کاربرد ندارد |
| تست با `nginx -t` | داخل Container انجام می‌شود |
| `systemctl reload nginx` | با Recreate کردن Container جایگزین شده |
| تنظیم `/etc/hosts` | توسط `collect_results.sh` انجام می‌شود |
| تست Domain | توسط `collect_results.sh` ثبت می‌شود |

## ۱. استخراج فایل‌ها

پوشه `06_nginx` را در ریشه پروژه قرار دهید:

```text
~/naserrahmati_kubernetes_02/06_nginx
```

## ۲. همگام‌سازی Configuration با سورس Docker

برای اینکه اجرای مجدد مرحله ۵ Configuration قدیمی را برنگرداند:

```bash
cd ~/naserrahmati_kubernetes_02

cp \
  06_nginx/nginx_config.txt \
  04_docker/nginx/default.conf
```

## ۳. بررسی Syntax مربوط به Playbook

```bash
cd ~/naserrahmati_kubernetes_02/02_ansible_setup

ansible-playbook \
  -i inventory \
  ../06_nginx/configure_nginx.yml \
  --syntax-check
```

## ۴. اجرای Configuration روی Ubuntu مقصد

```bash
set -o pipefail

ansible-playbook \
  -i inventory \
  ../06_nginx/configure_nginx.yml \
  --ask-become-pass \
  2>&1 | tee ../06_nginx/nginx_deploy_log.txt
```

در پایان باید این موارد موفق باشند:

```text
failed=0
unreachable=0
Nginx health status: 200
Application proxy status: 200
```

## ۵. تنظیم `/etc/hosts` و تولید خروجی‌ها

روی AlmaLinux Controller:

```bash
cd ~/naserrahmati_kubernetes_02

chmod +x 06_nginx/collect_results.sh

./06_nginx/collect_results.sh
```

این Script در صورت نیاز Entry زیر را به `/etc/hosts` اضافه می‌کند:

```text
192.168.200.54 myapp.test
```

سپس فایل‌های زیر را با خروجی واقعی ایجاد می‌کند:

```text
06_nginx/hosts_file.txt
06_nginx/test_results.txt
```

## ۶. بررسی خروجی‌ها

```bash
cat 06_nginx/hosts_file.txt
```

```bash
cat 06_nginx/test_results.txt
```

نتیجه موفق باید شامل موارد زیر باشد:

```text
HTTP/1.1 200 OK
healthy
Hello Blog post #1
HTTP Status: 200
Final result: PASSED
```

## ۷. ساختار نهایی

```text
06_nginx/
├── nginx_config.txt
├── nginx_explanation.md
├── configure_nginx.yml
├── collect_results.sh
├── nginx_deploy_log.txt
├── hosts_file.txt
└── test_results.txt
```
