#!/bin/bash

# Allele Switch Checker (checkref) Update Script
# Updates the checkref application from GitHub repository
# Author: Afrigen-D Team
# Version: 1.0

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
GITHUB_REPO="https://github.com/afrigen-d/checkref"
APP_DIR="/home/ubuntu/imputationserver2/apps/checkref"
CURRENT_VERSION="1.0.0"
BACKUP_DIR="/home/ubuntu/imputationserver2/backups/checkref"
LOG_FILE="/home/ubuntu/devs/checkref/checkref-update-tools/logs/checkref-update.log"
SERVICE_NAME="cloudgene"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO: $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log "WARNING: $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "ERROR: $1"
}

# Help function
show_help() {
    cat << EOF
Allele Switch Checker Update Script

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --version       Specify version to download (default: latest)
    -b, --backup-only   Only create backup, don't update
    -r, --rollback      Rollback to previous backup
    -f, --force         Force update without confirmation
    --no-restart        Don't restart cloudgene service
    --dry-run          Show what would be done without executing

Examples:
    $0                          # Update to latest version
    $0 -v v1.1.0               # Update to specific version
    $0 --rollback              # Rollback to previous version
    $0 --dry-run               # Preview update actions

EOF
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if running as correct user
    if [[ "$USER" != "ubuntu" ]]; then
        print_warning "Script should be run as 'ubuntu' user"
    fi
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        print_error "git is not installed. Please install git first."
        exit 1
    fi
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed. Please install curl first."
        exit 1
    fi

    # Check if tar is installed
    if ! command -v tar &> /dev/null; then
        print_error "tar is not installed. Please install tar first."
        exit 1
    fi
    
    # Check if app directory exists
    if [[ ! -d "$APP_DIR" ]]; then
        print_error "Application directory $APP_DIR does not exist"
        exit 1
    fi
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Create logs directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    
    print_success "Prerequisites check completed"
}

# Create backup
create_backup() {
    local backup_name="checkref-backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    print_status "Creating backup: $backup_name"
    
    if [[ -d "$APP_DIR/$CURRENT_VERSION" ]]; then
        cp -r "$APP_DIR/$CURRENT_VERSION" "$backup_path"
        echo "$backup_name" > "$BACKUP_DIR/latest-backup.txt"
        print_success "Backup created at: $backup_path"
    else
        print_error "Current version directory not found: $APP_DIR/$CURRENT_VERSION"
        exit 1
    fi
}

