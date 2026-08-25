# راهنمای رفع اشکال پروژه

## ۱. روش عیب‌یابی

ترتیب پیشنهادی:

```text
1. Ansible connection
2. Target services
3. Docker daemon
4. Compose validation
5. Container status
6. Health checks
7. Logs
8. Network
9. Secret permissions
10. HTTP/HTTPS
```

دستورات پایه:

```bash
ansible -i inventory deployment_servers -m ping

ssh rahmati@192.168.200.54

sudo systemctl status docker --no-pager

cd /opt/nginx-flask-mysql

docker compose config --quiet
docker compose ps --all
docker compose logs --tail 200
```

---

## ۲. خطای اتصال SSH

### نشانه

```text
UNREACHABLE
Connection timed out
Permission denied
```

### علت‌ها

- IP اشتباه
- SSH Service غیرفعال
- Firewall
- User اشتباه
- SSH Key ثبت نشده
- Host Key تغییر کرده

### بررسی

```bash
ping -c 4 192.168.200.54
ssh -v rahmati@192.168.200.54
```

روی Target:

```bash
sudo systemctl status ssh
sudo ufw status verbose
```

### راه‌حل

```bash
ssh-copy-id rahmati@192.168.200.54
```

در صورت تغییر Host Key و تأیید هویت واقعی سرور:

```bash
ssh-keygen -R 192.168.200.54
```

---

## ۳. خطای sudo یا Become

### نشانه

```text
Missing sudo password
Incorrect sudo password
user is not in the sudoers file
```

### بررسی

```bash
ssh rahmati@192.168.200.54
sudo -v
```

### راه‌حل

Playbook را با این گزینه اجرا کنید:

```bash
--ask-become-pass
```

مثال:

```bash
ansible-playbook \
  -i inventory \
  server_setup.yml \
  --ask-become-pass
```

---

## ۴. خطای Python Interpreter

### نشانه

```text
Failed to find a usable Python interpreter
```

### علت

Python روی Target نصب نیست یا مسیر اشتباه است.

### بررسی

```bash
ssh rahmati@192.168.200.54 "command -v python3 && python3 --version"
```

### تنظیم Inventory

```ini
ansible_python_interpreter=/usr/bin/python3
```

---

## ۵. `config file = None` در Ansible

### علت

Ansible فایل `ansible.cfg` را در Current Directory پیدا نکرده است.

### راه‌حل

```bash
cd ~/naserrahmati_kubernetes_02/02_ansible_setup

export ANSIBLE_CONFIG="$PWD/ansible.cfg"

ansible --version
```

---

## ۶. تداخل نسخه‌های Ansible

### نشانه

Ansible جدید با pipx نصب شده ولی دستور `ansible` نسخه قدیمی Python 3.9 را اجرا می‌کند.

### بررسی

```bash
command -v ansible
readlink -f "$(command -v ansible)"
ansible --version
pipx list
```

### راه‌حل

نسخه قدیمی User-level را حذف و لینک‌های pipx را بازسازی کنید:

```bash
/usr/bin/python3 -m pip uninstall -y ansible ansible-core

pipx install \
  --force \
  --python /usr/bin/python3.12 \
  --include-deps \
  ansible

hash -r
```

---

## ۷. خطای Docker Socket Permission

### نشانه

