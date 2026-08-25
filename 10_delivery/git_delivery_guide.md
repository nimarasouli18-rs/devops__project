# راهنمای Git و تحویل نهایی

## ۱. فایل‌های این مرحله

```text
10_delivery/
├── project_summary.md
├── team_contribution.md
├── git_delivery_guide.md
├── generate_delivery_outputs.sh
├── git_history.txt
└── final_structure.txt
```

دو فایل آخر باید از Repository واقعی تولید شوند:

```text
git_history.txt
final_structure.txt
```

## ۲. قرار دادن `.gitignore`

فایل `.gitignore` موجود در بسته را در Root پروژه قرار دهید:

```bash
cd ~/naserrahmati_kubernetes_02

cp /path/to/stage_10_delivery/.gitignore .gitignore
```

بررسی فایل‌های Ignoreشده:

```bash
git check-ignore -v \
  04_docker/.env \
  04_docker/secrets/db_password.txt \
  03_project_clone/awesome-compose/
```

این فایل‌ها نباید Commit شوند:

```text
04_docker/.env
04_docker/secrets/db_password.txt
Certificate private keys
03_project_clone/awesome-compose/
```

## ۳. Initialize کردن Repository

```bash
cd ~/naserrahmati_kubernetes_02

git init
git branch -M main
```

تنظیم مشخصات Commit:

```bash
git config user.name "YOUR NAME"
git config user.email "YOUR EMAIL"
```

بررسی:

```bash
git config user.name
git config user.email
```

## ۴. بررسی قبل از Add

```bash
git status --short --ignored
```

اطمینان حاصل کنید Secretها با علامت `!!` نمایش داده شوند و در بخش Untracked عادی نباشند.

## ۵. Commitهای پیشنهادی

### Commit اول — Repository و Overview

```bash
git add .gitignore README.md

git commit -m \
  "chore: initialize repository and add project overview"
```

### Commit دوم — Environment

```bash
git add 01_environment

git commit -m \
  "docs(environment): add target server assessment"
```

### Commit سوم — Server Setup

```bash
git add 02_ansible_setup

git commit -m \
  "feat(ansible): add Ubuntu server bootstrap automation"
```

### Commit چهارم — Project Selection

```bash
git add 03_project_clone/project_info.md \
        03_project_clone/project_structure.txt

git commit -m \
  "docs(project): add GitHub application selection analysis"
```

### Commit پنجم — Docker Stack

```bash
git add 04_docker

git commit -m \
  "feat(docker): add containerized Flask MariaDB Nginx stack"
```

### Commit ششم — Deployment

```bash
git add 05_deployment

git commit -m \
  "feat(deploy): add remote application deployment workflow"
```

### Commit هفتم — Nginx

```bash
git add 06_nginx

git commit -m \
  "feat(nginx): add containerized reverse proxy configuration"
```

### Commit هشتم — SSL/TLS

```bash
git add 07_ssl

git commit -m \
  "feat(tls): add self-signed HTTPS configuration"
```

### Commit نهم — End-to-End Automation

```bash
git add 08_ansible_automation

git commit -m \
  "feat(ansible): add end-to-end deployment automation"
```

### Commit دهم — Documentation

```bash
git add 09_documentation

git commit -m \
  "docs: add architecture deployment and troubleshooting guides"
```

### Commit یازدهم — Delivery Documents

```bash
git add 10_delivery/project_summary.md \
        10_delivery/team_contribution.md \
        10_delivery/git_delivery_guide.md \
        10_delivery/generate_delivery_outputs.sh

git commit -m \
  "docs(delivery): add final summary and team contributions"
```

اگر در هر مرحله چیزی برای Commit وجود نداشت، Git پیام `nothing to commit` نمایش می‌دهد؛ این موضوع در صورتی طبیعی است که آن بخش قبلاً Commit شده باشد.

## ۶. تولید خروجی‌های واقعی

