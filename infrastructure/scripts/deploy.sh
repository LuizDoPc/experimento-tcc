#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "Starting deployment..."

echo "Cleaning up macOS metadata files..."
find . -name "._*" -type f -delete 2>/dev/null || true
find . -name ".DS_Store" -type f -delete 2>/dev/null || true

echo "Building all applications..."
bash "$SCRIPT_DIR/build-all.sh"

echo "Starting MySQL if not running..."
sudo systemctl start mysql || true

echo "Verifying MySQL connection..."
mysql -u admin -p123 -e "USE metrics;" || {
    echo "MySQL setup..."
    mysql -e "CREATE DATABASE IF NOT EXISTS metrics;"
    mysql -e "CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY '123';"
    mysql -e "GRANT ALL PRIVILEGES ON metrics.* TO 'admin'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
}

echo "Deployment ready! You can now run the lab client:"
echo "  cd client && ./lab-client"