```text
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

### علت

کاربر عضو گروه `docker` نیست.

### بررسی

```bash
id
getent group docker
ls -l /var/run/docker.sock
```

### راه‌حل

روی همان ماشینی که Docker Command اجرا می‌شود:

```bash
sudo usermod -aG docker "$USER"
```

سپس Logout/Login:

```bash
exit
```

بعد از ورود:

```bash
id -nG
docker ps
```

### هشدار

این راه‌حل را استفاده نکنید:

```bash
sudo chmod 666 /var/run/docker.sock
```

---

## ۸. Docker Service غیرفعال است

### نشانه

```text
Cannot connect to the Docker daemon
```

### بررسی

```bash
sudo systemctl is-active docker
sudo systemctl status docker --no-pager
```

### راه‌حل

```bash
sudo systemctl enable --now docker
```

---

## ۹. خطای `docker-ce is not available` در Check Mode

### نشانه

```text
No package matching 'docker-ce' is available
```

فقط هنگام اولین اجرای:

```bash
ansible-playbook --check
```

### علت

در Check Mode، Repository جدید Docker واقعاً اضافه نمی‌شود، ولی تسک نصب پکیج سعی می‌کند Package را از Cache فعلی پیدا کند.

### راه‌حل

Syntax را بررسی کرده و یک‌بار Playbook را بدون `--check` اجرا کنید:

```bash
ansible-playbook \
  -i inventory \
  server_setup.yml \
  --ask-become-pass
```

پس از Bootstrap اولیه، Check Mode نتیجه دقیق‌تری خواهد داشت.

---

## ۱۰. هشدار Deprecated Facts در Ansible

### نشانه

```text
INJECT_FACTS_AS_VARS is deprecated
```

### علت

استفاده از Factهای Top-level مانند:

```yaml
ansible_distribution
ansible_architecture
```

### راه‌حل

از دیکشنری زیر استفاده کنید:

```yaml
ansible_facts["distribution"]
ansible_facts["architecture"]
```

در `ansible.cfg`:

```ini
inject_facts_as_vars = False
```

---

## ۱۱. YAML Parsing Error

### نشانه

```text
could not find expected ':'
```

### علت

Indentation اشتباه، خصوصاً بعد از `>-` یا بلوک Jinja.

### نمونه صحیح

```yaml
docker_apt_arch: >-
  {{
    docker_architecture_map.get(
      ansible_facts["architecture"],
      ansible_facts["architecture"]
    )
  }}
```

یا حالت ساده‌تر:

```yaml
docker_apt_arch: "{{ docker_architecture_map[ansible_facts['architecture']] | default(ansible_facts['architecture']) }}"
```

### بررسی

```bash
ansible-playbook \
  -i inventory \
  server_setup.yml \
  --syntax-check
```

---

## ۱۲. هشدار `version is obsolete`

### نشانه

```text
the attribute `version` is obsolete
```

### علت

Compose جدید از Compose Specification استفاده می‌کند و فیلد Top-level زیر را لازم ندارد:

```yaml
version: "3.8"
```

### راه‌حل

خط را از Template حذف کنید:

```bash
sed -i \
  '/^version: "3.8"$/d' \
  08_ansible_automation/templates/docker-compose.yml.j2
```

این هشدار معمولاً عامل Failure نیست.

---

## ۱۳. خطای `No such image: sha256:...`

### نشانه

```text
General error: Error response from daemon:
No such image: sha256:...
```

ممکن است ماژول Ansible هنگام اجرای داخلی دستور زیر Fail شود:

```text
docker compose images --format json
```

### علت

Container قدیمی به Image IDای اشاره می‌کند که رکورد آن دیگر در Docker Image Store موجود نیست. این وضعیت در برخی نسخه‌های Docker Compose هنگام Rebuild یا جایگزینی Image رخ می‌دهد.

### بررسی

```bash
docker compose version

cd /opt/nginx-flask-mysql

docker compose images
docker compose ps --all
docker image ls
```

### راه‌حل اول: Upgrade Compose روی Ubuntu

```bash
sudo apt update
sudo apt install --only-upgrade docker-compose-plugin
docker compose version
```

نسخه پیشنهادی:

```text
5.5.0 یا بالاتر
```

### راه‌حل دوم: Recreate بدون حذف Volume

```bash
cd /opt/nginx-flask-mysql

docker compose down --remove-orphans

docker compose up \
  -d \
  --build \
  --wait \
  --wait-timeout 180
```

از این گزینه استفاده نکنید:

```bash
--volumes
```

مگر اینکه حذف داده‌های MariaDB موردنظر باشد.

---

## ۱۴. Backend Unhealthy

### نشانه

```text
dependency backend failed to start
container backend is unhealthy
```

### بررسی وضعیت

```bash
docker compose ps --all
docker compose logs --tail 200 backend
```

Health Log:

```bash
backend_id="$(docker compose ps -q backend)"