# Get latest version from GitHub
get_latest_version() {
    local latest_version
    latest_version=$(curl -s "https://api.github.com/repos/afrigen-d/checkref/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [[ -z "$latest_version" ]]; then
        echo "main"
    else
        echo "$latest_version"
    fi
}

# Download and extract from GitHub
download_update() {
    local version="$1"
    local temp_dir="/tmp/checkref-update-$$"

    print_status "Downloading checkref version: $version" >&2

    # Create temporary directory
    mkdir -p "$temp_dir"

    # Download from GitHub
    if [[ "$version" == "main" ]]; then
        local download_url="$GITHUB_REPO/archive/refs/heads/main.tar.gz"
    else
        local download_url="$GITHUB_REPO/archive/refs/tags/$version.tar.gz"
    fi

    print_status "Downloading from: $download_url" >&2

    if curl -sL -o "$temp_dir/checkref.tar.gz" "$download_url"; then
        print_success "Download completed" >&2
    else
        print_error "Failed to download from GitHub" >&2
        rm -rf "$temp_dir"
        exit 1
    fi

    # Extract
    print_status "Extracting files..." >&2
    cd "$temp_dir"
    tar -xzf checkref.tar.gz

    # Find extracted directory
    local extracted_dir
    extracted_dir=$(find . -maxdepth 1 -type d -name "checkref-*" | head -1)

    if [[ -z "$extracted_dir" ]]; then
        print_error "Could not find extracted directory" >&2
        rm -rf "$temp_dir"
        exit 1
    fi

    echo "$temp_dir/$extracted_dir"
}

# Update application
update_application() {
    local source_dir="$1"
    local new_version="$2"
    
    print_status "Updating application..."
    
    # Determine new version directory
    local version_dir
    if [[ "$new_version" == "main" ]]; then
        version_dir="$CURRENT_VERSION-dev"
    else
        version_dir="${new_version#v}"  # Remove 'v' prefix if present
    fi
    
    local target_dir="$APP_DIR/$version_dir"
    
    # Remove existing target directory if it exists
    if [[ -d "$target_dir" ]]; then
        print_warning "Removing existing directory: $target_dir"
        rm -rf "$target_dir"
    fi
    
    # Copy new files
    print_status "Copying new files to: $target_dir"
    cp -r "$source_dir" "$target_dir"
    
    # Set correct permissions
    chmod +x "$target_dir/main.nf" 2>/dev/null || true
    chmod +x "$target_dir/bin/"* 2>/dev/null || true
    
    # Update cloudgene.yaml version if needed
    if [[ -f "$target_dir/cloudgene.yaml" ]] && [[ "$new_version" != "main" ]]; then
        sed -i "s/version: .*/version: ${new_version#v}/" "$target_dir/cloudgene.yaml"
    fi
    
    print_success "Application updated to version: $version_dir"
    echo "$version_dir" > "$APP_DIR/current-version.txt"
}

# Restart cloudgene service
restart_service() {
    print_status "Restarting cloudgene service..."
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        if sudo systemctl restart "$SERVICE_NAME"; then
            print_success "Service restarted successfully"
            sleep 5
            if systemctl is-active --quiet "$SERVICE_NAME"; then
                print_success "Service is running"
            else
                print_error "Service failed to start after restart"
                return 1
            fi
        else
            print_error "Failed to restart service"
            return 1
        fi
    else
        print_warning "Service is not running, attempting to start..."
        if sudo systemctl start "$SERVICE_NAME"; then
            print_success "Service started successfully"
        else
            print_error "Failed to start service"
            return 1
        fi
    fi
}

# Rollback function
rollback() {
    print_status "Rolling back to previous version..."
    
    if [[ ! -f "$BACKUP_DIR/latest-backup.txt" ]]; then
        print_error "No backup found to rollback to"
        exit 1
    fi
    
    local backup_name
    backup_name=$(cat "$BACKUP_DIR/latest-backup.txt")
    local backup_path="$BACKUP_DIR/$backup_name"
    
    if [[ ! -d "$backup_path" ]]; then
        print_error "Backup directory not found: $backup_path"
        exit 1
    fi
    
    # Create backup of current state before rollback
    create_backup
    
    # Remove current version and restore backup
    rm -rf "$APP_DIR/$CURRENT_VERSION"
    cp -r "$backup_path" "$APP_DIR/$CURRENT_VERSION"
    
    print_success "Rollback completed"
}

# Main function
main() {
    local version=""
    local backup_only=false
    local rollback_mode=false
    local force=false
    local no_restart=false
    local dry_run=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                version="$2"
                shift 2
                ;;
            -b|--backup-only)
                backup_only=true
                shift
                ;;
            -r|--rollback)
                rollback_mode=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            --no-restart)
                no_restart=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Start logging
    log "=== Checkref Update Script Started ==="
    
    print_status "Starting Allele Switch Checker update process..."
    
    # Check prerequisites
    check_prerequisites
    
    # Handle rollback mode
    if [[ "$rollback_mode" == true ]]; then
        if [[ "$dry_run" == true ]]; then
            print_status "DRY RUN: Would rollback to previous backup"
            exit 0
        fi
        rollback
        if [[ "$no_restart" != true ]]; then
            restart_service
        fi
        exit 0
    fi
    
    # Create backup
    if [[ "$dry_run" == true ]]; then
        print_status "DRY RUN: Would create backup of current version"
    else
        create_backup
    fi
    
    # Exit if backup only
    if [[ "$backup_only" == true ]]; then
        print_success "Backup completed. Exiting."
        exit 0
    fi
    
    # Get version to download
    if [[ -z "$version" ]]; then
        print_status "Fetching latest version from GitHub..."
        version=$(get_latest_version)
        if [[ "$version" == "main" ]]; then
            print_warning "No releases found, using main branch"
        else
            print_success "Latest version: $version"
        fi
    fi
    
    # Confirmation
    if [[ "$force" != true ]] && [[ "$dry_run" != true ]]; then
        echo
        print_warning "This will update checkref to version: $version"
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Update cancelled by user"
            exit 0
        fi
    fi
    
    if [[ "$dry_run" == true ]]; then
        print_status "DRY RUN: Would download and install version: $version"
        print_status "DRY RUN: Would restart cloudgene service"
        print_status "DRY RUN: Update simulation completed"
        echo ""
        print_status "Running version check for detailed comparison..."
        echo ""
        # Run the version checker script if it exists
        if [[ -f "./check-checkref-version.sh" ]]; then
            ./check-checkref-version.sh
        else
            print_warning "check-checkref-version.sh not found - cannot show detailed version comparison"
        fi
        exit 0
    fi
    
    # Download and update
    local source_dir
    source_dir=$(download_update "$version")
    
    # Update application
    update_application "$source_dir" "$version"
    
    # Cleanup
    rm -rf "$(dirname "$source_dir")"
    
    # Restart service
    if [[ "$no_restart" != true ]]; then
        restart_service
    fi
    
    print_success "Checkref update completed successfully!"
    print_status "New version installed: $version"
    
    log "=== Checkref Update Script Completed Successfully ==="
}

# Run main function with all arguments
main "$@"
