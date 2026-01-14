#!/usr/bin/env bash
set -e

cd /workspaces/"${localWorkspaceFolderBasename:-gegok12}"

echo ">>> Installing PHP dependencies with Composer..."
if [ -f composer.json ]; then
  composer install
fi

echo ">>> Creating .env from env.production.example (or .env.example)..."
if [ ! -f .env ]; then
  if [ -f env.production.example ]; then
    cp env.production.example .env
  elif [ -f .env.example ]; then
    cp .env.example .env
  fi
fi

echo ">>> Setting up SQLite for demo database..."
if ! grep -q "^DB_CONNECTION=sqlite" .env; then
  {
    echo ""
    echo "DB_CONNECTION=sqlite"
    echo "DB_DATABASE="
  } >> .env
fi

mkdir -p database
touch database/database.sqlite

echo ">>> Generating Laravel APP_KEY..."
php artisan key:generate --force || true

echo ">>> Installing Node.js dependencies..."
if [ -f package.json ]; then
  npm install
fi

echo ">>> Post-create script complete. In the Codespace, run:"
echo "    php artisan migrate --seed"
echo "    php artisan serve --host=0.0.0.0 --port=8000"

