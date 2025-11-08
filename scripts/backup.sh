#!/bin/bash

BACKUP_DIR="/var/backups/odoo"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
echo "Backing up database..."
docker exec basement-dweller-db pg_dumpall -U odoo > $BACKUP_DIR/db_backup_$TIMESTAMP.sql

# Backup filestore
echo "Backing up filestore..."
docker cp basement-dweller-odoo:/var/lib/odoo $BACKUP_DIR/filestore_$TIMESTAMP

# Compress backups
echo "Compressing backups..."
tar -czf $BACKUP_DIR/odoo_backup_$TIMESTAMP.tar.gz -C $BACKUP_DIR db_backup_$TIMESTAMP.sql filestore_$TIMESTAMP
rm -rf $BACKUP_DIR/db_backup_$TIMESTAMP.sql $BACKUP_DIR/filestore_$TIMESTAMP

# Keep only last 7 days of backups
find $BACKUP_DIR -name "odoo_backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR/odoo_backup_$TIMESTAMP.tar.gz"