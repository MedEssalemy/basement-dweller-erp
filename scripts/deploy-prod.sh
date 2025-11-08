#!/bin/bash

set -e

echo "Deploying Odoo 19 to Digital Ocean Droplet"

# Variables
DOMAIN="erp.moroccocomputers.com"
EMAIL="your-email@example.com"  # Change this

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Install Nginx
echo "Installing Nginx..."
sudo apt install -y nginx

# Install Certbot
echo "Installing Certbot..."
sudo apt install -y certbot python3-certbot-nginx

# Copy Nginx configuration
echo "Configuring Nginx..."
sudo cp nginx/odoo.conf /etc/nginx/sites-available/odoo
sudo ln -sf /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Copy production config
echo "Setting up production configuration..."
cp config/odoo-prod.conf config/odoo.conf

# Create log directory
sudo mkdir -p /var/log/odoo
sudo chmod 777 /var/log/odoo

# Start services
echo "Starting Odoo containers..."
docker-compose up -d

# Reload Nginx
sudo systemctl reload nginx

# Setup SSL with Certbot
echo "Setting up SSL certificate..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

# Setup auto-renewal
sudo systemctl enable certbot.timer

# Setup firewall
echo "Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

echo ""
echo "Deployment complete!"
echo "Access your Odoo instance at: https://$DOMAIN"
echo ""
echo "Important: Update the following:"
echo "1. Change passwords in .env file"
echo "2. Update admin_passwd in config/odoo.conf"
echo "3. Update EMAIL in this script for SSL certificates"