docker inspect "$backend_id" \
  --format '{{range .State.Health.Log}}{{println "ExitCode:" .ExitCode}}{{println .Output}}{{end}}'
```

### علت‌های محتمل

- Secret غیرقابل خواندن
- اتصال Database ناموفق
- Dependency نصب نشده
- Command اشتباه
- Gunicorn Module اشتباه
- Database هنوز آماده نیست

---

## ۱۵. Secret برای Backend قابل خواندن نیست

### نشانه

```text
PermissionError
Readable: False
```

### بررسی

```bash
docker compose exec -T backend \
python -c '
import os
p="/run/secrets/db-password"
s=os.stat(p)
print("Process UID:", os.getuid())
print("Process GID:", os.getgid())
print("File UID:", s.st_uid)
print("File GID:", s.st_gid)
print("Mode:", oct(s.st_mode & 0o777))
print("Readable:", os.access(p, os.R_OK))
'
```

خروجی صحیح:

```text
Process UID: 10001
Process GID: 10001
File UID: 0
File GID: 10001
Mode: 0o640
Readable: True
```

### اصلاح

```bash
sudo chown root:10001 secrets/db_password.txt
sudo chmod 0640 secrets/db_password.txt
```

سپس:

```bash
docker compose up \
  -d \
  --force-recreate \
  --wait \
  --wait-timeout 180 \
  backend proxy
```

---

## ۱۶. Backend با UID/GID اشتباه اجرا می‌شود

### نشانه

```text
uid=999
gid=999
```

درحالی‌که Secret برای `10001` تنظیم شده است.

### علت

Dockerfile از `--system` بدون UID/GID ثابت استفاده کرده یا Image قدیمی Cache شده است.

### Dockerfile صحیح

```dockerfile
RUN groupadd --gid 10001 appgroup \
    && useradd \
       --uid 10001 \
       --gid 10001 \
       --home-dir /app \
       --no-create-home \
       --no-log-init \
       --shell /usr/sbin/nologin \
       appuser
```

### Rebuild

```bash
docker compose build \
  --no-cache \
  --pull \
  backend
```

بررسی Image:

```bash
docker run \
  --rm \
  --entrypoint /usr/bin/id \
  nginx-flask-mysql-backend:1.0
```

انتظار:

```text
uid=10001(appuser) gid=10001(appgroup)
```

---

## ۱۷. SELinux و Bind Mount

### نشانه

Permissionها ظاهراً درست‌اند ولی Container هنوز فایل را نمی‌خواند.

### بررسی

روی AlmaLinux:

```bash
getenforce
ls -lZ secrets/db_password.txt
```

### راه‌حل آزمایشی

```bash
sudo chcon -t container_file_t secrets/db_password.txt
```

برای Configuration دائمی در محیط واقعی از Policy یا `semanage fcontext` استفاده شود.

---

## ۱۸. MariaDB Access Denied بعد از تغییر Password

### نشانه

```text
Access denied for user 'root'
```

### علت

Volume دیتابیس قبلاً با Password دیگری Initialize شده است ولی فایل Secret تغییر کرده است.

Environment Variableهای Initialization فقط در اولین ساخت دیتابیس اعمال می‌شوند.

### راه‌حل ایمن

Secret قبلی را بازیابی یا Password دیتابیس را داخل MariaDB هماهنگ کنید.

### Reset فقط برای Lab

> این عملیات تمام داده‌های MariaDB را حذف می‌کند.

```bash
docker compose down
docker volume ls | grep db-data
docker volume rm <exact-volume-name>
docker compose up -d --wait --wait-timeout 180
```

---

## ۱۹. هشدار MariaDB `io_uring`

### نشانه

```text
io_uring_queue_init() failed
falling back to libaio
```

### معنی

MariaDB نتوانسته از io_uring استفاده کند و به Linux AIO بازگشته است.

اگر Database در وضعیت `ready for connections` و `healthy` است، این Warning به‌تنهایی Failure محسوب نمی‌شود.

### بررسی

```bash
docker compose ps
docker compose logs --tail 100 db
```

---

## ۲۰. پورت 80 یا 443 اشغال است

### نشانه

```text
address already in use
failed to bind host port
```

### بررسی

```bash
sudo ss -ltnp | grep -E ':80 |:443 '

