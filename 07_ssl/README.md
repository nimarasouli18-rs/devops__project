# مرحله ۷ — پیکربندی SSL/TLS

## فایل‌های بسته

```text
07_ssl/
├── nginx_ssl_config.txt
├── docker-compose.ssl.yml
├── configure_ssl.yml
├── ssl_explanation.md
└── README.md
```

فایل‌های زیر پس از اجرای واقعی Playbook ایجاد می‌شوند:

```text
07_ssl/certificate_info.txt
07_ssl/test_results.txt
07_ssl/nginx_ssl_deploy_log.txt
```

## پیش‌نیازها

قبل از اجرای این مرحله باید موارد زیر کامل شده باشند:

- مرحله ۵: Deployment اپلیکیشن روی Ubuntu
- مرحله ۶: تنظیم `myapp.test` در `/etc/hosts`
- فعال بودن پورت‌های `80` و `443` در UFW
- Healthy بودن سرویس‌های `db`، `backend` و `proxy`

بررسی Domain روی AlmaLinux Controller:

```bash
getent hosts myapp.test
```

خروجی باید IP زیر را نشان دهد:

```text
192.168.200.54
```

## ۱. قرار دادن پوشه در پروژه

پوشه را در مسیر زیر قرار دهید:

```text
~/naserrahmati_kubernetes_02/07_ssl
```

## ۲. بررسی Syntax

```bash
cd ~/naserrahmati_kubernetes_02/02_ansible_setup

ansible-playbook \
  -i inventory \
  ../07_ssl/configure_ssl.yml \
  --syntax-check
```

خروجی صحیح:

```text
playbook: ../07_ssl/configure_ssl.yml
```

## ۳. اجرای SSL Deployment

```bash
set -o pipefail

ansible-playbook \
  -i inventory \
  ../07_ssl/configure_ssl.yml \
  --ask-become-pass \
  2>&1 | tee ../07_ssl/nginx_ssl_deploy_log.txt
```

در پایان باید این مقادیر دیده شوند:

```text
unreachable=0
failed=0
```

همچنین Playbook باید این فایل‌ها را روی Controller ایجاد کند:

```text
07_ssl/certificate_info.txt
07_ssl/test_results.txt
```

## ۴. بررسی Certificate

```bash
cat ~/naserrahmati_kubernetes_02/07_ssl/certificate_info.txt
```

این فایل شامل موارد زیر است:

- مسیر Private Key
- مسیر CSR
- مسیر Certificate
- Permission فایل‌ها
- Subject
- Issuer
- Serial Number
- تاریخ شروع اعتبار
- تاریخ پایان اعتبار
- SHA-256 Fingerprint
- Subject Alternative Nameها
- اطلاعات Certificate ارائه‌شده توسط Nginx

## ۵. بررسی تست‌ها

```bash
cat ~/naserrahmati_kubernetes_02/07_ssl/test_results.txt
```

نتیجه موفق باید شامل موارد زیر باشد:

```text
HTTP status: 301
Location: https://myapp.test/
HTTPS status: 200
Overall SSL/TLS configuration: PASSED
```

## ۶. تست دستی

تست Redirect:

```bash
curl -I http://myapp.test/
```

تست HTTPS با نادیده‌گرفتن هشدار Self-Signed:

```bash
curl -k -I https://myapp.test/
```

تست Follow Redirect:

```bash
curl -k -L http://myapp.test/
```

مشاهده Certificate ارائه‌شده توسط Nginx:

```bash
printf '' |
openssl s_client \
  -connect myapp.test:443 \
  -servername myapp.test \
  2>/dev/null |
openssl x509 \
  -noout \
  -subject \
  -issuer \
  -dates \
  -fingerprint \
  -sha256 \
  -ext subjectAltName
```

## ۷. بررسی Containerها روی Ubuntu

```bash
ssh rahmati@192.168.200.54
```

سپس:

```bash
cd /opt/nginx-flask-mysql

docker compose ps
```

تست Configuration:

```bash
docker compose exec -T proxy nginx -t
```

بررسی Portها:

```bash
sudo ss -ltnp | grep -E ':80 |:443 '
```

## ۸. تولید مجدد Certificate

Playbook برای جلوگیری از تغییر ناخواسته Certificate، از فایل‌های موجود استفاده می‌کند.

برای تولید مجدد، ابتدا روی Ubuntu از فایل‌ها نسخه پشتیبان تهیه کرده و سپس آن‌ها را حذف کنید:

```bash
sudo cp -a \
  /opt/nginx-flask-mysql/certificates \
  /opt/nginx-flask-mysql/certificates.backup

sudo rm -f \
  /opt/nginx-flask-mysql/certificates/myapp.test.key \
  /opt/nginx-flask-mysql/certificates/myapp.test.csr \
  /opt/nginx-flask-mysql/certificates/myapp.test.crt
```

سپس Playbook را دوباره اجرا کنید.

## نکته امنیتی

گزینه `curl -k` فقط برای Certificate آزمایشی Self-Signed استفاده می‌شود. در محیط Production باید Certificate معتبر و مورد اعتماد Clientها نصب شود.
