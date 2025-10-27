#!/bin/bash
# Generate Kubernetes manifests for all environments
# This script uses CUE to export Deployment and Service resources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Generating Kubernetes manifests from CUE definitions...${NC}"
echo

# Create manifests directory if it doesn't exist
mkdir -p manifests

# Export development environment
echo -e "${BLUE}[1/3] Generating dev.yaml...${NC}"
cue export ./envs/dev.cue -e deployment -e service --out yaml > manifests/dev.yaml
echo -e "${GREEN}✓ manifests/dev.yaml created${NC}"

# Export staging environment
echo -e "${BLUE}[2/3] Generating stage.yaml...${NC}"
cue export ./envs/stage.cue -e deployment -e service --out yaml > manifests/stage.yaml
echo -e "${GREEN}✓ manifests/stage.yaml created${NC}"

# Export production environment
echo -e "${BLUE}[3/3] Generating prod.yaml...${NC}"
cue export ./envs/prod.cue -e deployment -e service --out yaml > manifests/prod.yaml
echo -e "${GREEN}✓ manifests/prod.yaml created${NC}"

echo
echo -e "${GREEN}All manifests generated successfully!${NC}"
echo
echo "Manifest files:"
ls -lh manifests/*.yaml | awk '{print "  " $9 " (" $5 ")"}'
echo
echo "Each manifest contains:"
echo "  - Deployment resource"
echo "  - Service resource"
echo
echo "These manifests are ready for:"
echo "  - kubectl apply -f manifests/<env>.yaml"
echo "  - ArgoCD GitOps deployment"
echo "  - CI/CD pipelines"
