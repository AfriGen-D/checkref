#!/bin/bash

# Checkref Configuration Management Script
# Helps manage checkref versions in cloudgene configuration
# Author: Afrigen-D Team

set -e

# Configuration
CONFIG_FILE="/home/ubuntu/imputationserver2/config/settings.yaml"
APP_DIR="/home/ubuntu/imputationserver2/apps/checkref"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    cat << EOF
Checkref Configuration Management Script

Usage: $0 [COMMAND] [OPTIONS]

COMMANDS:
    list                List available checkref versions
    current             Show current active version
    switch <version>    Switch to specified version
    backup              Backup current configuration
    restore             Restore configuration from backup

OPTIONS:
    -h, --help         Show this help message
    --dry-run          Show what would be done without executing

Examples:
    $0 list                    # List all available versions
    $0 current                 # Show current version
    $0 switch 1.0.0-updated    # Switch to updated version
    $0 backup                  # Backup current config

EOF
}

# List available versions
list_versions() {
    echo -e "${BLUE}Available checkref versions:${NC}"
    if [[ -d "$APP_DIR" ]]; then
        for dir in "$APP_DIR"/*; do
            if [[ -d "$dir" ]]; then
                local version=$(basename "$dir")
                local status=""
                
                # Check if this version is currently active
                if grep -q "apps/checkref/$version/cloudgene.yaml" "$CONFIG_FILE" 2>/dev/null; then
                    status=" ${GREEN}(ACTIVE)${NC}"
                fi
                
                echo -e "  - $version$status"
            fi
        done
    else
        echo -e "${RED}Checkref directory not found: $APP_DIR${NC}"
    fi
}

# Show current version
show_current() {
    echo -e "${BLUE}Current active checkref version:${NC}"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        local current_path
        current_path=$(grep -o "apps/checkref/[^/]*/cloudgene.yaml" "$CONFIG_FILE" 2>/dev/null || echo "")
        
        if [[ -n "$current_path" ]]; then
            local version
            version=$(echo "$current_path" | cut -d'/' -f3)
            echo -e "  ${GREEN}$version${NC}"
            
            # Check if the directory actually exists
            if [[ ! -d "$APP_DIR/$version" ]]; then
                echo -e "  ${RED}WARNING: Directory does not exist!${NC}"
            fi
        else
            echo -e "  ${RED}No checkref configuration found${NC}"
        fi
    else
        echo -e "${RED}Configuration file not found: $CONFIG_FILE${NC}"
    fi
}

# Switch to a different version
switch_version() {
    local new_version="$1"
    local dry_run="$2"
    
    if [[ -z "$new_version" ]]; then
        echo -e "${RED}Error: Version not specified${NC}"
        exit 1
    fi
    
    # Check if version directory exists
    if [[ ! -d "$APP_DIR/$new_version" ]]; then
        echo -e "${RED}Error: Version directory does not exist: $APP_DIR/$new_version${NC}"
        exit 1
    fi
    
    # Check if cloudgene.yaml exists in the version directory
    if [[ ! -f "$APP_DIR/$new_version/cloudgene.yaml" ]]; then
        echo -e "${RED}Error: cloudgene.yaml not found in version directory${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Switching checkref to version: $new_version${NC}"
    
    if [[ "$dry_run" == "true" ]]; then
        echo -e "${BLUE}DRY RUN: Would update configuration to use version $new_version${NC}"
        return 0
    fi
    
    # Backup current configuration
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d-%H%M%S)"
    echo "Configuration backed up"
    
    # Update configuration
    sed -i "s|apps/checkref/[^/]*/cloudgene.yaml|apps/checkref/$new_version/cloudgene.yaml|g" "$CONFIG_FILE"
    
    echo -e "${GREEN}Configuration updated successfully${NC}"
    echo "Checkref is now using version: $new_version"
    echo ""
    echo -e "${YELLOW}Remember to restart cloudgene service:${NC}"
    echo "sudo systemctl restart cloudgene"
}

# Backup configuration
backup_config() {
    local backup_file="$CONFIG_FILE.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$CONFIG_FILE" "$backup_file"
    echo -e "${GREEN}Configuration backed up to: $backup_file${NC}"
}

# Restore configuration
restore_config() {
    echo -e "${BLUE}Available configuration backups:${NC}"
    
    local backups
    backups=$(find "$(dirname "$CONFIG_FILE")" -name "settings.yaml.backup.*" -type f 2>/dev/null | sort -r)
    
    if [[ -z "$backups" ]]; then
        echo -e "${RED}No backup files found${NC}"
        exit 1
    fi
    
    local i=1
    declare -a backup_array
    
    while IFS= read -r backup; do
        backup_array[$i]="$backup"
        local backup_name=$(basename "$backup")
        local backup_date=$(echo "$backup_name" | grep -o '[0-9]\{8\}-[0-9]\{6\}')
        echo "  $i. $backup_name ($(date -d "${backup_date:0:8} ${backup_date:9:2}:${backup_date:11:2}:${backup_date:13:2}" 2>/dev/null || echo "$backup_date"))"
        ((i++))
    done <<< "$backups"
    
    echo ""
    read -p "Select backup to restore (1-$((i-1)), or 0 to cancel): " choice
    
    if [[ "$choice" == "0" ]] || [[ -z "$choice" ]]; then
        echo "Restore cancelled"
        exit 0
    fi
    
    if [[ "$choice" -ge 1 ]] && [[ "$choice" -lt "$i" ]]; then
        local selected_backup="${backup_array[$choice]}"
        
        # Create backup of current config before restoring
        backup_config
        
        # Restore selected backup
        cp "$selected_backup" "$CONFIG_FILE"
        echo -e "${GREEN}Configuration restored from: $(basename "$selected_backup")${NC}"
        echo ""
        echo -e "${YELLOW}Remember to restart cloudgene service:${NC}"
        echo "sudo systemctl restart cloudgene"
    else
        echo -e "${RED}Invalid selection${NC}"
        exit 1
    fi
}

# Main function
main() {
    local command=""
    local dry_run="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            list|current|backup|restore)
                command="$1"
                shift
                ;;
            switch)
                command="$1"
                shift
                if [[ $# -gt 0 ]]; then
                    version="$1"
                    shift
                else
                    echo -e "${RED}Error: Version not specified for switch command${NC}"
                    exit 1
                fi
                ;;
            *)
                echo -e "${RED}Unknown command: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Execute command
    case "$command" in
        list)
            list_versions
            ;;
        current)
            show_current
            ;;
        switch)
            switch_version "$version" "$dry_run"
            ;;
        backup)
            backup_config
            ;;
        restore)
            restore_config
            ;;
        "")
            echo -e "${YELLOW}No command specified. Use --help for usage information.${NC}"
            echo ""
            show_current
            echo ""
            list_versions
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
