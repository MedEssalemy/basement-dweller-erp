# Basement Dweller ERP - Odoo 19

Enterprise Resource Planning system built on Odoo 19.

## Local Development (Windows WSL)

### Prerequisites
- WSL2 installed
- Docker Desktop for Windows with WSL2 backend
- Git

### Setup Instructions

1. Clone the repository:
```bash
git clone  basement-dweller-erp
cd basement-dweller-erp
```

2. Copy environment file:
```bash
cp .env.example .env
```

3. Edit `.env` and update passwords

4. Run setup script:
```bash
chmod +x scripts/*.sh
./scripts/setup-local.sh
```

5. Access Odoo at `http://localhost:8069`

### Useful Commands

```bash
# Start containers
docker-compose up -d

# Stop containers
docker-compose down

# View logs
docker-compose logs -f web

# Restart Odoo
docker-compose restart web

# Access Odoo shell
docker exec -it basement-dweller-odoo odoo shell

# Backup database
./scripts/backup.sh
```

## Production Deployment (Digital Ocean)

### Prerequisites
- Digital Ocean Droplet (Ubuntu 22.04)
- Domain pointing to droplet IP: erp.moroccocomputers.com
- SSH access to droplet

### Deployment Steps

1. SSH into your droplet:
```bash
ssh root@your-droplet-ip
```

2. Clone repository:
```bash
cd /opt
git clone  basement-dweller-erp
cd basement-dweller-erp
```

3. Update configuration:
```bash
cp .env.example .env
nano .env  # Update with production credentials
```

4. Update email in deploy script:
```bash
nano scripts/deploy-prod.sh  # Change EMAIL variable
```

5. Run deployment:
```bash
chmod +x scripts/*.sh
./scripts/deploy-prod.sh
```

6. Setup automated backups (cron):
```bash
crontab -e
# Add: 0 2 * * * /opt/basement-dweller-erp/scripts/backup.sh
```

### Post-Deployment

- Access: https://erp.moroccocomputers.com
- Create your first database
- Change master password immediately
- Configure email settings in Odoo

## Custom Addons

Place your custom addons in the `addons/` directory. They will be automatically loaded.

Example structure:
```
addons/
├── my_custom_module/
│   ├── __init__.py
│   ├── __manifest__.py
│   ├── models/
│   ├── views/
│   └── security/
```

## Troubleshooting

### Port already in use
```bash
docker-compose down
sudo lsof -i :8069
sudo kill -9 
```

### Database connection issues
```bash
docker-compose logs db
docker-compose restart db
```

### SSL certificate issues
```bash
sudo certbot renew --dry-run
sudo nginx -t
sudo systemctl restart nginx
```

## Security Checklist

- [ ] Changed default passwords in `.env`
- [ ] Updated `admin_passwd` in `config/odoo.conf`
- [ ] Configured firewall rules
- [ ] SSL certificate installed
- [ ] Regular backups scheduled
- [ ] Database list disabled (`list_db = False`)

## Support

For issues and questions, contact the development team.
```

## Quick Start Commands

### On Windows/WSL:

```bash
# Create project directory
mkdir basement-dweller-erp
cd basement-dweller-erp

# Create all files and directories
# Copy the contents from each section above

# Make scripts executable
chmod +x scripts/*.sh

# Setup and run
./scripts/setup-local.sh
```

### On Digital Ocean Droplet:

```bash
# After SSH into droplet
cd /opt
git clone  basement-dweller-erp
cd basement-dweller-erp
./scripts/deploy-prod.sh
```

## Next Steps

1. Create all files with the content above
2. Initialize git repository
3. Test locally on WSL
4. Push to your git repository
5. Deploy to Digital Ocean
6. Configure DNS for erp.moroccocomputers.com
7. Start developing custom addons!