#!/bin/bash

set -e

echo "Deploying Odoo 19 to Digital Ocean Droplet"

# Load environment variables from .env file
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    set -a  # Automatically export all variables
    source .env
    set +a  # Stop automatic exporting
else
    echo "Error: .env file not found!"
    echo "Please create a .env file with DOMAIN and EMAIL variables"
    exit 1
fi

# Check if required variables are set
if [ -z "$DOMAIN" ]; then
    echo "Error: DOMAIN variable not set in .env file"
    exit 1
fi

if [ -z "$EMAIL" ]; then
    echo "Error: EMAIL variable not set in .env file"
    exit 1
fi

echo "Using Domain: $DOMAIN"
echo "Using Email: $EMAIL"

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

# Create certbot webroot directory
sudo mkdir -p /var/www/certbot

# Copy Nginx configuration
echo "Configuring Nginx..."
sudo cp nginx/odoo.conf /etc/nginx/sites-available/odoo
sudo ln -sf /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Ensure Nginx is running
echo "Starting Nginx service..."
sudo systemctl enable nginx
sudo systemctl start nginx

# Get SSL certificate
echo "Setting up SSL certificate..."
sudo certbot certonly --webroot -w /var/www/certbot -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

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

# Reload Nginx with SSL configuration
sudo systemctl reload nginx

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