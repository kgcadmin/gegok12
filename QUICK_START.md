# Quick Start Guide - Deploy GegoK12 to Hostinger VPS

## 🚀 Fast Track Deployment

Follow these steps in order to deploy your GegoK12 application.

---

## Step 1: Prepare Your VPS

1. **SSH into your VPS:**
   ```bash
   ssh root@your-vps-ip
   ```

2. **Upload deployment files to your VPS:**
   - Upload `deploy.sh` to your VPS
   - Or manually follow `DEPLOYMENT_GUIDE.md`

---

## Step 2: Run Automated Deployment (Recommended)

**Option A: Use the automated script**

```bash
# Make script executable
chmod +x deploy.sh

# Edit script variables (domain, database name, etc.)
nano deploy.sh

# Run the script
sudo ./deploy.sh
```

**Option B: Manual deployment**

Follow the detailed steps in `DEPLOYMENT_GUIDE.md`

---

## Step 3: Upload Your Application Code

**If using Git:**
```bash
cd /var/www
sudo git clone https://github.com/your-repo/gegok12.git
sudo chown -R www-data:www-data /var/www/gegok12
```

**If using SFTP:**
- Upload all files to `/var/www/gegok12` using FileZilla or similar
- Set ownership: `sudo chown -R www-data:www-data /var/www/gegok12`

---

## Step 4: Configure Environment

1. **Copy environment template:**
   ```bash
   cd /var/www/gegok12
   sudo cp env.production.example .env
   ```

2. **Edit .env file:**
   ```bash
   sudo nano .env
   ```

3. **Update these REQUIRED values:**
   - `APP_URL=https://yourdomain.com`
   - `DB_DATABASE=your_database_name`
   - `DB_USERNAME=your_database_user`
   - `DB_PASSWORD=your_database_password`
   - `MAIL_*` settings (for email)

4. **Generate app key:**
   ```bash
   sudo php artisan key:generate --force
   ```

---

## Step 5: Install Dependencies & Build

```bash
cd /var/www/gegok12

# PHP dependencies
sudo -u www-data composer install --no-dev --optimize-autoloader

# Node.js dependencies & build
sudo npm ci
sudo npm run production

# Set permissions
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache

# Create storage link
sudo -u www-data php artisan storage:link
```

---

## Step 6: Run Migrations

```bash
cd /var/www/gegok12
sudo -u www-data php artisan migrate --force
```

---

## Step 7: Configure Nginx

1. **Copy Nginx config:**
   ```bash
   sudo nano /etc/nginx/sites-available/gegok12
   ```
   Paste contents from `nginx-config.conf` (replace `yourdomain.com`)

2. **Enable site:**
   ```bash
   sudo ln -s /etc/nginx/sites-available/gegok12 /etc/nginx/sites-enabled/
   sudo rm /etc/nginx/sites-enabled/default
   sudo nginx -t
   sudo systemctl restart nginx
   ```

---

## Step 8: Set Up SSL (HTTPS)

```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Follow prompts and choose to redirect HTTP to HTTPS.

---

## Step 9: Configure Queue Workers

1. **Copy Supervisor config:**
   ```bash
   sudo nano /etc/supervisor/conf.d/gegok12-worker.conf
   ```
   Paste contents from `supervisor-worker.conf`

2. **Start workers:**
   ```bash
   sudo supervisorctl reread
   sudo supervisorctl update
   sudo supervisorctl start gegok12-worker:*
   ```

---

## Step 10: Set Up Scheduler (Cron)

```bash
sudo crontab -e
```

Add this line:
```
* * * * * cd /var/www/gegok12 && php artisan schedule:run >> /dev/null 2>&1
```

---

## Step 11: Cache Configuration

```bash
cd /var/www/gegok12
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan route:cache
sudo -u www-data php artisan view:cache
sudo -u www-data php artisan event:cache
```

---

## Step 12: Verify Deployment

1. **Visit your website:** `https://yourdomain.com`
2. **Check logs if issues:**
   ```bash
   tail -f /var/www/gegok12/storage/logs/laravel.log
   ```
3. **Verify services:**
   ```bash
   sudo systemctl status nginx
   sudo systemctl status php8.1-fpm
   sudo systemctl status mysql
   sudo supervisorctl status
   ```

---

## ✅ Post-Deployment Checklist

Use `POST_DEPLOYMENT.md` for a complete verification checklist.

---

## 🆘 Troubleshooting

### 500 Error?
```bash
# Check logs
tail -f /var/www/gegok12/storage/logs/laravel.log

# Fix permissions
sudo chown -R www-data:www-data /var/www/gegok12/storage
sudo chmod -R 775 /var/www/gegok12/storage

# Clear caches
cd /var/www/gegok12
php artisan config:clear
php artisan cache:clear
```

### Database Error?
```bash
# Test connection
mysql -u your_db_user -p your_database_name

# Check .env file
cat /var/www/gegok12/.env | grep DB_
```

### Assets Not Loading?
```bash
cd /var/www/gegok12
npm run production
php artisan storage:link
```

---

## 📚 Full Documentation

- **Complete Guide:** `DEPLOYMENT_GUIDE.md`
- **Post-Deployment:** `POST_DEPLOYMENT.md`
- **Nginx Config:** `nginx-config.conf`
- **Supervisor Config:** `supervisor-worker.conf`
- **Environment Template:** `env.production.example`

---

## 🎉 You're Done!

Your GegoK12 application should now be live at `https://yourdomain.com`

For support, visit: https://docs.gegok12.com
