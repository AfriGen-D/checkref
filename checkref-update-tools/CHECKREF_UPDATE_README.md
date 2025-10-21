# Checkref Update Scripts

This directory (`/home/ubuntu/devs/checkref/checkref-update-tools`) contains scripts to easily update the Allele Switch Checker (checkref) application from GitHub.

## Quick Access

From anywhere in the system, you can use the wrapper script:

```bash
# From the main imputationserver2 directory
cd /home/ubuntu/imputationserver2
./checkref-tools.sh check          # Check for updates
./checkref-tools.sh update         # Update checkref
./checkref-tools.sh config current # Show current version
```

Or run the scripts directly from this directory:

```bash
cd /home/ubuntu/devs/checkref/checkref-update-tools
./check-checkref-version.sh
./update-checkref.sh
```

## Available Scripts

### 1. `update-checkref.sh` - Full-Featured Update Script

The comprehensive update script with advanced features:

```bash
# Basic update to latest version
./update-checkref.sh

# Update to specific version
./update-checkref.sh -v v1.1.0

# Preview what would be done (dry run)
./update-checkref.sh --dry-run

# Force update without confirmation
./update-checkref.sh -f

# Update without restarting service
./update-checkref.sh --no-restart

# Create backup only
./update-checkref.sh --backup-only

# Rollback to previous version
./update-checkref.sh --rollback

# Show help
./update-checkref.sh --help
```

**Features:**

- ✅ Automatic backup creation
- ✅ Version detection from GitHub
- ✅ Rollback capability
- ✅ Service restart management
- ✅ Comprehensive logging
- ✅ Dry-run mode
- ✅ Error handling and validation

### 2. `quick-update-checkref.sh` - Simple Update Script

Quick and simple update for basic use cases:

```bash
# Quick update to latest main branch
./quick-update-checkref.sh
```

**Features:**

- ✅ Simple one-command update
- ✅ Automatic backup
- ✅ Downloads latest main branch
- ✅ Clear instructions for next steps

### 3. `manage-checkref-config.sh` - Configuration Management

Manage checkref versions in cloudgene configuration:

```bash
# List available versions
./manage-checkref-config.sh list

# Show current active version
./manage-checkref-config.sh current

# Switch to a different version
./manage-checkref-config.sh switch 1.0.0-updated

# Backup configuration
./manage-checkref-config.sh backup

# Restore from backup
./manage-checkref-config.sh restore

# Show help
./manage-checkref-config.sh --help
```

**Features:**

- ✅ List all available checkref versions
- ✅ Switch between versions
- ✅ Configuration backup/restore
- ✅ Validation of version directories

## Quick Start Guide

### Option 1: Simple Update (Recommended for most users)

```bash
# 1. Preview the update
./update-checkref.sh --dry-run

# 2. Run quick update
./quick-update-checkref.sh

# 3. Switch to updated version
./manage-checkref-config.sh switch 1.0.0-updated

# 4. Restart service
sudo systemctl restart cloudgene
```

### Option 2: Full Update with Advanced Features

```bash
# 1. Preview the update
./update-checkref.sh --dry-run

# 2. Run the update
./update-checkref.sh

# 3. Check current version
./manage-checkref-config.sh current
```

## Workflow Integration

After updating checkref, you may need to:

1. **Update Configuration**: Use `manage-checkref-config.sh` to switch to the new version
2. **Restart Service**: `sudo systemctl restart cloudgene`
3. **Test Functionality**: Submit a test job to verify the update works
4. **Monitor Logs**: Check `/home/ubuntu/devs/checkref/checkref-update-tools/logs/checkref-update.log`

## Troubleshooting

### If Update Fails

```bash
# Check logs
tail -f /home/ubuntu/devs/checkref/checkref-update-tools/logs/checkref-update.log

# Rollback to previous version
./update-checkref.sh --rollback

# Or restore configuration
./manage-checkref-config.sh restore
```

### If Service Won't Start

```bash
# Check service status
sudo systemctl status cloudgene

# Check service logs
sudo journalctl -u cloudgene -f

# Restart service manually
sudo systemctl restart cloudgene
```

### Manual Rollback

If scripts fail, you can manually rollback:

```bash
# Find backup
ls -la /home/ubuntu/imputationserver2/backups/checkref/

# Restore backup (replace BACKUP_NAME with actual backup)
rm -rf /home/ubuntu/imputationserver2/apps/checkref/1.0.0
cp -r /home/ubuntu/imputationserver2/backups/checkref/BACKUP_NAME /home/ubuntu/imputationserver2/apps/checkref/1.0.0

# Restart service
sudo systemctl restart cloudgene
```

## File Locations

- **Application**: `/home/ubuntu/imputationserver2/apps/checkref/`
- **Configuration**: `/home/ubuntu/imputationserver2/config/settings.yaml`
- **Backups**: `/home/ubuntu/imputationserver2/backups/checkref/`
- **Logs**: `/home/ubuntu/devs/checkref/checkref-update-tools/logs/checkref-update.log`
- **GitHub Repository**: <https://github.com/afrigen-d/checkref>

## Security Notes

- Scripts require appropriate permissions to modify application files
- Service restart requires sudo privileges
- Backups are created automatically before any changes
- All operations are logged for audit purposes

## Support

If you encounter issues:

1. Check the logs: `/home/ubuntu/devs/checkref/checkref-update-tools/logs/checkref-update.log`
2. Verify GitHub repository access: <https://github.com/afrigen-d/checkref>
3. Ensure proper permissions on application directories
4. Test with `--dry-run` mode first
