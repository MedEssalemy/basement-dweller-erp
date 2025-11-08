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

if [ -z "$POSTGRES_PASSWORD" ]; then
    echo "Error: POSTGRES_PASSWORD variable not set in .env file"
    exit 1
fi

if [ -z "$ADMIN_PASSWORD" ]; then
    echo "Error: ADMIN_PASSWORD variable not set in .env file"
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

# Generate production Odoo config with actual passwords
echo "Generating production Odoo configuration..."
cat > config/odoo.conf <<EOF
[options]
addons_path = /mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons
data_dir = /var/lib/odoo
admin_passwd = ${ADMIN_PASSWORD}
db_host = db
db_port = 5432
db_user = ${POSTGRES_USER:-odoo}
db_password = ${POSTGRES_PASSWORD}
db_name = False
http_port = 8069
longpolling_port = 8072

# Proxy settings
proxy_mode = True
xmlrpc_interface = 127.0.0.1
netrpc_interface = 127.0.0.1

# Performance
workers = 4
max_cron_threads = 2
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200

# Logging
log_level = warn
logfile = /var/log/odoo/odoo.log

# Security
list_db = False
EOF

echo "Generated config/odoo.conf with actual passwords"

# Create log directory
sudo mkdir -p /var/log/odoo
sudo chmod 777 /var/log/odoo

# Start services
echo "Starting Odoo containers..."
docker-compose up -d

# Wait for containers to start
echo "Waiting for containers to initialize..."
sleep 10

# Check container status
docker-compose ps

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
echo "========================================"
echo "Deployment complete!"
echo "========================================"
echo "Access your Odoo instance at: https://$DOMAIN"
echo ""
echo "If you see database connection errors:"
echo "1. Run: docker-compose down"
echo "2. Run: docker volume rm \$(docker volume ls -q | grep basement-dweller)"
echo "3. Run: docker-compose up -d"
echo ""
echo "View logs with: docker-compose logs -f"