docker ps \
  --format 'table {{.Names}}\t{{.Ports}}'
```

### علت رایج

- `bootstrap-nginx`
- Nginx نصب‌شده روی Host
- Apache
- Stack قدیمی

### راه‌حل

برای Bootstrap Container:

```bash
docker compose \
  -f /opt/bootstrap-nginx/compose.yml \
  down
```

برای Nginx Host:

```bash
sudo systemctl disable --now nginx
```

فقط در صورتی که معماری پروژه Nginx کانتینری باشد.

---

## ۲۱. Nginx Configuration Test شکست می‌خورد

### بررسی

```bash
cd /opt/nginx-flask-mysql

docker compose exec -T proxy nginx -t
```

### علت‌ها

- Syntax اشتباه
- مسیر Certificate اشتباه
- فایل Mount نشده
- Upstream نامعتبر
- Duplicate Listen
- Permission Certificate

### بررسی Mountها

```bash
docker inspect "$(docker compose ps -q proxy)" |
grep -A 30 Mounts
```

---

## ۲۲. پیام Read-only در Nginx Entrypoint

### نشانه

```text
can not modify /etc/nginx/conf.d/default.conf
read-only file system?
```

### علت

Configuration عمداً با `:ro` Mount شده است و Entrypoint رسمی Nginx نمی‌تواند آن را تغییر دهد.

اگر بعد از آن این پیام دیده شود:

```text
Configuration complete; ready for start up
```

و Container Healthy باشد، این پیام به‌تنهایی خطا نیست.

---

## ۲۳. HTTP Redirect کار نمی‌کند

### بررسی

```bash
curl -I http://myapp.test/
```

انتظار:

```text
301
Location: https://myapp.test/
```

### بررسی Domain

```bash
getent hosts myapp.test
```

### بررسی Nginx

```bash
docker compose exec -T proxy nginx -T |
grep -A 20 "listen 80"
```

---

## ۲۴. HTTPS با Curl خطای Certificate می‌دهد

### نشانه

```text
SSL certificate problem: self-signed certificate
```

### علت

Certificate توسط CA مورد اعتماد صادر نشده است.

### تست آزمایشی

```bash
curl -k https://myapp.test/
```

### راه‌حل Production

- Let's Encrypt
- CA سازمانی
- Import کردن CA مورد اعتماد

---

## ۲۵. HTTPS روی IP ولی نه Domain

### بررسی SAN:

```bash
printf '' |
openssl s_client \
  -connect myapp.test:443 \
  -servername myapp.test \
  2>/dev/null |
openssl x509 \
  -noout \
  -ext subjectAltName
