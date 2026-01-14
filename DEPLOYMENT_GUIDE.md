# GegoK12 Deployment Guide for Hostinger VPS

This guide will help you deploy GegoK12 to your Hostinger VPS running Ubuntu 22.04/24.04.

## Prerequisites

- ✅ Ubuntu 22.04 or 24.04 VPS
- ✅ Domain name pointed to your VPS IP
- ✅ SSH access to your VPS
- ✅ Root or sudo access

---

## Step 1: Connect to Your VPS

SSH into your VPS:

```bash
ssh root@your-vps-ip
# or
ssh your-username@your-vps-ip
```

---

## Step 2: Update System & Install Required Software

Run these commands to update your system and install all required packages:

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install PHP 8.1+ and required extensions
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y php8.1 php8.1-fpm php8.1-cli php8.1-common php8.1-mysql \
    php8.1-zip php8.1-gd php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath \
    php8.1-intl php8.1-soap php8.1-redis

# Install Nginx
sudo apt install -y nginx

# Install MySQL/MariaDB
sudo apt install -y mysql-server

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer

# Install Node.js 18.x (for building frontend assets)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Git (if not already installed)
sudo apt install -y git

# Install Redis (for caching/queues)
sudo apt install -y redis-server

# Install Certbot (for SSL certificates)
sudo apt install -y certbot python3-certbot-nginx

# Install Supervisor (for queue workers)
sudo apt install -y supervisor
```

---

## Step 3: Configure MySQL Database

1. **Secure MySQL installation:**
```bash
sudo mysql_secure_installation
```
   - Set root password (or press Enter if using auth_socket)
   - Answer Y to all security questions

2. **Create database and user:**
```bash
sudo mysql -u root -p
```

Then run these SQL commands (replace `your_database_name`, `your_db_user`, `your_db_password`):

```sql
CREATE DATABASE your_database_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'your_db_user'@'localhost' IDENTIFIED BY 'your_db_password';
GRANT ALL PRIVILEGES ON your_database_name.* TO 'your_db_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

**Note:** Save these credentials - you'll need them for the `.env` file!

---

## Step 4: Upload Your Application Code

### Option A: Using Git (Recommended)

```bash
# Navigate to web directory
cd /var/www

# Clone your repository (replace with your repo URL)
sudo git clone https://github.com/your-username/gegok12.git
# OR if you have a private repo:
# sudo git clone https://github.com/your-username/gegok12.git

# Set ownership
sudo chown -R www-data:www-data /var/www/gegok12
sudo chmod -R 755 /var/www/gegok12
```

### Option B: Using SFTP/FileZilla

1. Connect to your VPS via SFTP using FileZilla or similar
2. Upload all files to `/var/www/gegok12`
3. Set permissions:
```bash
sudo chown -R www-data:www-data /var/www/gegok12
sudo chmod -R 755 /var/www/gegok12
```

---

## Step 5: Configure Environment Variables

1. **Copy the environment file:**
```bash
cd /var/www/gegok12
sudo cp .env.example .env
```

2. **Edit the `.env` file:**
```bash
sudo nano .env
```

3. **Update these critical variables:**

```env
APP_NAME="GegoK12"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://yourdomain.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=your_database_name
DB_USERNAME=your_db_user
DB_PASSWORD=your_db_password

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@yourdomain.com
MAIL_FROM_NAME="${APP_NAME}"
```

**Important:** 
- Replace `yourdomain.com` with your actual domain
- Replace database credentials with what you created in Step 3
- For Gmail SMTP, you'll need an [App Password](https://support.google.com/accounts/answer/185833)

4. **Generate application key:**
```bash
cd /var/www/gegok12
sudo php artisan key:generate --force
```

---

## Step 6: Install Dependencies

```bash
cd /var/www/gegok12

# Install PHP dependencies
sudo -u www-data composer install --no-dev --optimize-autoloader

# Install Node.js dependencies
sudo npm ci

# Build frontend assets
sudo npm run production
```

---

## Step 7: Configure Laravel

```bash
cd /var/www/gegok12

# Set proper permissions
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache

# Create storage link
sudo -u www-data php artisan storage:link

# Run database migrations
sudo -u www-data php artisan migrate --force

# Cache configuration for production
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan route:cache
sudo -u www-data php artisan view:cache
sudo -u www-data php artisan event:cache
```

