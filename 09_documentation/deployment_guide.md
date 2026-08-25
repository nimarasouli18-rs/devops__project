# راهنمای استقرار پروژه

## ۱. هدف

این راهنما فرآیند استقرار پروژه را از یک Controller مبتنی بر AlmaLinux روی Ubuntu 22.04 توضیح می‌دهد.

نتیجه نهایی:

```text
https://myapp.test/
```

## ۲. مشخصات محیط

```text
Controller:
  OS: AlmaLinux
  User: naser

Target:
  OS: Ubuntu 22.04.5 LTS
  IP: 192.168.200.54
  SSH User: rahmati

Application:
  Domain: myapp.test
  Directory: /opt/nginx-flask-mysql
```

## ۳. آماده‌سازی Controller

### ۳.۱. نصب ابزارها

```bash
sudo dnf install -y \
  python3.12 \
  python3.12-pip \
  git \
  openssh-clients \
  curl \
  openssl
```

### ۳.۲. نصب pipx

```bash
python3.12 -m pip install --user --upgrade pipx
python3.12 -m pipx ensurepath
export PATH="$HOME/.local/bin:$PATH"
```

خروجی مورد انتظار:

```bash
pipx --version
```

```text
1.x
```

### ۳.۳. نصب Ansible

```bash
pipx install \
  --python /usr/bin/python3.12 \
  --include-deps \
  ansible
```

بررسی:

```bash
ansible --version
ansible-community --version
```

خروجی پروژه:

```text
ansible [core 2.21.3]
Ansible community version 14.3.1
```

## ۴. آماده‌سازی SSH

```bash
ssh-keygen -t ed25519
ssh-copy-id rahmati@192.168.200.54
```

تست:

```bash
ssh rahmati@192.168.200.54
```

روی Target:

```bash
whoami
python3 --version
sudo -v
```

خروجی مورد انتظار:

```text
rahmati
Python 3.x
```

## ۵. Inventory

فایل:

```text
02_ansible_setup/inventory
```

محتوا:

```ini
[deployment_servers]
ubuntu_deploy ansible_host=192.168.200.54 ansible_user=rahmati ansible_port=22 ansible_python_interpreter=/usr/bin/python3 deployment_user=rahmati
```

بررسی:

```bash
cd ~/naserrahmati_kubernetes_02/02_ansible_setup

ansible-inventory -i inventory --graph
```

خروجی مورد انتظار:

```text
@deployment_servers:
  |--ubuntu_deploy
```

## ۶. تست اتصال Ansible

```bash
ansible -i inventory deployment_servers \
  -m ansible.builtin.ping \
  2>&1 | tee ping_test.txt
```

خروجی مورد انتظار:

```text
ubuntu_deploy | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

جمع‌آوری Facts:

```bash
ansible -i inventory deployment_servers \
  -m ansible.builtin.setup \
  2>&1 | tee facts.txt
```

## ۷. آماده‌سازی Ubuntu

نصب Collectionها:

```bash
ansible-galaxy collection install -r requirements.yml
```

بررسی Syntax:

```bash
ansible-playbook \
  -i inventory \
  server_setup.yml \
  --syntax-check
```

خروجی:

```text
playbook: server_setup.yml
```

اجرای Playbook:

```bash
set -o pipefail

ansible-playbook \
  -i inventory \
  server_setup.yml \
  --ask-become-pass \
  2>&1 | tee playbook_output.txt
```

خروجی موفق:

```text
unreachable=0
failed=0
```

Verification:

```bash
ansible-playbook \
  -i inventory \
  verification.yml \
  --ask-become-pass \
  2>&1 | tee verification.txt
```

موارد مورد انتظار:

```text
Docker version
Docker Compose version
Docker service active
Containerd active
UFW active
22/tcp ALLOW
80/tcp ALLOW
443/tcp ALLOW
```

## ۸. Clone و بررسی پروژه مرجع

```bash
cd ~/naserrahmati_kubernetes_02/03_project_clone

git clone https://github.com/docker/awesome-compose.git

cd awesome-compose/nginx-flask-mysql

tree
```

فایل‌های مهم:

```text
backend/Dockerfile
backend/hello.py
backend/requirements.txt
compose.yaml
proxy/Dockerfile
proxy/conf
db/password.txt
```

## ۹. تست Docker محلی روی Controller

```bash
cd ~/naserrahmati_kubernetes_02/04_docker
```

بررسی Compose:

```bash
docker compose \
  --env-file .env \
  -f docker-compose.yml \
  config --quiet
```

Build:

```bash
set -o pipefail

docker compose \
  --env-file .env \
  -f docker-compose.yml \
  --progress plain \
  build backend \
  2>&1 | tee build_log.txt
```

اجرا:

```bash
docker compose \
  --env-file .env \
  -f docker-compose.yml \
  up \
  --detach \
  --wait \
  --wait-timeout 180
```

خروجی مورد انتظار:

```text
db       Healthy
backend  Healthy
proxy    Healthy
```

تست:

```bash
curl -i http://127.0.0.1:8080/
```

خروجی مورد انتظار:

```text
HTTP/1.1 200 OK
Hello Blog post #1
```

## ۱۰. تنظیم Domain روی Controller

```bash
grep -q "myapp.test" /etc/hosts ||
echo "192.168.200.54 myapp.test" |
sudo tee -a /etc/hosts
```

بررسی:

```bash
getent hosts myapp.test
```

خروجی:

```text
192.168.200.54 myapp.test
```

## ۱۱. نصب Collectionهای Automation

```bash
cd ~/naserrahmati_kubernetes_02/02_ansible_setup

