# مستند معماری پروژه

## ۱. هدف معماری

هدف این معماری، استقرار یک Web Application چندلایه به‌صورت:

- قابل تکرار
- قابل تست
- ایزوله
- خودکار
- دارای Persistence
- دارای Reverse Proxy
- دارای HTTPS
- قابل مدیریت با Ansible

است.

معماری از جداسازی Controller و Target استفاده می‌کند. فایل‌های پروژه، Playbookها و Templateها روی AlmaLinux Controller نگهداری می‌شوند و عملیات Deployment از طریق SSH روی Ubuntu Target اجرا می‌شود.

## ۲. نمای سطح بالا

```text
+------------------------------+
| AlmaLinux Controller         |
|------------------------------|
| Git                          |
| Ansible                      |
| Python 3.12                  |
| Project Files                |
| Templates                    |
| Verification Outputs         |
+---------------+--------------+
                |
                | SSH / Ansible
                | TCP 22
                v
+------------------------------+
| Ubuntu 22.04 Target          |
|------------------------------|
| Docker Engine                |
| Docker Compose               |
| UFW                          |
| /opt/nginx-flask-mysql       |
+---------------+--------------+
                |
                | Docker Compose
                v
+---------------------------------------------------------+
|                    Application Stack                    |
|                                                         |
|  +------------------+       +------------------------+  |
|  | Nginx Proxy      | ----> | Flask + Gunicorn      |  |
|  | :80 / :443       |       | :8000 internal       |  |
|  +------------------+       +-----------+------------+  |
|          |                              |               |
|          | frontnet                     | backnet       |
|          |                              v               |
|          |                    +----------------------+  |
|          |                    | MariaDB              |  |
|          |                    | :3306 internal      |  |
|          |                    +----------+-----------+  |
|          |                               |              |
|          |                               v              |
|          |                         Named Volume         |
+---------------------------------------------------------+
```

## ۳. اجزای معماری

### ۳.۱. AlmaLinux Controller

وظایف:

- نگهداری Repository پروژه
- اجرای Git
- نگهداری Inventory
- اجرای Playbookها
- Render کردن Templateها
- انتقال فایل‌ها
- جمع‌آوری خروجی‌ها
- اجرای Verification از خارج سرور مقصد

اجزای مهم:

```text
Ansible Community 14.3.1
Ansible Core 2.21.3
Python 3.12.13
```

### ۳.۲. Ubuntu Target Server

مشخصات:

```text
OS: Ubuntu 22.04.5 LTS
Hostname: local20054
IP: 192.168.200.54
SSH User: rahmati
```

وظایف:

- اجرای Docker daemon
- نگهداری فایل‌های Deployment
- اجرای Containerها
- نگهداری Volume دیتابیس
- نگهداری Secret و Certificate
- ارائه HTTP و HTTPS

### ۳.۳. Docker Engine

Docker مرز ایزوله اجرای سرویس‌ها را فراهم می‌کند.

Containerها:

```text
proxy
backend
db
```

### ۳.۴. Docker Compose

Compose مسئول موارد زیر است:

- Build کردن Backend
- Pull کردن Nginx و MariaDB
- تعریف سرویس‌ها
- تعریف Networkها
- تعریف Volume
- تعریف Secret
- تعریف Restart Policy
- تعریف Health Check
- تعیین ترتیب اجرا
- Publish کردن پورت‌های `80` و `443`

### ۳.۵. Nginx Proxy

وظایف:

- Listen روی `80`
- Redirect به HTTPS
- Listen روی `443`
- Load کردن Certificate
- Reverse Proxy به `backend:8000`
- ارسال Headerهای Forwarded
- مدیریت Timeoutها
- مدیریت خطاهای Upstream
- ارائه Endpoint سلامت

Headerها:

```text
Host
X-Real-IP
X-Forwarded-For
X-Forwarded-Proto
X-Forwarded-Host
X-Forwarded-Port
```

### ۳.۶. Flask Backend

Backend با Gunicorn اجرا می‌شود.

ویژگی‌ها:

- Python 3.12
- Flask
- Gunicorn
- Non-root user
- UID/GID ثابت `10001`
- پورت داخلی `8000`
- اتصال به MariaDB از طریق `backnet`
- دریافت Password از `/run/secrets/db-password`

### ۳.۷. MariaDB

ویژگی‌ها:

- MariaDB 10.11
- پورت داخلی `3306`
- عدم Publish پورت روی Host
- Persistent Storage
- Health Check
- Password از Secret
- Database اولیه با نام `example`

### ۳.۸. Named Volume

```text
db-data
```

داده‌های MariaDB را خارج از Lifecycle مربوط به Container نگه می‌دارد.

```text
Container Recreate
        |
        v
Data remains in Named Volume
```

### ۳.۹. Docker Secret

Password در فایل زیر روی Target نگهداری می‌شود:

```text
/opt/nginx-flask-mysql/secrets/db_password.txt
```

مالکیت و Permission:

```text
root:appcontainer
0640
```

Backend با GID برابر `10001` امکان خواندن Secret را دارد.

### ۳.۱۰. SSL/TLS

Certificate از نوع Self-Signed است.

فایل‌ها:

