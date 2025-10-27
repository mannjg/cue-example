#!/bin/bash
# Generate Kubernetes manifests for all environments
# This script uses CUE to dynamically export resources based on each app's resources_list definition
# Each app gets its own YAML file per environment for individual ArgoCD Application management

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Define apps and environments
APPS=("foo" "bar" "baz")
ENVS=("dev" "stage" "prod")

echo -e "${BLUE}Generating Kubernetes manifests from CUE definitions...${NC}"
echo -e "${YELLOW}Output: One YAML file per app per environment${NC}"
echo -e "${YELLOW}Resources are dynamically determined from each app's resources_list${NC}"
echo

# Create environment directories
for env in "${ENVS[@]}"; do
    mkdir -p "manifests/$env"
done

# Counter for progress
total=$((${#ENVS[@]} * ${#APPS[@]}))
current=0

# Generate manifests for each environment and app
for env in "${ENVS[@]}"; do
    for app in "${APPS[@]}"; do
        current=$((current + 1))

        echo -e "${BLUE}[$current/$total] Generating $env/$app.yaml...${NC}"

        # Query the app's resources_list from CUE
        echo "  → Querying: cue export ./envs/$env.cue -e $app.resources_list --out json"
        resources_json=$(cue export "./envs/$env.cue" -e "$app.resources_list" --out json 2>&1 | tr -d '\n')

        # Check if cue export failed
        if [ $? -ne 0 ]; then
            echo -e "${RED}✗ Error querying resources_list for $app in $env:${NC}"
            echo -e "${RED}  $resources_json${NC}"
            resources_json="[]"
        fi

        # Handle empty or error output
        if [ -z "$resources_json" ] || [ "$resources_json" = "null" ]; then
            resources_json="[]"
        fi

        # Parse JSON array into bash array
        # Remove brackets, quotes, and whitespace, split by comma
        resources_str=$(echo "$resources_json" | sed 's/[][]//g' | sed 's/"//g' | tr -d ' ')
        IFS=',' read -ra resources <<< "$resources_str"

        # Build export flags dynamically
        export_flags=""
        for resource in "${resources[@]}"; do
            # Trim whitespace
            resource=$(echo "$resource" | xargs)
            if [ -n "$resource" ]; then
                export_flags="$export_flags -e $app.$resource"
            fi
        done

        # Export app-specific resources
        if [ -n "$export_flags" ]; then
            echo "  → Exporting: cue export ./envs/$env.cue $export_flags --out yaml"
            export_output=$(cue export "./envs/$env.cue" $export_flags --out yaml 2>&1)
            export_status=$?

            if [ $export_status -eq 0 ]; then
                echo "$export_output" > "manifests/$env/$app.yaml"
                echo -e "${GREEN}✓ manifests/$env/$app.yaml created (resources: ${resources[*]})${NC}"
            else
                echo -e "${RED}✗ Error exporting resources for $app in $env:${NC}"
                echo -e "${RED}$export_output${NC}"
                exit 1
            fi
        else
            echo -e "${YELLOW}⚠ No resources defined for $app in $env${NC}"
            echo -e "${YELLOW}  Check that $app.resources_list exists in ./envs/$env.cue${NC}"
            echo -e "${YELLOW}  Or verify the app definition is present for this environment${NC}"
        fi
    done
done

echo
echo -e "${GREEN}All manifests generated successfully!${NC}"
echo
echo "Generated structure:"
for env in "${ENVS[@]}"; do
    echo "manifests/$env/"
    for app in "${APPS[@]}"; do
        if [ -f "manifests/$env/$app.yaml" ]; then
            size=$(ls -lh "manifests/$env/$app.yaml" | awk '{print $5}')
            resource_count=$(grep -c '^kind:' "manifests/$env/$app.yaml")
            # Get resource types
            resource_types=$(grep '^kind:' "manifests/$env/$app.yaml" | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
            echo "  ├── $app.yaml ($size, $resource_count resources: $resource_types)"
        fi
    done
    echo
done

echo "These manifests are ready for:"
echo "  - Individual ArgoCD Application per app"
echo "  - kubectl apply -f manifests/<env>/<app>.yaml"
echo "  - Selective app deployments"
echo "  - Independent app sync policies"