ansible-galaxy collection install \
  -r ../08_ansible_automation/requirements.yml
```

بررسی:

```bash
ansible-galaxy collection list |
grep -E 'community.docker|community.crypto'
```

## ۱۲. بررسی نسخه Docker Compose روی Target

```bash
ansible \
  -i inventory \
  deployment_servers \
  -b \
  -m ansible.builtin.command \
  -a "docker compose version" \
  --ask-become-pass
```

نسخه پیشنهادی:

```text
Docker Compose 5.5.0 یا بالاتر
```

به‌روزرسانی روی Ubuntu:

```bash
ansible \
  -i inventory \
  deployment_servers \
  -b \
  -m ansible.builtin.apt \
  -a "name=docker-compose-plugin state=latest update_cache=yes" \
  --ask-become-pass
```

## ۱۳. بررسی Syntax Automation

```bash
ansible-playbook \
  -i inventory \
  ../08_ansible_automation/site.yml \
  --syntax-check
```

خروجی:

```text
playbook: ../08_ansible_automation/site.yml
```

## ۱۴. Dry Run

```bash
ansible-playbook \
  -i inventory \
  ../08_ansible_automation/site.yml \
  --check \
  --diff \
  --ask-become-pass
```

نکته:

- Docker Runtime Operationها ممکن است در Check Mode کامل شبیه‌سازی نشوند.
- اجرای واقعی ملاک نهایی است.

## ۱۵. اجرای کامل Automation

### روش Script

```bash
cd ~/naserrahmati_kubernetes_02

chmod +x 08_ansible_automation/run_automation.sh
./08_ansible_automation/run_automation.sh
```

### روش مستقیم

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

ترتیب Playbookها:

```text
deploy_app.yml
      |
deploy_nginx.yml
      |
verify.yml
```

خروجی نهایی موفق:

```text
unreachable=0
failed=0
```

## ۱۶. بررسی Verification

```bash
cat ~/naserrahmati_kubernetes_02/08_ansible_automation/verification.txt
```

مقادیر مورد انتظار:

```text
Containers: VERIFIED
Nginx configuration: VERIFIED
HTTP redirect: VERIFIED
HTTPS application response: VERIFIED
Certificate: VERIFIED
Overall automation verification: PASSED
```

## ۱۷. بررسی روی Ubuntu

```bash
ssh rahmati@192.168.200.54
```

```bash
cd /opt/nginx-flask-mysql
docker compose ps
```

انتظار:

```text
db        healthy
backend   healthy
proxy     healthy
```

بررسی Nginx:

```bash
docker compose exec -T proxy nginx -t
```

انتظار:

```text
syntax is ok
test is successful
```

بررسی پورت‌ها:

```bash
sudo ss -ltnp | grep -E ':80 |:443 '
```

## ۱۸. تست از Controller

Redirect:

```bash
curl -I http://myapp.test/
```

انتظار:

```text
HTTP/1.1 301 Moved Permanently
Location: https://myapp.test/
```

HTTPS:

```bash
curl -k -I https://myapp.test/
```

انتظار:

```text
HTTP/1.1 200 OK
```

Follow Redirect:

```bash
curl -k -L http://myapp.test/
```

## ۱۹. بررسی Certificate

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

انتظار:

```text
subject=... CN = myapp.test
issuer=... CN = myapp.test
DNS:myapp.test
IP Address:192.168.200.54
```

## ۲۰. مدیریت بعد از استقرار

### Status

```bash
cd /opt/nginx-flask-mysql
docker compose ps
```

### Log

```bash
docker compose logs \
  --no-color \
  --timestamps \
  --tail 200
```

### Restart

```bash
docker compose restart
```

### Rebuild Backend

```bash
docker compose build backend

docker compose up \
  -d \
  --wait \
  --wait-timeout 180
```

### توقف بدون حذف داده

```bash
docker compose down
```

## ۲۱. خروجی‌های مستنداتی مورد انتظار

```text
08_ansible_automation/playbook_output.txt
08_ansible_automation/verification.txt
```

همچنین:

```text
05_deployment/deploy_log.txt
05_deployment/container_status.txt
05_deployment/container_logs.txt
05_deployment/test_results.txt
06_nginx/test_results.txt
07_ssl/certificate_info.txt
07_ssl/test_results.txt
```

## ۲۲. مشکلات رایج در Deployment

### Docker Socket Permission

```bash
sudo usermod -aG docker "$USER"
```

سپس Logout/Login.

### Port Conflict

```bash
sudo ss -ltnp | grep -E ':80 |:443 '
docker ps --format 'table {{.Names}}\t{{.Ports}}'
```

### Backend Unhealthy

```bash
docker compose logs --tail 200 backend
docker compose exec -T backend id
sudo ls -ln secrets/db_password.txt
```

### MariaDB Password و Volume قدیمی

در صورت `Access denied`، ابتدا Secret و Volume را بررسی کنید. حذف Volume فقط برای محیط Lab و با آگاهی از حذف داده‌ها مجاز است.

### No such image

Compose Plugin را ارتقا دهید و Containerهای قدیمی را بدون حذف Volume Recreate کنید.

## ۲۳. Rollback ساده

از فایل‌های Backup ایجادشده توسط Ansible یا نسخه قبلی Templateها استفاده کنید.

برای بازسازی سرویس‌ها:

```bash
cd /opt/nginx-flask-mysql

docker compose down
docker compose up -d --wait --wait-timeout 180
```

Volume دیتابیس حفظ می‌شود.
