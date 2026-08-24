# مرحله ۸ — خودکارسازی کامل با Ansible

## ساختار فایل‌ها

```text
08_ansible_automation/
├── automation_design.md
├── deploy_app.yml
├── app_vars.yml
├── deploy_nginx.yml
├── nginx_vars.yml
├── verify.yml
├── site.yml
├── requirements.yml
├── run_automation.sh
├── templates/
│   ├── app.env.j2
│   ├── docker-compose.yml.j2
│   └── nginx.conf.j2
├── playbook_output.txt      # پس از اجرا ساخته می‌شود
└── verification.txt         # پس از اجرا ساخته می‌شود
```

## پیش‌نیازها

- پوشه `04_docker` در Root پروژه موجود باشد.
- Inventory مرحله ۲ آماده باشد.
- اتصال SSH و `become` کار کند.
- Docker و Docker Compose روی Ubuntu نصب باشند.
- پورت‌های ۸۰ و ۴۴۳ در UFW مجاز باشند.

## ۱. قرار دادن پوشه

مسیر نهایی:

```text
~/naserrahmati_kubernetes_02/08_ansible_automation
```

## ۲. نصب Collectionها

```bash
cd ~/naserrahmati_kubernetes_02/02_ansible_setup

ansible-galaxy collection install \
  -r ../08_ansible_automation/requirements.yml
```

بررسی:

```bash
ansible-galaxy collection list | grep -E 'community.docker|community.crypto'
```

## ۳. بررسی Syntax

```bash
ansible-playbook \
  -i inventory \
  ../08_ansible_automation/site.yml \
  --syntax-check
```

## ۴. Dry Run

```bash
ansible-playbook \
  -i inventory \
  ../08_ansible_automation/site.yml \
  --check \
  --diff \
  --ask-become-pass
```

Check Mode عملیات Runtime مانند اجرای Docker و تست HTTP را انجام نمی‌دهد. اگر سرور کاملاً خام باشد، ابتدا Syntax Check را ملاک قرار دهید و سپس اجرای واقعی را انجام دهید.

## ۵. اجرای کامل با یک دستور

```bash
cd ~/naserrahmati_kubernetes_02

chmod +x 08_ansible_automation/run_automation.sh

./08_ansible_automation/run_automation.sh
```

Script رمز `sudo` کاربر `rahmati` را درخواست می‌کند و خروجی اجرا را در فایل زیر ذخیره می‌کند:

```text
08_ansible_automation/playbook_output.txt
```

Playbook نهایی Verification نیز فایل زیر را ایجاد می‌کند:

```text
08_ansible_automation/verification.txt
```

## ۶. اجرای مستقیم site.yml

```bash
cd ~/naserrahmati_kubernetes_02/02_ansible_setup

set -o pipefail

ansible-playbook \
  -i inventory \
  ../08_ansible_automation/site.yml \
  --ask-become-pass \
  -v \
  2>&1 | tee ../08_ansible_automation/playbook_output.txt
```

## ۷. نتیجه موفق

در انتهای `playbook_output.txt` باید مقادیر زیر دیده شوند:

```text
unreachable=0
failed=0
```

فایل `verification.txt` باید شامل موارد زیر باشد:

```text
Containers: VERIFIED
Nginx configuration: VERIFIED
HTTP redirect: VERIFIED
HTTPS application response: VERIFIED
Certificate: VERIFIED
Overall automation verification: PASSED
```

## ۸. تست دستی

```bash
curl -I http://myapp.test/
```

```bash
curl -k -I https://myapp.test/
```

```bash
curl -k -L http://myapp.test/
```

## ۹. اجرای مجدد و Idempotency

اجرای مجدد `site.yml` مجاز است. Password دیتابیس، Private Key و Certificate بدون دلیل تغییر نخواهند کرد.

برای مشاهده Idempotency، Playbook را بار دوم اجرا کرده و تعداد Taskهای `changed` را بررسی کنید. Build Backend با سیاست فعلی انجام می‌شود، اما سرویس‌ها فقط در صورت تفاوت Configuration توسط Compose تغییر خواهند کرد.
