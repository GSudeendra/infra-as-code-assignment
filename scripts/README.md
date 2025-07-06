# Scripts Directory

This directory contains all automation scripts for the Infrastructure as Code assignment, organized by purpose.

## 📁 Directory Structure

```
scripts/
├── deployment/          # Infrastructure deployment scripts
│   ├── deploy.sh       # Deploy all infrastructure
│   └── destroy.sh      # Destroy all infrastructure
├── testing/            # Testing and validation scripts
│   └── test.sh         # Run comprehensive tests
├── utilities/          # Utility and helper scripts
│   ├── validate-aws-account.sh  # AWS account validation
│   ├── build-lambdas.sh         # Lambda package builder
│   ├── import-log-groups.sh     # CloudWatch log management
│   └── show-structure.sh        # Project structure display
├── pre-terraform-hook.sh        # Pre-deployment validation
└── README.md                    # This file
```

## 🚀 Quick Start

### Root Directory Wrappers
For convenience, you can use these wrapper scripts from the project root:

```bash
./deploy    # Deploy infrastructure
./destroy   # Destroy infrastructure  
./test      # Run tests
```

### Direct Script Usage
Or use the scripts directly:

```bash
# Deployment
./scripts/deployment/deploy.sh
./scripts/deployment/destroy.sh

# Testing
./scripts/testing/test.sh

# Utilities
./scripts/utilities/validate-aws-account.sh
./scripts/utilities/build-lambdas.sh
./scripts/utilities/import-log-groups.sh
./scripts/utilities/show-structure.sh
```

## 📋 Script Details

### Deployment Scripts

#### `deploy.sh`
- **Purpose**: Deploy complete infrastructure
- **Actions**:
  - Validate AWS account
  - Build Lambda packages
  - Deploy remote state infrastructure
  - Deploy main infrastructure
  - Run post-deployment tests
- **Usage**: `./scripts/deployment/deploy.sh`

#### `destroy.sh`
- **Purpose**: Destroy all infrastructure
- **Actions**:
  - Destroy main infrastructure
  - Destroy remote state infrastructure
  - Clean up local files
- **Usage**: `./scripts/deployment/destroy.sh`

### Testing Scripts

#### `test.sh`
- **Purpose**: Comprehensive testing suite
- **Actions**:
  - Run Terraform validation
  - Execute Python tests
  - Perform curl API tests
  - Generate test reports
- **Usage**: `./scripts/testing/test.sh`

### Utility Scripts

#### `validate-aws-account.sh`
- **Purpose**: Validate AWS configuration
- **Features**:
  - Check AWS CLI installation
  - Validate credentials
  - Verify account ID
  - Test permissions
- **Usage**: `./scripts/utilities/validate-aws-account.sh`

#### `build-lambdas.sh`
- **Purpose**: Build Lambda deployment packages
- **Features**:
  - Create ZIP files from Python source
  - Install dependencies
  - Generate deployment-ready packages
- **Usage**: `./scripts/utilities/build-lambdas.sh`

#### `import-log-groups.sh`
- **Purpose**: Manage CloudWatch log groups
- **Features**:
  - List existing log groups
  - Generate Terraform import commands
  - Delete log groups (interactive)
- **Usage**: `./scripts/utilities/import-log-groups.sh`

#### `show-structure.sh`
- **Purpose**: Display project structure and information
- **Features**:
  - Show directory layout
  - Display quick commands
  - Project information
  - Interactive menu
- **Usage**: `./scripts/utilities/show-structure.sh`

### Pre-deployment Scripts

#### `pre-terraform-hook.sh`
- **Purpose**: Pre-deployment validation
- **Actions**:
  - Check Terraform installation
  - Validate configuration
  - Ensure proper setup
- **Usage**: `./scripts/pre-terraform-hook.sh`

## 🔧 Prerequisites

Before running any scripts:

1. **AWS CLI**: Install and configure AWS CLI
2. **Terraform**: Install Terraform (version 1.0+)
3. **Python**: Install Python 3.8+ with pip
4. **Dependencies**: Install Python dependencies
   ```bash
   pip install -r tests/requirements.txt
   ```

## 🎯 Typical Workflow

1. **Setup**:
   ```bash
   ./scripts/utilities/validate-aws-account.sh
   ```

2. **Deploy**:
   ```bash
   ./deploy
   ```

3. **Test**:
   ```bash
   ./test
   ```

4. **Cleanup**:
   ```bash
   ./destroy
   ```

## 🛠️ Troubleshooting

### Common Issues

1. **AWS Credentials**: Run `./scripts/utilities/validate-aws-account.sh`
2. **Lambda Build Issues**: Run `./scripts/utilities/build-lambdas.sh`
3. **Log Group Conflicts**: Use `./scripts/utilities/import-log-groups.sh`
4. **Project Structure**: Run `./scripts/utilities/show-structure.sh`

### Script Permissions

If scripts are not executable:
```bash
chmod +x scripts/**/*.sh
chmod +x deploy destroy test
```

## 📝 Notes

- All scripts include colored output for better readability
- Scripts are designed to be idempotent and safe to re-run
- Error handling is included in all scripts
- Scripts can be run individually or as part of the workflow
- Interactive scripts provide menu options for better UX 