#!/bin/bash
# Update expected manifest files with current actual manifests
# Use this when you've made intentional changes and want to update the baseline

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Configuration
MANIFESTS_DIR="manifests"
EXPECTED_DIR="expected"
APPS=("foo" "bar" "baz")
ENVS=("dev" "stage" "prod")

# Flags
FORCE=false
SPECIFIC_ENV=""
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS] [ENVIRONMENT]"
            echo ""
            echo "Update expected manifest files with current actual manifests"
            echo ""
            echo "Options:"
            echo "  --force, -f       Skip confirmation prompt"
            echo "  --dry-run         Show what would be updated without making changes"
            echo "  --help, -h        Show this help message"
            echo ""
            echo "Arguments:"
            echo "  ENVIRONMENT       Optional: update only specific environment (dev|stage|prod)"
            echo ""
            echo "Examples:"
            echo "  $0                    # Update all environments (with confirmation)"
            echo "  $0 --force            # Update all without confirmation"
            echo "  $0 dev                # Update only dev environment"
            echo "  $0 --dry-run          # Preview what would be updated"
            exit 0
            ;;
        dev|stage|prod)
            SPECIFIC_ENV=$1
            shift
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Determine which environments to update
if [ -n "$SPECIFIC_ENV" ]; then
    UPDATE_ENVS=("$SPECIFIC_ENV")
else
    UPDATE_ENVS=("${ENVS[@]}")
fi

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Update Expected Manifests                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo

# Create expected directory if it doesn't exist
if [ ! -d "$EXPECTED_DIR" ]; then
    echo -e "${YELLOW}Creating expected directory structure...${NC}"
    for env in "${ENVS[@]}"; do
        mkdir -p "$EXPECTED_DIR/$env"
    done
    echo -e "${GREEN}✓ Expected directory created${NC}"
    echo
fi

# Check if manifests directory exists
if [ ! -d "$MANIFESTS_DIR" ]; then
    echo -e "${RED}Error: Manifests directory '$MANIFESTS_DIR' not found${NC}"
    echo "Run './generate-manifests.sh' first to generate manifests"
    exit 1
fi

# Preview what will be updated
echo -e "${BLUE}Files to update:${NC}"
update_count=0
for env in "${UPDATE_ENVS[@]}"; do
    for app in "${APPS[@]}"; do
        actual="$MANIFESTS_DIR/$env/$app.yaml"

        if [ ! -f "$actual" ]; then
            echo -e "  ${YELLOW}⚠ $env/$app - actual manifest not found, skipping${NC}"
            continue
        fi

        expected="$EXPECTED_DIR/$env/$app.yaml"

        # Check if there are differences
        if [ -f "$expected" ]; then
            if diff -q "$actual" "$expected" > /dev/null 2>&1; then
                echo -e "  ${GREEN}= $env/$app - already up to date${NC}"
            else
                echo -e "  ${YELLOW}→ $env/$app - will be updated${NC}"
                update_count=$((update_count + 1))
            fi
        else
            echo -e "  ${BLUE}+ $env/$app - new expected file${NC}"
            update_count=$((update_count + 1))
        fi
    done
done

echo
echo -e "Total files to update: ${YELLOW}$update_count${NC}"
echo

# Exit if dry run
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}Dry run complete. No files were modified.${NC}"
    exit 0
fi

# Confirm if not forced
if [ "$FORCE" = false ] && [ $update_count -gt 0 ]; then
    echo -e "${YELLOW}This will overwrite expected manifest files.${NC}"
    echo -e "${YELLOW}Make sure the current manifests are correct!${NC}"
    echo
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Update cancelled${NC}"
        exit 1
    fi
    echo
fi

# Perform the update
echo -e "${BLUE}Updating expected manifests...${NC}"
echo

copied=0
for env in "${UPDATE_ENVS[@]}"; do
    for app in "${APPS[@]}"; do
        actual="$MANIFESTS_DIR/$env/$app.yaml"

        if [ ! -f "$actual" ]; then
            continue
        fi

        expected="$EXPECTED_DIR/$env/$app.yaml"

        # Create directory if needed
        mkdir -p "$(dirname "$expected")"

        # Copy the file
        cp "$actual" "$expected"
        echo -e "  ${GREEN}✓ Updated $env/$app${NC}"
        copied=$((copied + 1))
    done
done

echo
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Update Complete                               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo
echo -e "${GREEN}Updated $copied expected manifest file(s)${NC}"
echo
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Review the changes with: git diff expected/"
echo -e "  2. Run validation to confirm: ./validate-manifests.sh"
echo -e "  3. Commit the updated expected files if correct"
echo
