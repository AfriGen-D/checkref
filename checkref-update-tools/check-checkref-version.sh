#!/bin/bash

# Checkref Version Checker
# Simple script to check current vs latest available version
# Author: Afrigen-D Team

set -e

# Configuration
GITHUB_REPO="https://github.com/afrigen-d/checkref"
CONFIG_FILE="/home/ubuntu/imputationserver2/config/settings.yaml"
APP_DIR="/home/ubuntu/imputationserver2/apps/checkref"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Checkref Version Checker ===${NC}"
echo ""

# Get current version from config
get_current_version() {
    if [[ -f "$CONFIG_FILE" ]]; then
        local current_path
        current_path=$(grep -o "apps/checkref/[^/]*/cloudgene.yaml" "$CONFIG_FILE" 2>/dev/null || echo "")
        
        if [[ -n "$current_path" ]]; then
            local version
            version=$(echo "$current_path" | cut -d'/' -f3)
            echo "$version"
        else
            echo "unknown"
        fi
    else
        echo "config-not-found"
    fi
}

# Get latest version from GitHub
get_latest_version() {
    echo -e "${YELLOW}Fetching latest version from GitHub...${NC}"
    
    local latest_version
    latest_version=$(curl -s "https://api.github.com/repos/afrigen-d/checkref/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' 2>/dev/null || echo "")
    
    if [[ -z "$latest_version" ]]; then
        echo -e "${YELLOW}No releases found, checking main branch...${NC}"
        
        # Get latest commit date from main branch
        local commit_date
        commit_date=$(curl -s "https://api.github.com/repos/afrigen-d/checkref/commits/main" | grep '"date":' | head -1 | sed -E 's/.*"([^"]+)".*/\1/' 2>/dev/null || echo "")
        
        if [[ -n "$commit_date" ]]; then
            echo "main-branch (last updated: $(date -d "$commit_date" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "$commit_date"))"
        else
            echo "main-branch"
        fi
    else
        echo "$latest_version"
    fi
}

# Get latest commit info
get_latest_commit_info() {
    echo -e "${YELLOW}Getting latest commit information...${NC}"
    
    local commit_info
    commit_info=$(curl -s "https://api.github.com/repos/afrigen-d/checkref/commits/main" 2>/dev/null)
    
    if [[ -n "$commit_info" ]]; then
        local commit_sha
        local commit_date
        local commit_message
        
        commit_sha=$(echo "$commit_info" | grep '"sha":' | head -1 | sed -E 's/.*"([^"]+)".*/\1/' | cut -c1-8)
        commit_date=$(echo "$commit_info" | grep '"date":' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
        commit_message=$(echo "$commit_info" | grep '"message":' | head -1 | sed -E 's/.*"([^"]+)".*/\1/' | cut -c1-50)
        
        if [[ -n "$commit_sha" ]]; then
            echo "  Latest commit: $commit_sha"
            if [[ -n "$commit_date" ]]; then
                echo "  Date: $(date -d "$commit_date" '+%Y-%m-%d %H:%M UTC' 2>/dev/null || echo "$commit_date")"
            fi
            if [[ -n "$commit_message" ]]; then
                echo "  Message: $commit_message..."
            fi
        fi
    else
        echo -e "${RED}Could not fetch commit information${NC}"
    fi
}

# Check if update is available
check_update_available() {
    local current="$1"
    local latest="$2"
    
    if [[ "$current" == "unknown" ]] || [[ "$current" == "config-not-found" ]]; then
        echo -e "${RED}Cannot determine if update is needed (current version unknown)${NC}"
        return 1
    fi
    
    if [[ "$latest" == "main-branch"* ]]; then
        echo -e "${YELLOW}Latest version is from main branch - update recommended${NC}"
        return 0
    fi
    
    if [[ "$current" != "$latest" ]]; then
        echo -e "${GREEN}Update available!${NC}"
        return 0
    else
        echo -e "${GREEN}You have the latest version${NC}"
        return 1
    fi
}

# Main execution
echo -e "${BLUE}Current Version:${NC}"
current_version=$(get_current_version)

if [[ "$current_version" == "config-not-found" ]]; then
    echo -e "  ${RED}Configuration file not found${NC}"
elif [[ "$current_version" == "unknown" ]]; then
    echo -e "  ${RED}No checkref configuration found in settings${NC}"
else
    echo -e "  ${GREEN}$current_version${NC}"
    
    # Check if directory exists
    if [[ -d "$APP_DIR/$current_version" ]]; then
        echo -e "  ${GREEN}✓${NC} Directory exists"
    else
        echo -e "  ${RED}✗${NC} Directory missing: $APP_DIR/$current_version"
    fi
fi

echo ""
echo -e "${BLUE}Latest Available Version:${NC}"
latest_version=$(get_latest_version)
echo -e "  ${GREEN}$latest_version${NC}"

echo ""
echo -e "${BLUE}Repository Information:${NC}"
echo "  Repository: $GITHUB_REPO"
get_latest_commit_info

echo ""
echo -e "${BLUE}Update Status:${NC}"
if check_update_available "$current_version" "$latest_version"; then
    echo ""
    echo -e "${YELLOW}To update, run:${NC}"
    echo "  ./update-checkref.sh"
    echo ""
    echo -e "${YELLOW}Or for a quick update:${NC}"
    echo "  ./quick-update-checkref.sh"
else
    echo ""
    echo -e "${GREEN}No update needed${NC}"
fi

echo ""
echo -e "${BLUE}Available Local Versions:${NC}"
if [[ -d "$APP_DIR" ]]; then
    for dir in "$APP_DIR"/*; do
        if [[ -d "$dir" ]]; then
            version=$(basename "$dir")
            status=""

            # Check if this version is currently active
            if [[ "$version" == "$current_version" ]]; then
                status=" ${GREEN}(ACTIVE)${NC}"
            fi

            echo -e "  - $version$status"
        fi
    done
else
    echo -e "  ${RED}Checkref directory not found${NC}"
fi
