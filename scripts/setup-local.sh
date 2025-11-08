#!/bin/bash

echo "Setting up Odoo 19 - basement-dweller-erp for local development"

# Check if .env exists
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "Please edit .env file with your credentials"
fi

# Create necessary directories
mkdir -p addons
mkdir -p config
touch addons/.gitkeep

# Start Docker containers
echo "Starting Docker containers..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10

# Check container status
docker-compose ps

echo ""
echo "Setup complete!"
echo "Access Odoo at: http://localhost:8069"
echo "Default master password: admin (change this in production!)"
echo ""
echo "To view logs: docker-compose logs -f web"
echo "To stop: docker-compose down"