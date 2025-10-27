# Manifest Validation System

A simple regression testing solution for validating Kubernetes manifests against expected versions using CUE and bash.

## Overview

This validation system compares actual generated manifests against "golden" expected versions to detect unintended changes, similar to snapshot testing.

## Directory Structure

```
cue-example/
├── manifests/              # Actual generated manifests
│   ├── dev/
│   ├── stage/
│   └── prod/
├── expected/               # Expected/golden manifests
│   ├── dev/
│   ├── stage/
│   └── prod/
├── validate-manifests.sh   # Main validation script
└── update-expected.sh      # Update golden files
```

## Quick Start

### 1. Validate All Manifests

```bash
./validate-manifests.sh
```

This will:
- Regenerate manifests from CUE source
- Compare each manifest against its expected version
- Report any divergences

### 2. Validate Specific Environment

```bash
./validate-manifests.sh dev
./validate-manifests.sh stage
./validate-manifests.sh prod
```

### 3. View Detailed Differences

```bash
./validate-manifests.sh --verbose
./validate-manifests.sh --verbose dev
```

Shows unified diff output for divergences.

### 4. Update Expected Files

When you've made intentional changes and want to update the baseline:

```bash
# Preview what will be updated
./update-expected.sh --dry-run

# Update with confirmation
./update-expected.sh

# Update without confirmation
./update-expected.sh --force

# Update specific environment
./update-expected.sh dev
```

## Validation Options

### validate-manifests.sh

```bash
./validate-manifests.sh [OPTIONS] [ENVIRONMENT]

Options:
  --no-regenerate    Skip regenerating manifests from CUE
  --schema          Also validate schema conformance with 'cue vet'
  --verbose, -v     Show detailed diff output
  --help, -h        Show help message

Arguments:
  ENVIRONMENT       Optional: dev, stage, or prod
```

### update-expected.sh

```bash
./update-expected.sh [OPTIONS] [ENVIRONMENT]

Options:
  --force, -f       Skip confirmation prompt
  --dry-run         Show what would be updated without making changes
  --help, -h        Show help message

Arguments:
  ENVIRONMENT       Optional: dev, stage, or prod
```

## Usage Examples

### Basic Workflow

```bash
# Make changes to CUE definitions
vim envs/dev.cue

# Generate and validate
./generate-manifests.sh
./validate-manifests.sh

# If validation fails, review differences
./validate-manifests.sh --verbose

# If changes are intentional, update expected files
./update-expected.sh

# Commit both the CUE changes and updated expected files
git add envs/dev.cue expected/
git commit -m "Update dev environment configuration"
```

### Continuous Integration

```bash
# In CI pipeline, validate without regeneration
./validate-manifests.sh --no-regenerate

# Exit code 0 = all pass, 1 = divergences found
```

### Schema Validation

```bash
# Validate both against expected AND CUE schema
./validate-manifests.sh --schema
```

## How It Works

1. **Regeneration**: Re-generates manifests from CUE source to ensure fresh output
2. **Comparison**: Uses `diff` to compare actual vs expected manifests
3. **Reporting**: Color-coded output showing passed/failed validations
4. **Exit Codes**: Returns 0 if all match, 1 if any divergences

## Benefits

- **No additional dependencies**: Uses only bash, diff, and CUE (already installed)
- **Simple and clear**: Easy to understand and modify
- **Visual feedback**: Color-coded diffs show exactly what changed
- **Selective validation**: Can target specific environments
- **Safe updates**: Confirmation prompts prevent accidental overwrites

## Tips

- Run validation before committing changes
- Keep expected files in version control
- Use `--dry-run` before updating expected files
- Use `--verbose` to understand what changed
- Combine with `--schema` for comprehensive validation

## Troubleshooting

### "Expected directory not found"

Run `./update-expected.sh` to create initial baseline.

### "Actual manifest missing"

Run `./generate-manifests.sh` to generate manifests.

### All validations fail after CUE changes

This is expected! Review changes with `--verbose`, then update expected files with `./update-expected.sh`.

### Want to skip regeneration

Use `--no-regenerate` to validate existing manifests without regenerating from CUE.
