# Deployment Scripts

This directory contains scripts to manage the Terraform infrastructure for the AWS China observability demo.

## Prerequisites

- AWS CLI configured with China region credentials
- Terraform >= 1.0 installed
- Appropriate IAM permissions for resource creation

## Scripts

### `bootstrap.sh` (First Time Setup)
Create the S3 bucket and DynamoDB table required for Terraform backend.

**Run this ONCE before any other operations:**

```bash
./scripts/bootstrap.sh <region> [profile]
```

Examples:
```bash
./scripts/bootstrap.sh cn-north-1
./scripts/bootstrap.sh cn-northwest-1 cn
```

### `init.sh`
Initialize Terraform with the appropriate backend configuration.

```bash
./scripts/init.sh <region> [profile]
```

Examples:
```bash
./scripts/init.sh cn-north-1
./scripts/init.sh cn-northwest-1 cn
```

### `validate.sh`
Validate Terraform configuration and formatting.

```bash
./scripts/validate.sh
```

### `plan.sh`
Plan Terraform deployment without applying changes.

```bash
./scripts/plan.sh <environment> <region> [profile]
```

Examples:
```bash
./scripts/plan.sh dev cn-north-1
./scripts/plan.sh dev cn-northwest-1 cn
```

### `deploy.sh`
Deploy infrastructure to AWS.

```bash
./scripts/deploy.sh <environment> <region> [profile]
```

Examples:
```bash
./scripts/deploy.sh dev cn-north-1
./scripts/deploy.sh dev cn-northwest-1 cn
```

### `outputs.sh`
Display Terraform outputs (ALB URLs, endpoints, etc.).

```bash
./scripts/outputs.sh [profile]
```

Examples:
```bash
./scripts/outputs.sh
./scripts/outputs.sh cn
```

### `destroy.sh`
Destroy all infrastructure (with confirmation prompt).

```bash
./scripts/destroy.sh <environment> <region> [profile]
```

Examples:
```bash
./scripts/destroy.sh dev cn-north-1
./scripts/destroy.sh dev cn-northwest-1 cn
```

## Typical Workflow

### First Time Setup

1. **Bootstrap backend resources:**
   ```bash
   ./scripts/bootstrap.sh cn-north-1
   ```

2. **Validate configuration:**
   ```bash
   ./scripts/validate.sh
   ```

3. **Plan deployment:**
   ```bash
   ./scripts/plan.sh dev cn-north-1
   ```

4. **Deploy infrastructure:**
   ```bash
   ./scripts/deploy.sh dev cn-north-1
   ```

5. **Check outputs:**
   ```bash
   ./scripts/outputs.sh
   ```

### Subsequent Deployments

1. **Plan deployment:**
   ```bash
   ./scripts/plan.sh dev cn-north-1
   ```

2. **Deploy infrastructure:**
   ```bash
   ./scripts/deploy.sh dev cn-north-1
   ```

3. **Clean up (when done):**
   ```bash
   ./scripts/destroy.sh dev cn-north-1
   ```

## Supported Regions

- `cn-north-1` (Beijing)
- `cn-northwest-1` (Ningxia)

## AWS Profile Usage

If you have multiple AWS profiles configured, specify the profile name as the last parameter:

```bash
./scripts/deploy.sh dev cn-north-1 cn
```

This will use the `cn` profile from your AWS credentials file.
