#!/bin/bash

# GegoK12 Automated Deployment Script for Ubuntu 22.04/24.04
# Run this script on your VPS as root or with sudo

set -e  # Exit on error

echo "=========================================="
echo "GegoK12 Deployment Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Variables (customize these)
DOMAIN="yourdomain.com"
DB_NAME="gegok12_db"
DB_USER="gegok12_user"
DB_PASS=""
APP_DIR="/var/www/gegok12"
PHP_VERSION="8.1"

echo -e "${YELLOW}Configuration:${NC}"
echo "Domain: $DOMAIN"
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"
echo "App Directory: $APP_DIR"
echo "PHP Version: $PHP_VERSION"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Step 1: Update system
echo -e "${GREEN}[1/12] Updating system packages...${NC}"
apt update && apt upgrade -y

# Step 2: Install PHP and extensions
echo -e "${GREEN}[2/12] Installing PHP $PHP_VERSION and extensions...${NC}"
apt install -y software-properties-common
add-apt-repository ppa:ondrej/php -y
apt update
apt install -y php${PHP_VERSION} php${PHP_VERSION}-fpm php${PHP_VERSION}-cli php${PHP_VERSION}-common \
    php${PHP_VERSION}-mysql php${PHP_VERSION}-zip php${PHP_VERSION}-gd php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-curl php${PHP_VERSION}-xml php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-intl php${PHP_VERSION}-soap php${PHP_VERSION}-redis

# Step 3: Install Nginx
echo -e "${GREEN}[3/12] Installing Nginx...${NC}"
apt install -y nginx

# Step 4: Install MySQL
echo -e "${GREEN}[4/12] Installing MySQL...${NC}"
apt install -y mysql-server

# Step 5: Install Composer
echo -e "${GREEN}[5/12] Installing Composer...${NC}"
if [ ! -f /usr/local/bin/composer ]; then
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
fi

# Step 6: Install Node.js
echo -e "${GREEN}[6/12] Installing Node.js...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
fi

# Step 7: Install Redis
echo -e "${GREEN}[7/12] Installing Redis...${NC}"
apt install -y redis-server
systemctl enable redis-server
systemctl start redis-server

# Step 8: Install Certbot
echo -e "${GREEN}[8/12] Installing Certbot...${NC}"
apt install -y certbot python3-certbot-nginx

# Step 9: Install Supervisor
echo -e "${GREEN}[9/12] Installing Supervisor...${NC}"
apt install -y supervisor

# Step 10: Create database
echo -e "${GREEN}[10/12] Setting up database...${NC}"
if [ -z "$DB_PASS" ]; then
    read -sp "Enter database password: " DB_PASS
    echo
fi

mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo -e "${GREEN}Database created successfully!${NC}"

# Step 11: Check if app directory exists
echo -e "${GREEN}[11/12] Checking application directory...${NC}"
if [ ! -d "$APP_DIR" ]; then
    echo -e "${YELLOW}Application directory not found at $APP_DIR${NC}"
    echo "Please upload your code to $APP_DIR first, then run this script again."
    echo "Or clone from Git:"
    echo "  cd /var/www"
    echo "  git clone https://github.com/your-repo/gegok12.git"
    exit 1
fi

# Step 12: Configure Laravel
echo -e "${GREEN}[12/12] Configuring Laravel application...${NC}"
cd $APP_DIR

# Set ownership
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
    else
        echo -e "${RED}.env.example not found!${NC}"
        exit 1
    fi
fi

# Set permissions for storage and cache
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Install dependencies
echo "Installing PHP dependencies..."
sudo -u www-data composer install --no-dev --optimize-autoloader

echo "Installing Node.js dependencies..."
npm ci

echo "Building frontend assets..."
npm run production

# Generate app key if not set
if ! grep -q "APP_KEY=base64:" .env; then
    sudo -u www-data php artisan key:generate --force
fi

# Create storage link
sudo -u www-data php artisan storage:link

echo ""
echo -e "${YELLOW}=========================================="
echo "Manual Steps Required:"
echo "==========================================${NC}"
echo ""
echo "1. Edit .env file:"
echo "   nano $APP_DIR/.env"
echo ""
echo "   Update these values:"
echo "   - APP_URL=https://$DOMAIN"
echo "   - DB_DATABASE=$DB_NAME"
echo "   - DB_USERNAME=$DB_USER"
echo "   - DB_PASSWORD=$DB_PASS"
echo ""
echo "2. Run migrations:"
echo "   cd $APP_DIR"
echo "   sudo -u www-data php artisan migrate --force"
echo ""
echo "3. Cache configuration:"
echo "   sudo -u www-data php artisan config:cache"
echo "   sudo -u www-data php artisan route:cache"
echo "   sudo -u www-data php artisan view:cache"
echo ""
echo "4. Configure Nginx (see nginx-config.conf)"
echo ""
echo "5. Set up SSL:"
echo "   sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo ""
echo -e "${GREEN}Deployment script completed!${NC}"
