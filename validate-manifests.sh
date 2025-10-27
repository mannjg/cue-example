#!/bin/bash
# Validate Kubernetes manifests against expected versions
# This script performs regression testing by comparing actual manifests with golden/expected versions

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
REGENERATE=true
VALIDATE_SCHEMA=false
VERBOSE=false
SPECIFIC_ENV=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-regenerate)
            REGENERATE=false
            shift
            ;;
        --schema)
            VALIDATE_SCHEMA=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS] [ENVIRONMENT]"
            echo ""
            echo "Validate manifests against expected versions (regression testing)"
            echo ""
            echo "Options:"
            echo "  --no-regenerate    Skip regenerating manifests from CUE"
            echo "  --schema          Also validate schema conformance with 'cue vet'"
            echo "  --verbose, -v     Show detailed diff output"
            echo "  --help, -h        Show this help message"
            echo ""
            echo "Arguments:"
            echo "  ENVIRONMENT       Optional: validate only specific environment (dev|stage|prod)"
            echo ""
            echo "Examples:"
            echo "  $0                    # Validate all environments"
            echo "  $0 dev                # Validate only dev environment"
            echo "  $0 --schema           # Validate all with schema checking"
            echo "  $0 --verbose dev      # Verbose output for dev environment"
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

# Determine which environments to validate
if [ -n "$SPECIFIC_ENV" ]; then
    VALIDATE_ENVS=("$SPECIFIC_ENV")
else
    VALIDATE_ENVS=("${ENVS[@]}")
fi

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Manifest Validation - Regression Testing     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo

# Check if expected directory exists
if [ ! -d "$EXPECTED_DIR" ]; then
    echo -e "${RED}Error: Expected directory '$EXPECTED_DIR' not found${NC}"
    echo "Run './update-expected.sh' to create baseline expected manifests"
    exit 1
fi

# Step 1: Regenerate manifests from CUE if requested
if [ "$REGENERATE" = true ]; then
    echo -e "${BLUE}[1/3] Regenerating manifests from CUE...${NC}"
    if [ "$VERBOSE" = true ]; then
        ./generate-manifests.sh
    else
        ./generate-manifests.sh > /dev/null 2>&1
    fi
    echo -e "${GREEN}✓ Manifests regenerated${NC}"
    echo
else
    echo -e "${YELLOW}[1/3] Skipping manifest regeneration${NC}"
    echo
fi

# Step 2: Schema validation with CUE vet (optional)
if [ "$VALIDATE_SCHEMA" = true ]; then
    echo -e "${BLUE}[2/3] Validating schema conformance with CUE...${NC}"
    schema_errors=0

    for env in "${VALIDATE_ENVS[@]}"; do
        for app in "${APPS[@]}"; do
            manifest_file="$MANIFESTS_DIR/$env/$app.yaml"

            if [ ! -f "$manifest_file" ]; then
                continue
            fi

            # Validate YAML against CUE schema
            if ! cue vet "./envs/$env.cue" "$manifest_file" 2>&1; then
                echo -e "${RED}✗ Schema validation failed: $env/$app${NC}"
                schema_errors=$((schema_errors + 1))
            elif [ "$VERBOSE" = true ]; then
                echo -e "${GREEN}✓ Schema valid: $env/$app${NC}"
            fi
        done
    done

    if [ $schema_errors -eq 0 ]; then
        echo -e "${GREEN}✓ All manifests pass schema validation${NC}"
    else
        echo -e "${RED}✗ $schema_errors schema validation error(s) found${NC}"
    fi
    echo
else
    echo -e "${YELLOW}[2/3] Skipping schema validation${NC}"
    echo
fi

# Step 3: Compare actual vs expected manifests
echo -e "${BLUE}[3/3] Comparing manifests against expected versions...${NC}"
echo

# Counters
total=0
passed=0
failed=0
declare -a failed_manifests

for env in "${VALIDATE_ENVS[@]}"; do
    echo -e "${BLUE}Environment: $env${NC}"

    for app in "${APPS[@]}"; do
        actual="$MANIFESTS_DIR/$env/$app.yaml"
        expected="$EXPECTED_DIR/$env/$app.yaml"

        total=$((total + 1))

        # Check if files exist
        if [ ! -f "$actual" ]; then
            echo -e "  ${RED}✗ $app - actual manifest missing${NC}"
            failed=$((failed + 1))
            failed_manifests+=("$env/$app (missing actual)")
            continue
        fi

        if [ ! -f "$expected" ]; then
            echo -e "  ${YELLOW}⚠ $app - expected manifest missing (run update-expected.sh)${NC}"
            failed=$((failed + 1))
            failed_manifests+=("$env/$app (missing expected)")
            continue
        fi

        # Compare files
        if diff -q "$actual" "$expected" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓ $app - matches expected${NC}"
            passed=$((passed + 1))
        else
            echo -e "  ${RED}✗ $app - DIVERGES from expected${NC}"
            failed=$((failed + 1))
            failed_manifests+=("$env/$app")

            # Show diff if verbose
            if [ "$VERBOSE" = true ]; then
                echo -e "${YELLOW}    Diff:${NC}"
                diff -u "$expected" "$actual" | tail -n +3 | head -n 20 | sed 's/^/    /'
                echo
            fi
        fi
    done
    echo
done

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Validation Summary                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo
echo -e "Total manifests validated: $total"
echo -e "${GREEN}Passed: $passed${NC}"
echo -e "${RED}Failed: $failed${NC}"
echo

if [ $failed -gt 0 ]; then
    echo -e "${RED}Manifests with divergences:${NC}"
    for manifest in "${failed_manifests[@]}"; do
        echo -e "  ${RED}• $manifest${NC}"
    done
    echo
    echo -e "${YELLOW}To see detailed differences, run with --verbose flag${NC}"
    echo -e "${YELLOW}To update expected files if changes are intentional, run: ./update-expected.sh${NC}"
    echo
    exit 1
else
    echo -e "${GREEN}✓ All manifests match expected versions!${NC}"
    echo
    exit 0
fi
