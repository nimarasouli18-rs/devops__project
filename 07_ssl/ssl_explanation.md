# توضیح مرحله SSL/TLS

## معماری

در این پروژه Nginx روی Ubuntu Host نصب نشده است و داخل Docker Container اجرا می‌شود. بنابراین:

- Certificateها روی Ubuntu Host تولید و نگهداری می‌شوند.
- Certificate و Private Key به‌صورت Read-only داخل Nginx Container Mount می‌شوند.
- تست Configuration با `nginx -t` داخل Container انجام می‌شود.
- به‌جای `systemctl reload nginx`، سرویس `proxy` با Docker Compose دوباره ایجاد می‌شود.

## Domain و Certificate

Domain آزمایشی:

```text
myapp.test
```

IP سرور:

```text
192.168.200.54
```

Certificate شامل Subject Alternative Nameهای زیر است:

```text
DNS:myapp.test
IP:192.168.200.54
```

وجود SAN باعث می‌شود نام Domain و IP داخل Certificate به‌صورت صریح ثبت شوند.

## فایل‌های Certificate روی Ubuntu

```text
/opt/nginx-flask-mysql/certificates/myapp.test.key
/opt/nginx-flask-mysql/certificates/myapp.test.csr
/opt/nginx-flask-mysql/certificates/myapp.test.crt
/opt/nginx-flask-mysql/certificates/myapp.test.ext
```

Permissionها:

| فایل | Permission |
|---|---:|
| Certificate directory | `0750` |
| Private key | `0600` |
| CSR | `0644` |
| Certificate | `0644` |
| Extensions file | `0644` |

Private Key فقط برای `root` قابل خواندن است.

## مراحل تولید Certificate

### Private Key

Private Key از نوع RSA و با طول ۳۰۷۲ بیت تولید می‌شود:

```text
openssl genrsa
```

### Certificate Signing Request

CSR با الگوریتم SHA-256 و Subject مربوط به `myapp.test` ایجاد می‌شود:

```text
openssl req -new
```

### Self-Signed Certificate

Certificate از CSR تولید و با همان Private Key امضا می‌شود:

```text
openssl x509 -req
```

مدت اعتبار Certificate:

```text
365 days
```

## تنظیمات TLS

پروتکل‌های مجاز:

```text
TLSv1.2
TLSv1.3
```

نسخه‌های قدیمی SSL و TLS فعال نمی‌شوند.

Configuration همچنین شامل موارد زیر است:

- Cipherهای مبتنی بر ECDHE
- غیرفعال‌کردن Session Ticket
- Shared SSL Session Cache
- Session Timeout
- Redirect دائمی HTTP به HTTPS
- Reverse Proxy به `backend:8000`
- Error Handling برای خطاهای Upstream

## Redirect

تمام درخواست‌های HTTP مربوط به Domain آزمایشی با Status Code زیر به HTTPS هدایت می‌شوند:

```text
301 Moved Permanently
```

مقصد:

```text
https://myapp.test
```

## HSTS

در این مرحله HSTS فعال نشده است.

علت این تصمیم آن است که Certificate از نوع Self-Signed است و Browserها به‌صورت پیش‌فرض به آن اعتماد نمی‌کنند. فعال‌کردن HSTS در محیط آزمایشی می‌تواند تست و رفع اشکال را دشوار کند.

## Docker Compose

فایل `docker-compose.ssl.yml` نسخه SSL-enabled فایل Compose است و موارد زیر را اضافه می‌کند:

- انتشار پورت `443`
- Mount کردن Certificate
- Mount کردن Private Key
- Health Check روی HTTPS

این فایل توسط Playbook به‌عنوان فایل اصلی Deployment در مسیر زیر قرار می‌گیرد:

```text
/opt/nginx-flask-mysql/docker-compose.yml
```

## Docker Build Context

پوشه زیر به `.dockerignore` اضافه می‌شود:

```text
certificates/
```

بنابراین Private Key و Certificateها هنگام Build به Docker daemon ارسال نمی‌شوند و وارد Image نمی‌شوند.

## Self-Signed Warning

Certificate توسط CA عمومی صادر نشده است؛ بنابراین Browser هشدار Trust نمایش می‌دهد.

برای تست با Curl از گزینه زیر استفاده می‌شود:

```text
-k
```

یا:

```text
--insecure
```

این گزینه فقط برای محیط آزمایشی مناسب است.

## محیط Production

برای Production باید Self-Signed Certificate با Certificate معتبر صادرشده توسط یک CA مانند Let's Encrypt یا CA سازمانی جایگزین شود.
