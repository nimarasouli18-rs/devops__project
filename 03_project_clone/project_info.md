# اطلاعات پروژه انتخاب‌شده

## آدرس Repository
https://github.com/docker/awesome-compose/tree/master/nginx-flask-mysql

## توضیح پروژه
یک اپلیکیشن نمونه شامل سه بخش:
- backend: اپلیکیشن Flask (پایتون) که یک صفحه ساده وبلاگ برمی‌گرداند
- db: پایگاه‌داده MariaDB برای ذخیره پست‌های وبلاگ
- proxy: یک Nginx کانتینری (که در این پروژه استفاده نمی‌شود،
  چون طبق فاز 5-6 پروژه، Nginx باید روی خود سرور (host) نصب و
  با SSL پیکربندی شود، نه داخل کانتینر)

## تکنولوژی‌های استفاده‌شده
- Python 3.13 (Flask 3.1.2)
- MariaDB 10 (سازگار با MySQL)
- Docker / Docker Compose
- Docker Secrets (برای مدیریت امن پسورد دیتابیس)

## Dependencies (از backend/requirements.txt)
- Flask==3.1.2
- mysql-connector==2.2.9

## Ports مورد استفاده
- Flask backend: 8000 (داخلی)
- MariaDB: 3306, 33060 (فقط داخل شبکه Docker، expose نشده به host)
- (سرویس proxy اصلی که پورت 80 را می‌گرفت، حذف می‌شود)

## نکات فنی مهم که بررسی شد
- اتصال به دیتابیس با کتابخانه mysql-connector و از طریق فایل
  Docker Secret در مسیر /run/secrets/db-password انجام می‌شود
  (نه از طریق environment variable ساده) — روش امنیتی مناسبی است
- Dockerfile موجود در backend/ از multi-stage build و BuildKit
  cache mount استفاده می‌کند که یک best practice شناخته‌شده است
