# Multi-Environment Kubernetes Deployment with CUE

This project demonstrates a well-structured, multi-environment Kubernetes deployment pattern using [CUE](https://cuelang.org/) - a powerful configuration language with strong type safety and validation.

## Architecture

The configuration follows a layered architecture with progressive refinement:

```
┌─────────────────────────────────────────────────────────────┐
│ deployment.cue                                              │
│ Base Kubernetes schemas (#Deployment, #Container, etc.)    │
│ Fixed invariants: apiVersion, kind                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ app.cue                                                     │
│ Application-specific configuration                          │
│ - Volumes, mounts, env vars, ports, labels                 │
│ - Constraints for instance values                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────┬──────────────────┬──────────────────────────┐
│ dev.cue      │ stage.cue        │ prod.cue                 │
│ Dev instance │ Staging instance │ Production instance      │
│ - 1 replica  │ - 2 replicas     │ - 3 replicas             │
│ - Small      │ - Moderate       │ - Large resources        │
│ - dev-latest │ - RC images      │ - Versioned images       │
└──────────────┴──────────────────┴──────────────────────────┘
```

## File Structure

```
.
├── deployment.cue   # Base Kubernetes resource schemas
├── app.cue         # Application-specific configuration
├── dev.cue         # Development environment
├── stage.cue       # Staging environment
├── prod.cue        # Production environment
└── README.md       # This file
```

### deployment.cue

Defines reusable Kubernetes resource schemas:
- `#Deployment` - Complete Deployment resource structure
- `#Container` - Container specification
- `#Volume` - Volume definitions (PVC, ConfigMap, Secret, EmptyDir, Projected)
- `#Resources` - CPU and memory requests/limits
- `#Probe` - Health check probes
- Other supporting schemas

**Key principles:**
- Fixed invariants (apiVersion, kind) cannot be overridden
- Type constraints enforce valid values
- Sensible defaults where appropriate
- Optional fields marked with `?`

### app.cue

Defines the application-specific configuration:
- **#AppConfig schema** - Defines what environment files must provide
- **Application details** - Volumes, env vars, ports, health checks
- **Constraints** - Limits on replicas (1-10), resource requirements
- **Instance placeholders** - References to `appConfig` for values filled by env files

**What goes here:**
- ✅ Volumes and volume mounts
- ✅ Environment variables (including secret references)
- ✅ Ports and protocols
- ✅ Labels and annotations
- ✅ Health check configurations
- ✅ Security contexts
- ❌ Image tags
- ❌ Replica counts
- ❌ Resource limits
- ❌ Node selectors

### Environment Files (dev.cue, stage.cue, prod.cue)

Provide concrete values for each environment:

| Aspect | Dev | Stage | Prod |
|--------|-----|-------|------|
| **Replicas** | 1 | 2 | 3 |
| **CPU Request** | 100m | 250m | 500m |
| **Memory Request** | 128Mi | 512Mi | 1Gi |
| **CPU Limit** | 200m | 500m | 1000m |
| **Memory Limit** | 256Mi | 1Gi | 2Gi |
| **Image** | dev-latest | stage-rc | v1.2.3 |
| **Node Selector** | None | Optional | Production nodes |

## Prerequisites

Install CUE:

```bash
# macOS
brew install cue

# Linux
curl -L https://github.com/cue-lang/cue/releases/download/v0.7.0/cue_v0.7.0_linux_amd64.tar.gz | tar xz
sudo mv cue /usr/local/bin/

# Verify installation
cue version
```

## Usage

### Generate Kubernetes YAML

Export configuration for each environment:

```bash
# Development
cue export deployment.cue app.cue dev.cue --out yaml > dev.yaml

# Staging
cue export deployment.cue app.cue stage.cue --out yaml > stage.yaml

# Production
cue export deployment.cue app.cue prod.cue --out yaml > prod.yaml
```

### Validate Configuration

Validate without exporting:

```bash
# Validate development
cue vet deployment.cue app.cue dev.cue

# Validate all environments
cue vet deployment.cue app.cue dev.cue
cue vet deployment.cue app.cue stage.cue
cue vet deployment.cue app.cue prod.cue
```

### Format CUE Files

```bash
cue fmt deployment.cue app.cue dev.cue stage.cue prod.cue
```

### Inspect Configuration

View the unified configuration:

```bash
# See what values are set for dev
cue eval deployment.cue app.cue dev.cue

# See just the appConfig
cue eval deployment.cue app.cue dev.cue -e appConfig
```

## Deployment with kubectl

```bash
# Apply to development
cue export deployment.cue app.cue dev.cue --out yaml | kubectl apply -f -

# Apply to production (be careful!)
cue export deployment.cue app.cue prod.cue --out yaml | kubectl apply -f -
```

## Integration with ArgoCD

### Directory Structure for ArgoCD

Organize your repository for multi-app deployments:

```
.
├── base/
│   └── deployment.cue          # Shared schemas
├── apps/
│   ├── backend/
│   │   └── app.cue            # Backend app config
│   ├── frontend/
│   │   └── app.cue            # Frontend app config
│   └── worker/
│       └── app.cue            # Worker app config
└── environments/
    ├── dev/
    │   ├── backend.cue
    │   ├── frontend.cue
    │   └── worker.cue
    ├── staging/
    │   ├── backend.cue
    │   ├── frontend.cue
    │   └── worker.cue
    └── production/
        ├── backend.cue
        ├── frontend.cue
        └── worker.cue
```

### ArgoCD Application Example

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-production
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourorg/yourrepo
    targetRevision: main
    path: environments/production
    plugin:
      name: cue
      env:
        - name: CUE_FILES
          value: "../../base/deployment.cue ../../apps/backend/app.cue backend.cue"
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### CUE Plugin for ArgoCD

Install the argocd-cue plugin:

```bash
# Add to argocd-cm ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  configManagementPlugins: |
    - name: cue
      generate:
        command: ["sh", "-c"]
        args:
          - |
            cue export $CUE_FILES --out yaml
```

## Customization

### Adding New Environments

Create a new environment file (e.g., `qa.cue`):

```cue
package k8s

appConfig: {
    image: "myapp:qa-v1.0.0"
    replicas: 2
    resources: {
        requests: {cpu: "200m", memory: "256Mi"}
        limits: {cpu: "400m", memory: "512Mi"}
    }
    namespace: "qa"
}
```

### Adding More Applications

When adding multiple apps, structure like this:

**apps/backend/app.cue:**
```cue
package k8s

backendConfig: #AppConfig & {
    replicas: >=1 & <=10
}

deployments: backend: #Deployment & {
    metadata: name: "backend"
    // ... rest of config
}
```

**environments/prod/backend.cue:**
```cue
package k8s

backendConfig: {
    image: "backend:v1.0.0"
    replicas: 3
    resources: {
        requests: {cpu: "500m", memory: "1Gi"}
        limits: {cpu: "1000m", memory: "2Gi"}
    }
}
```

### Overriding Specific Fields

Environment files can override any non-invariant field:

```cue
// prod.cue
package k8s

appConfig: {
    image: "myapp:v1.0.0"
    replicas: 5
    resources: {
        requests: {cpu: "1000m", memory: "2Gi"}
        limits: {cpu: "2000m", memory: "4Gi"}
    }
    namespace: "production"
}

// Override specific deployment fields
deployment: {
    spec: {
        // More aggressive rolling update
        strategy: rollingUpdate: {
            maxSurge: 2
            maxUnavailable: 1
        }

        template: spec: {
            // Add sidecar container
            containers: [..., {
                name: "sidecar"
                image: "sidecar:v1.0"
                // ... sidecar config
            }]
        }
    }
}
```

## Benefits of This Approach

1. **Type Safety** - CUE validates all configurations at build time
2. **DRY Principle** - No duplication across environments
3. **Progressive Refinement** - Layer configurations from generic to specific
4. **Constraints** - Enforce limits (e.g., max 10 replicas) across all environments
5. **Merge Conflicts** - Easier to review changes to specific environments
6. **Documentation** - CUE schemas serve as living documentation
7. **Reusability** - Easy to add new apps and environments
8. **GitOps Ready** - Works seamlessly with ArgoCD and FluxCD

## Common Operations

### View Differences Between Environments

```bash
# Compare dev and prod configurations
diff <(cue export deployment.cue app.cue dev.cue --out yaml) \
     <(cue export deployment.cue app.cue prod.cue --out yaml)
```

### Test Configuration Locally

```bash
# Export and validate with kubectl (dry-run)
cue export deployment.cue app.cue dev.cue --out yaml | kubectl apply --dry-run=client -f -
```

### Generate Documentation

```bash
# Export schema documentation
cue def deployment.cue > schema-docs.cue
```

## Best Practices

1. **Never use `latest` in production** - Always use specific version tags
2. **Test staging before prod** - Validate changes in staging first
3. **Use constraints liberally** - Prevent misconfigurations with CUE constraints
4. **Version your schemas** - Track changes to deployment.cue
5. **Validate in CI** - Run `cue vet` in your CI pipeline
6. **Keep secrets external** - Reference secrets by name, don't embed them
7. **Use meaningful labels** - Enable proper monitoring and service discovery
8. **Document assumptions** - Add comments explaining design decisions

## Troubleshooting

### CUE validation errors

```bash
# Get detailed error information
cue vet -v deployment.cue app.cue prod.cue

# Check specific field
cue eval deployment.cue app.cue prod.cue -e deployment.spec.replicas
```

### Missing fields

If CUE complains about missing fields, ensure all required fields in `#AppConfig` are provided in your environment file.

### Type conflicts

If you see "conflicting values" errors, check that your environment overrides are compatible with the base schema and app constraints.

## Resources

- [CUE Language Specification](https://cuelang.org/docs/references/spec/)
- [CUE Tutorial](https://cuelang.org/docs/tutorials/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

## License

MIT

## Contributing

Contributions welcome! Please ensure all CUE files are formatted (`cue fmt`) and validated (`cue vet`) before submitting.
