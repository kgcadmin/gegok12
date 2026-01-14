## Running GegoK12 in GitHub Codespaces

This repository is preconfigured to run in **GitHub Codespaces** using the `.devcontainer` setup.

### 1. Open in Codespaces

- From the GitHub repo page, click **Code → Codespaces → Create codespace on main**.
- Wait for the container to build. The post-create script will:
  - Install PHP dependencies (`composer install`)
  - Create `.env` from `env.production.example` (or `.env.example`)
  - Configure **SQLite** as the demo database
  - Create `database/database.sqlite`
  - Generate the Laravel `APP_KEY`
  - Install Node dependencies (`npm install`)

### 2. Run database migrations and seed data

In the Codespaces terminal:

```bash
php artisan migrate --seed
```

> If there are migration errors related to specific database features, share the error and we can adjust the setup.

### 3. Start the Laravel development server

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

Codespaces will auto-forward port **8000** and open the app in a browser tab.

### 4. Frontend assets (if needed)

If you need to rebuild frontend assets:

```bash
npm run dev
```

or for a production build:

```bash
npm run build || npm run production
```

