#!/bin/bash

# Quick deployment script for Family Tree App
set -e

APP_IP="54.80.125.204"
DB_IP="98.84.157.89"
SSH_KEY="../family-tree-key.pem"

echo "🚀 Quick deploying Family Tree Application..."

# Deploy database if sql file exists
if [ -f "src/database/database.sql" ]; then
    echo "📦 Updating database..."
    scp -i "$SSH_KEY" src/database/database.sql ubuntu@$DB_IP:/tmp/database.sql
    ssh -i "$SSH_KEY" ubuntu@$DB_IP "mysql -u root -p1234pass familytreedb < /tmp/database.sql && echo '✅ Database updated'"
fi

# Deploy application
echo "📤 Deploying application..."
ssh -i "$SSH_KEY" ubuntu@$APP_IP << 'EOF'
sudo cp -r /var/www/html /var/www/html.backup.$(date +%Y%m%d%H%M%S)
sudo rm -rf /var/www/html/*
sudo cp -r /tmp/deploy/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo systemctl restart apache2
echo "✅ Application deployed"
EOF

echo "🎉 Quick deployment completed! Access: http://$APP_IP"