```text
myapp.test.key
myapp.test.csr
myapp.test.crt
myapp.test.ext
```

SANها:

```text
DNS:myapp.test
IP:192.168.200.54
```

پروتکل‌ها:

```text
TLSv1.2
TLSv1.3
```

## ۴. طراحی Network

### ۴.۱. frontnet

اعضا:

```text
proxy
backend
```

Flow:

```text
Nginx --> backend:8000
```

### ۴.۲. backnet

اعضا:

```text
backend
db
```

ویژگی:

```text
internal: true
```

Flow:

```text
Backend --> db:3306
```

### ۴.۳. جداسازی دسترسی

```text
Proxy cannot access Database directly
Database is not exposed to Host
Backend is not exposed to Host
Only Nginx is public
```

## ۵. Flow کامل Request

### ۵.۱. Resolution

```text
myapp.test
    |
    | /etc/hosts
    v
192.168.200.54
```

### ۵.۲. HTTP Request

```text
Client
   |
   | GET http://myapp.test/
   v
Nginx :80
   |
   | 301 Moved Permanently
   v
https://myapp.test/
```

### ۵.۳. TLS

```text
Client
   |
   | TLS Handshake
   v
Nginx :443
   |
   | Self-Signed Certificate
   | CN/SAN = myapp.test
   v
Encrypted HTTP Request
```

### ۵.۴. Reverse Proxy

```text
Nginx
   |
   | proxy_pass http://backend:8000
   | Host: myapp.test
   | X-Real-IP: client-ip
   | X-Forwarded-Proto: https
   v
Flask / Gunicorn
```

### ۵.۵. Database

```text
Flask
   |
   | Read /run/secrets/db-password
   | Connect to db:3306
   v
MariaDB
   |
   | Read/Write
   v
db-data Volume
```

### ۵.۶. Response

```text
MariaDB
   |
   v
Flask HTML Response
   |
   v
Nginx HTTPS Response
   |
   v
Client
```

## ۶. Flow استقرار

```text
1. Ansible reads Inventory
          |
2. SSH connection to Ubuntu
          |
3. Create deployment directories
          |
4. Copy Dockerfile and application code
          |
5. Render .env and docker-compose.yml
          |
6. Generate or preserve DB secret
          |
7. Build Backend image
          |
8. Start MariaDB and Backend
          |
9. Wait for healthy state
          |
10. Generate SSL key, CSR and certificate
          |
11. Render Nginx template
          |
12. Start/Recreate Nginx
          |
13. Test nginx -t
          |
14. Test HTTP 301
          |
15. Test HTTPS 200
          |
16. Write verification.txt
```

## ۷. Health Check Flow

```text
MariaDB starts
      |
      v
healthcheck.sh
      |
      | healthy
      v
Backend starts
      |
      v
Internal HTTP check :8000
      |
      | healthy
      v
Nginx starts
      |
      v
HTTPS health check
      |
      | healthy
      v
Stack Ready
```

## ۸. Security Boundaries

```text
Internet / LAN
      |
      | Only 80 and 443
      v
+-----------------+
| Nginx Boundary  |
+--------+--------+
         |
         | frontnet
         v
+-----------------+
| Backend Boundary|
+--------+--------+
         |
         | backnet internal
         v
+-----------------+
| Database        |
+-----------------+
```

کنترل‌ها:

- UFW
- عدم Publish پورت Database
- عدم Publish پورت Backend
- Internal Network
- Non-root Backend
- Secret خارج از Image
- Private Key با Permission `0600`
- Read-only Mountها
- TLS 1.2 و TLS 1.3
- Health Check و Restart Policy

## ۹. Persistence و Lifecycle

```text
docker compose down
        |
        +--> Containers removed
        +--> Networks removed
        +--> db-data remains

docker compose down --volumes
        |
        +--> Containers removed
        +--> Networks removed
        +--> db-data deleted
```

## ۱۰. Failure Handling

Playbookهای Automation از موارد زیر استفاده می‌کنند:

- `assert`
- `register`
- `debug`
- `block`
- `rescue`
- Health Check
- `wait`
- Verification Playbook
- ذخیره Logها

در صورت شکست Deployment:

```text
Failed Task
    |
    v
Rescue Block
    |
    +--> Compose Logs
    +--> Error Details
    +--> Controlled Failure
```

## ۱۱. محدودیت‌ها

- Certificate از نوع Self-Signed است.
- DNS عمومی وجود ندارد و از `/etc/hosts` استفاده می‌شود.
- Backend نمونه آموزشی است.
- Health Check فعلی Backend مسیر اصلی برنامه را فراخوانی می‌کند.
- Registry خارجی برای Imageها استفاده نشده و Backend روی Target Build می‌شود.
- High Availability پیاده‌سازی نشده است.
- Database Backup در Scope فعلی پروژه نیست.

## ۱۲. توسعه‌های آینده

- استفاده از Let's Encrypt
- افزودن CI/CD
- Push کردن Image به Registry
- افزودن Monitoring و Alerting
- افزودن Backup خودکار MariaDB
- افزودن Log Aggregation
- تعریف Route مستقل `/health`
- استفاده از Ansible Vault
- استفاده از Docker Swarm یا Kubernetes
