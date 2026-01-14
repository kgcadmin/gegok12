# Post-Deployment Checklist

Use this checklist to verify your GegoK12 deployment is working correctly.

## ✅ Basic Functionality

- [ ] **Website loads** - Visit `https://yourdomain.com` and verify the site loads
- [ ] **HTTPS works** - Check that SSL certificate is valid (green padlock in browser)
- [ ] **No 500 errors** - Check browser console and Laravel logs for errors
- [ ] **Assets load** - CSS, JavaScript, and images should load correctly

## ✅ Database

- [ ] **Database connection** - Verify database connection in Laravel logs
- [ ] **Migrations ran** - Check that all migrations were executed successfully
- [ ] **Tables exist** - Verify database tables were created:
  ```bash
  mysql -u your_db_user -p your_database_name -e "SHOW TABLES;"
  ```

## ✅ File Permissions

- [ ] **Storage writable** - Verify Laravel can write to storage:
  ```bash
  ls -la /var/www/gegok12/storage
  # Should show www-data ownership and 775 permissions
  ```
- [ ] **Logs directory** - Check that logs can be written:
  ```bash
  tail -f /var/www/gegok12/storage/logs/laravel.log
  ```

## ✅ Services Status

- [ ] **Nginx running** - `sudo systemctl status nginx`
- [ ] **PHP-FPM running** - `sudo systemctl status php8.1-fpm`
- [ ] **MySQL running** - `sudo systemctl status mysql`
- [ ] **Redis running** - `sudo systemctl status redis-server`
- [ ] **Queue workers running** - `sudo supervisorctl status`

## ✅ Laravel Configuration

- [ ] **App key generated** - Check `.env` has `APP_KEY=base64:...`
- [ ] **Config cached** - Run `php artisan config:cache`
- [ ] **Routes cached** - Run `php artisan route:cache`
- [ ] **Views cached** - Run `php artisan view:cache`
- [ ] **Debug mode OFF** - Verify `APP_DEBUG=false` in `.env`

## ✅ Email Configuration

- [ ] **SMTP configured** - Test sending an email from the application
- [ ] **Mail credentials correct** - Verify SMTP settings in `.env`
- [ ] **Gmail App Password** - If using Gmail, ensure App Password is set (not regular password)

## ✅ Queue & Scheduler

- [ ] **Queue workers** - Check Supervisor is running queue workers:
  ```bash
  sudo supervisorctl status gegok12-worker:*
  ```
- [ ] **Scheduler configured** - Verify cron job is set:
  ```bash
  crontab -l | grep schedule:run
  ```

## ✅ Security

- [ ] **Firewall configured** - Only necessary ports are open:
  ```bash
  sudo ufw status
  ```
- [ ] **SSL certificate valid** - Check certificate expiry:
  ```bash
  sudo certbot certificates
  ```
- [ ] **Auto-renewal enabled** - SSL certificates should auto-renew
- [ ] **.env file protected** - Verify `.env` is not publicly accessible
- [ ] **Storage link created** - `php artisan storage:link` was executed

## ✅ Performance

- [ ] **Cache working** - Verify Redis cache is functioning:
  ```bash
  redis-cli ping
  # Should return: PONG
  ```
- [ ] **Assets optimized** - Frontend assets should be minified (check browser Network tab)
- [ ] **Gzip enabled** - Verify Nginx gzip compression is working

## ✅ Logs

- [ ] **Laravel logs accessible** - Check `/var/www/gegok12/storage/logs/laravel.log`
- [ ] **Nginx logs accessible** - Check `/var/log/nginx/access.log` and `error.log`
- [ ] **PHP-FPM logs accessible** - Check `/var/log/php8.1-fpm.log`
- [ ] **No critical errors** - Review all logs for errors or warnings

## ✅ Optional Services

If you're using these services, verify they're configured:

- [ ] **AWS S3** - File uploads to S3 work correctly
- [ ] **Firebase** - Push notifications work (if enabled)
- [ ] **Pusher** - Real-time features work (if enabled)
- [ ] **Twilio** - SMS notifications work (if enabled)
- [ ] **Algolia** - Search functionality works (if enabled)

## ✅ Backup Strategy

- [ ] **Database backup script** - Set up automated database backups
- [ ] **File backup** - Plan for backing up `/var/www/gegok12` directory
- [ ] **Backup storage** - Decide where backups will be stored (external drive, cloud, etc.)

## ✅ Monitoring

- [ ] **Server monitoring** - Set up monitoring (optional: UptimeRobot, Pingdom, etc.)
- [ ] **Error tracking** - Consider error tracking service (Sentry, Bugsnag, etc.)
- [ ] **Log rotation** - Verify log rotation is configured to prevent disk space issues

## Common Issues & Solutions

### Issue: 500 Internal Server Error
**Solution:**
```bash
# Check Laravel logs
tail -f /var/www/gegok12/storage/logs/laravel.log

# Clear caches
cd /var/www/gegok12
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

# Re-cache
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### Issue: Database Connection Error
**Solution:**
```bash
# Test database connection
mysql -u your_db_user -p your_database_name

# Verify credentials in .env
cat /var/www/gegok12/.env | grep DB_

# Check MySQL is running
sudo systemctl status mysql
```

### Issue: Permission Denied Errors
**Solution:**
```bash
cd /var/www/gegok12
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
```

### Issue: Assets Not Loading
**Solution:**
```bash
cd /var/www/gegok12
npm run production
php artisan storage:link
```

### Issue: Queue Not Processing
**Solution:**
```bash
# Check Supervisor status
sudo supervisorctl status

# Restart workers
sudo supervisorctl restart gegok12-worker:*

# Check logs
tail -f /var/www/gegok12/storage/logs/worker.log
```

## Next Steps

After completing this checklist:

1. **Test all features** - Log in and test core functionality
2. **Set up monitoring** - Configure uptime monitoring
3. **Create backups** - Set up automated backup system
4. **Document credentials** - Store all passwords securely (password manager)
5. **Review security** - Ensure all security best practices are followed

## Support Resources

- **GegoK12 Documentation:** https://docs.gegok12.com
- **Laravel Documentation:** https://laravel.com/docs
- **Nginx Documentation:** https://nginx.org/en/docs/
- **Server Logs:** `/var/www/gegok12/storage/logs/laravel.log`

---

**Deployment Complete!** 🎉

If everything checks out, your GegoK12 application should be fully operational.