```bash
chmod +x 10_delivery/generate_delivery_outputs.sh

./10_delivery/generate_delivery_outputs.sh
```

خروجی‌ها:

```text
10_delivery/git_history.txt
10_delivery/final_structure.txt
```

بررسی:

```bash
cat 10_delivery/git_history.txt
less 10_delivery/final_structure.txt
```

سپس:

```bash
git add \
  10_delivery/git_history.txt \
  10_delivery/final_structure.txt

git commit -m \
  "docs(delivery): add final repository history and structure"
```

نکته: `git_history.txt` تاریخچه Commitهای پیش از Commit خودش را ثبت می‌کند. این رفتار طبیعی است.

## ۷. بررسی نهایی Repository

```bash
git status
```

انتظار:

```text
nothing to commit, working tree clean
```

تاریخچه:

```bash
git log \
  --oneline \
  --graph \
  --decorate \
  --all
```

بررسی Secretهای Trackشده:

```bash
git ls-files |
grep -E '(^|/)\.env$|db_password|\.key$|\.pem$|\.p12$|\.pfx$'
```

در حالت صحیح خروجی نباید Secret واقعی نشان دهد.

بررسی فایل‌های بزرگ:

```bash
find . \
  -path ./.git -prune -o \
  -type f \
  -size +20M \
  -print
```

## ۸. Branching Strategy

Branchهای پیشنهادی:

```text
main
develop
feature/ansible
feature/docker
feature/nginx-ssl
docs/documentation
```

برای پروژه تکمیل‌شده نیازی به بازنویسی مصنوعی History نیست. Commitهای معنی‌دار روی `main` قابل قبول‌اند.

برای توسعه‌های بعدی:

```bash
git switch -c develop
git push -u origin develop
```

ایجاد Feature Branch:

```bash
git switch develop
git switch -c feature/monitoring
```

## ۹. ایجاد Repository در GitHub یا GitLab

یک Repository خالی ایجاد کنید. بهتر است هنگام ساخت Remote Repository گزینه‌های زیر را فعال نکنید:

```text
Initialize with README
Add .gitignore
Add license
```

زیرا فایل‌های محلی از قبل وجود دارند.

## ۱۰. اتصال Remote

SSH:

```bash
git remote add origin \
  git@github.com:USERNAME/REPOSITORY.git
```

یا HTTPS:

```bash
git remote add origin \
  https://github.com/USERNAME/REPOSITORY.git
```

بررسی:

```bash
git remote -v
```

اگر `origin` از قبل وجود داشت:

```bash
git remote set-url origin \
  git@github.com:USERNAME/REPOSITORY.git
```

## ۱۱. Push

```bash
git push -u origin main
```

## ۱۲. Tag نهایی

فقط بعد از اجرای موفق Automation و ثبت `failed=0`:

```bash
git tag -a v1.0.0 \
  -m "Final DevOps project delivery"
```

Push Tag:

```bash
git push origin v1.0.0
```

## ۱۳. خروجی نهایی مورد انتظار

```text
Repository: pushed
Branch: main
Tag: v1.0.0
Working tree: clean
Secrets: not tracked
Meaningful commits: present
git_history.txt: generated
final_structure.txt: generated
```

## ۱۴. چک‌لیست قبل از Push

- [ ] نام اعضای تیم در `team_contribution.md` وارد شده است.
- [ ] آخرین Automation با `failed=0` اجرا شده است.
- [ ] `verification.txt` نتیجه `PASSED` دارد.
- [ ] Secret واقعی Track نشده است.
- [ ] Private Key Track نشده است.
- [ ] `.env.example` وجود دارد.
- [ ] `.env` Track نشده است.
- [ ] Repository خارجی `awesome-compose` Track نشده است.
- [ ] تمام فایل‌های خروجی الزامی وجود دارند.
- [ ] `git status` تمیز است.
- [ ] Remote URL درست است.
- [ ] Branch اصلی `main` است.
- [ ] Tag نهایی پس از Verification ایجاد شده است.
