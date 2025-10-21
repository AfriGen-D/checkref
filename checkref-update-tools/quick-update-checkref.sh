#!/bin/bash

# Quick Checkref Update Script
# Simple script to quickly update checkref from GitHub
# Author: Afrigen-D Team

set -e

# Configuration
GITHUB_REPO="https://github.com/afrigen-d/checkref"
APP_DIR="/home/ubuntu/imputationserver2/apps/checkref"
CURRENT_VERSION="1.0.0"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Quick Checkref Update ===${NC}"

# Check if app directory exists
if [[ ! -d "$APP_DIR" ]]; then
    echo -e "${RED}Error: Application directory $APP_DIR does not exist${NC}"
    exit 1
fi

# Create backup
echo -e "${YELLOW}Creating backup...${NC}"
BACKUP_NAME="checkref-backup-$(date +%Y%m%d-%H%M%S)"
cp -r "$APP_DIR/$CURRENT_VERSION" "/tmp/$BACKUP_NAME"
echo "Backup created: /tmp/$BACKUP_NAME"

# Download latest version
echo -e "${YELLOW}Downloading latest version...${NC}"
TEMP_DIR="/tmp/checkref-update-$$"
mkdir -p "$TEMP_DIR"

# Download main branch
curl -L -o "$TEMP_DIR/checkref.zip" "$GITHUB_REPO/archive/refs/heads/main.zip"

# Extract
cd "$TEMP_DIR"
unzip -q checkref.zip

# Find extracted directory
EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "checkref-*" | head -1)

if [[ -z "$EXTRACTED_DIR" ]]; then
    echo -e "${RED}Error: Could not find extracted directory${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Update application
echo -e "${YELLOW}Updating application...${NC}"
TARGET_DIR="$APP_DIR/$CURRENT_VERSION-updated"

# Remove existing updated directory if it exists
[[ -d "$TARGET_DIR" ]] && rm -rf "$TARGET_DIR"

# Copy new files
cp -r "$EXTRACTED_DIR" "$TARGET_DIR"

# Set permissions
chmod +x "$TARGET_DIR/main.nf" 2>/dev/null || true
chmod +x "$TARGET_DIR/bin/"* 2>/dev/null || true

# Cleanup
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Update completed!${NC}"
echo "New version installed at: $TARGET_DIR"
echo "Backup available at: /tmp/$BACKUP_NAME"
echo ""
echo "To use the updated version, you may need to:"
echo "1. Update the cloudgene.yaml configuration to point to the new directory"
echo "2. Restart the cloudgene service: sudo systemctl restart cloudgene"
echo ""
echo "To rollback if needed:"
echo "rm -rf '$TARGET_DIR' && cp -r '/tmp/$BACKUP_NAME' '$APP_DIR/$CURRENT_VERSION'"
