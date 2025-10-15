#!/bin/bash

# Complete Family Tree Application Deployment
set -e

APP_IP="54.80.125.204"
DB_IP="98.84.157.89"
SSH_KEY="../family-tree-key.pem"

echo "🚀 Deploying Complete Family Tree Application..."

# Create temporary directory for deployment
TEMP_DIR=$(mktemp -d)
echo "📦 Preparing deployment package in $TEMP_DIR"

# Copy all application files
echo "📁 Copying application files..."
cp -r . "$TEMP_DIR/"

# Upload database first if it exists
if [ -f "database/database.sql" ]; then
    echo "🗃️ Updating database..."
    scp -i "$SSH_KEY" database/database.sql ubuntu@$DB_IP:/tmp/database.sql
    ssh -i "$SSH_KEY" ubuntu@$DB_IP "mysql -u root -p1234pass familytreedb < /tmp/database.sql && echo '✅ Database updated'"
fi

# Upload application files
echo "📤 Uploading application to server..."
scp -i "$SSH_KEY" -r "$TEMP_DIR"/* ubuntu@$APP_IP:/tmp/family-tree-app/

# Deploy on server
echo "🔧 Deploying application on server..."
ssh -i "$SSH_KEY" ubuntu@$APP_IP << 'EOF'
set -e

echo "Creating backup..."
sudo cp -r /var/www/html /var/www/html.backup.$(date +%Y%m%d%H%M%S)

echo "Deploying new application..."
sudo rm -rf /var/www/html/*
sudo cp -r /tmp/family-tree-app/* /var/www/html/

# Update database configuration in configs/connection.php if it exists
if [ -f "/var/www/html/configs/connection.php" ]; then
    echo "Updating database configuration..."
    sudo sed -i "s/'HOSTNAME'.*=>.*'.*'/'HOSTNAME' => '98.84.157.89'/" /var/www/html/configs/connection.php
    sudo sed -i "s/'USERNAME'.*=>.*'.*'/'USERNAME' => 'familytreeuser'/" /var/www/html/configs/connection.php
    sudo sed -i "s/'PASSWORD'.*=>.*'.*'/'PASSWORD' => '1234pass'/" /var/www/html/configs/connection.php
    sudo sed -i "s/'DATABASE'.*=>.*'.*'/'DATABASE' => 'familytreedb'/" /var/www/html/configs/connection.php
fi

echo "Setting permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo find /var/www/html -type f -exec chmod 644 {} \;

echo "Restarting Apache..."
sudo systemctl restart apache2

echo "Cleaning up..."
rm -rf /tmp/family-tree-app

echo "✅ Application deployment completed!"
EOF

# Clean up
rm -rf "$TEMP_DIR"

echo "🎉 Complete deployment finished!"
echo "🌐 Access your application: http://$APP_IP"

# Test the deployment
echo ""
echo "🔍 Testing deployment..."
curl -s http://$APP_IP/ | head -10