**Note:** If you need to seed initial data, run:
```bash
sudo -u www-data php artisan db:seed --force
```

---

## Step 8: Configure Nginx

1. **Create Nginx configuration file:**
```bash
sudo nano /etc/nginx/sites-available/gegok12
```

2. **Paste this configuration** (replace `yourdomain.com` with your domain):

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name yourdomain.com www.yourdomain.com;
    root /var/www/gegok12/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

3. **Enable the site:**
```bash
sudo ln -s /etc/nginx/sites-available/gegok12 /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default  # Remove default site
```

4. **Test Nginx configuration:**
```bash
sudo nginx -t
```

5. **Restart Nginx:**
```bash
sudo systemctl restart nginx
```

---

## Step 9: Set Up SSL Certificate (HTTPS)

```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Follow the prompts:
- Enter your email address
- Agree to terms
- Choose whether to redirect HTTP to HTTPS (recommended: Yes)

Certbot will automatically configure SSL and renew certificates.

---

## Step 10: Configure Queue Worker (Supervisor)

1. **Create Supervisor configuration:**
```bash
sudo nano /etc/supervisor/conf.d/gegok12-worker.conf
```

2. **Paste this configuration:**
```ini
[program:gegok12-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/gegok12/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/gegok12/storage/logs/worker.log
stopwaitsecs=3600
```

3. **Reload Supervisor:**
```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start gegok12-worker:*
```

---

## Step 11: Set Up Laravel Scheduler (Cron)

```bash
sudo crontab -e
```

Add this line at the end:
```cron
* * * * * cd /var/www/gegok12 && php artisan schedule:run >> /dev/null 2>&1
```

---

## Step 12: Configure Firewall

```bash
# Allow SSH, HTTP, and HTTPS
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
sudo ufw status
```

---

## Step 13: Final Checks

1. **Test your application:**
   - Visit `https://yourdomain.com` in your browser
   - Check if the site loads correctly

2. **Check logs if there are issues:**
```bash
# Laravel logs
tail -f /var/www/gegok12/storage/logs/laravel.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log

# PHP-FPM logs
sudo tail -f /var/log/php8.1-fpm.log
```

3. **Verify services are running:**
```bash
sudo systemctl status nginx
sudo systemctl status php8.1-fpm
sudo systemctl status mysql
sudo systemctl status redis
sudo supervisorctl status
```

---

## Troubleshooting

### 500 Internal Server Error
- Check file permissions: `sudo chown -R www-data:www-data /var/www/gegok12`
- Check Laravel logs: `tail -f /var/www/gegok12/storage/logs/laravel.log`
- Clear caches: `php artisan config:clear && php artisan cache:clear`

### Database Connection Error
- Verify database credentials in `.env`
- Check MySQL is running: `sudo systemctl status mysql`
- Test connection: `mysql -u your_db_user -p your_database_name`

### Permission Denied Errors
- Fix storage permissions: `sudo chmod -R 775 storage bootstrap/cache`
- Ensure ownership: `sudo chown -R www-data:www-data storage bootstrap/cache`

### Assets Not Loading
- Rebuild assets: `npm run production`
- Clear browser cache
- Check `public` directory permissions

---

## Post-Deployment Checklist

See `POST_DEPLOYMENT.md` for a complete checklist of things to verify after deployment.

---

## Security Recommendations

1. **Keep software updated:**
```bash
sudo apt update && sudo apt upgrade -y
```

2. **Set up automatic security updates:**
```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

3. **Regular backups:**
   - Database: `mysqldump -u user -p database_name > backup.sql`
   - Files: Backup `/var/www/gegok12` directory

4. **Monitor logs regularly:**
```bash
# Set up log rotation
sudo logrotate -d /etc/logrotate.d/nginx
```

---

## Need Help?

- Check the official documentation: https://docs.gegok12.com
- Review Laravel deployment docs: https://laravel.com/docs/deployment
- Check application logs in `/var/www/gegok12/storage/logs/`

---

**Congratulations!** Your GegoK12 application should now be live! 🎉