```

انتظار:

```text
DNS:myapp.test
IP Address:192.168.200.54
```

در صورت نبود SAN باید Certificate دوباره تولید شود.

---

## ۲۶. Domain Resolve نمی‌شود

### نشانه

```text
Could not resolve host: myapp.test
```

### راه‌حل روی AlmaLinux

```bash
echo "192.168.200.54 myapp.test" |
sudo tee -a /etc/hosts
```

بررسی:

```bash
getent hosts myapp.test
```

روی Windows باید فایل زیر ویرایش شود:

```text
C:\Windows\System32\drivers\etc\hosts
```

---

## ۲۷. Nginx به Backend وصل نمی‌شود

### نشانه

```text
502 Bad Gateway
```

### بررسی

```bash
docker compose ps
docker compose logs --tail 100 backend proxy
```

از داخل Proxy:

```bash
docker compose exec -T proxy \
wget -qO- http://backend:8000/
```

### علت‌ها

- Backend Down
- Network مشترک وجود ندارد
- Port اشتباه
- Service Name اشتباه
- Health Check ناموفق

---

## ۲۸. Database از بیرون قابل دسترسی نیست

این رفتار در معماری فعلی **صحیح** است.

Database Port روی Host منتشر نشده است:

```text
3306 internal only
```

برای تست از Backend Network:

```bash
docker compose exec -T backend \
python -c 'import socket; print(socket.gethostbyname("db"))'
```

---

## ۲۹. داده‌ها بعد از Recreate باقی مانده‌اند

این رفتار به دلیل Named Volume صحیح است.

بررسی:

```bash
docker volume ls | grep db-data
```

برای مشاهده Mount:

```bash
docker inspect "$(docker compose ps -q db)" |
grep -A 20 Mounts
```

---

## ۳۰. داده‌ها ناخواسته حذف شده‌اند

علت محتمل:

```bash
docker compose down --volumes
```

یا حذف دستی Volume.

بازیابی فقط از Backup ممکن است. پروژه فعلی Backup خودکار ندارد.

---

## ۳۱. Playbook در Rescue فقط پیام عمومی می‌دهد

### مشکل

خطای اصلی پشت این پیام پنهان می‌شود:

```text
Application deployment failed
```

### اصلاح

در `rescue` این اطلاعات را چاپ کنید:

```yaml
- name: Display the original deployment failure
  ansible.builtin.debug:
    msg:
      - "Failed task: {{ ansible_failed_task.name | default('unknown') }}"
      - "Message: {{ ansible_failed_result.msg | default('not available') }}"
      - "Command: {{ ansible_failed_result.cmd | default('not available') }}"
      - "Standard error: {{ ansible_failed_result.stderr | default('') }}"
```

---

## ۳۲. Check Mode نتیجه غیرواقعی می‌دهد

Check Mode برای Taskهایی که به تغییر قبلی وابسته‌اند محدودیت دارد.

مثال‌ها:

- Repository هنوز واقعاً ایجاد نشده است.
- Package جدید قابل مشاهده نیست.
- Container واقعاً Start نمی‌شود.
- Live HTTP Test قابل انجام نیست.

راه‌حل:

```bash
ansible-playbook --syntax-check
```

سپس اجرای واقعی در محیط آزمایش.

---

## ۳۳. Reboot Required

بررسی:

```bash
ansible -i inventory deployment_servers \
  -b \
  -m ansible.builtin.stat \
  -a "path=/var/run/reboot-required" \
  --ask-become-pass
```

اگر:

```json
"exists": true
```

ابتدا سرویس‌ها را بررسی و سپس Reboot برنامه‌ریزی‌شده انجام دهید.

اگر:

```json
"exists": false
```

Reboot لازم نیست.

---

## ۳۴. خروجی Playbook با `tee` خطا را پنهان می‌کند

قبل از Pipeline:

```bash
set -o pipefail
```

مثال:

```bash
set -o pipefail

ansible-playbook \
  -i inventory \
  site.yml \
  2>&1 | tee playbook_output.txt
```

---

## ۳۵. دستورهای جمع‌بندی عیب‌یابی

روی Ubuntu:

```bash
cd /opt/nginx-flask-mysql

docker compose config --quiet
docker compose ps --all
docker compose logs --no-color --tail 200
docker compose exec -T proxy nginx -t
docker compose exec -T backend id
sudo ls -ln secrets/db_password.txt
sudo ss -ltnp | grep -E ':80 |:443 '
sudo ufw status verbose
```

روی Controller:

```bash
getent hosts myapp.test
curl -I http://myapp.test/
curl -k -I https://myapp.test/
curl -k -L http://myapp.test/
```

در Ansible:

```bash
ansible -i inventory deployment_servers -m ping

ansible-playbook \
  -i inventory \
  ../08_ansible_automation/site.yml \
  --syntax-check
```
