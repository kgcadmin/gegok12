# Testing GegoK12 ERP Application

## Option 1: Test in GitHub Codespaces (Recommended - Easiest)

### Step 1: Open in Codespaces
1. Go to your GitHub repository: `https://github.com/kgcadmin/gegok12`
2. Click the green **"Code"** button
3. Select **"Codespaces"** tab
4. Click **"Create codespace on main"**
5. Wait 2-3 minutes for the container to build and setup

### Step 2: Run Database Migrations
Once the Codespace opens, open the terminal and run:
```bash
php artisan migrate --seed
```

### Step 3: Start the Server
```bash
php artisan serve --host=0.0.0.0 --port=8000
```

### Step 4: Access Your App
- Codespaces will automatically forward port 8000
- A popup will appear asking to open in browser - click **"Open in Browser"**
- Or manually open: `https://<your-codespace-name>-8000.app.github.dev`

**That's it!** Your app is now running and accessible via web browser.

---

## Option 2: Test Locally on Windows

### Prerequisites to Install:
1. **PHP 8.1+** - Download from https://windows.php.net/download/
2. **Composer** - Download from https://getcomposer.org/download/
3. **MySQL/MariaDB** or **SQLite** (for database)
4. **Node.js** ✅ (Already installed: v22.16.0)

### Step 1: Install PHP
1. Download PHP 8.1+ ZIP from https://windows.php.net/download/
2. Extract to `C:\php`
3. Add `C:\php` to your Windows PATH environment variable
4. Verify: Open PowerShell and run `php --version`

### Step 2: Install Composer
1. Download Composer-Setup.exe from https://getcomposer.org/download/
2. Run the installer
3. Verify: Run `composer --version` in PowerShell

### Step 3: Install Database
**Option A: SQLite (Easiest for testing)**
- SQLite comes with PHP, no extra installation needed

**Option B: MySQL**
- Download XAMPP (includes MySQL): https://www.apachefriends.org/
- Or install MySQL separately: https://dev.mysql.com/downloads/

### Step 4: Setup the Application

Open PowerShell in the project directory:
```powershell
cd c:\Users\kumar\Downloads\ERP1.1

# Install PHP dependencies
composer install

# Copy environment file
copy .env.example .env

# Edit .env file - set database connection
# For SQLite:
# DB_CONNECTION=sqlite
# DB_DATABASE=

# For MySQL:
# DB_CONNECTION=mysql
# DB_HOST=127.0.0.1
# DB_PORT=3306
# DB_DATABASE=gegok12
# DB_USERNAME=root
# DB_PASSWORD=

# Generate app key
php artisan key:generate

# Create SQLite database (if using SQLite)
New-Item -ItemType File -Path database\database.sqlite -Force

# Run migrations
php artisan migrate --seed

# Install Node dependencies
npm install

# Build frontend assets (optional, for production)
npm run dev
# or
npm run production
```

### Step 5: Start the Server
```powershell
php artisan serve
```

### Step 6: Access Your App
Open browser and go to: **http://localhost:8000**

---

## Option 3: Deploy to Production Server

See `QUICK_START.md` for VPS deployment instructions.

---

## Troubleshooting

### Port Already in Use?
If port 8000 is busy, use a different port:
```bash
php artisan serve --port=8080
```

### Database Connection Error?
- Check your `.env` file database settings
- Make sure MySQL is running (if using MySQL)
- For SQLite, ensure `database/database.sqlite` file exists

### Permission Errors?
On Windows, you may need to run PowerShell as Administrator for some commands.

### Need Help?
Check the logs: `storage/logs/laravel.log`
