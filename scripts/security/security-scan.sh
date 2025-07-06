#!/bin/bash

# Security Scanning Script for Infrastructure as Code
# This script runs various security tools and generates reports

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPORTS_DIR="reports"
SECURITY_DIR="security-reports"
TERRAFORM_DIR="."
FAIL_ON_CRITICAL=true

# Create reports directory
mkdir -p "$REPORTS_DIR"
mkdir -p "$SECURITY_DIR"

echo -e "${GREEN}🔒 Starting Security Scan...${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print section header
print_section() {
    echo -e "\n${YELLOW}=== $1 ===${NC}"
}

# Function to print result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        if [ "$FAIL_ON_CRITICAL" = true ]; then
            exit 1
        fi
    fi
}

# 1. Checkov Security Scan
print_section "Running Checkov Security Scan"
if command_exists checkov; then
    echo "Running Checkov on Terraform files..."
    checkov -d "$TERRAFORM_DIR" \
        --quiet \
        --output sarif \
        --output-file-path "$REPORTS_DIR/checkov-results.sarif" \
        --download-external-modules true \
        --framework terraform \
        --soft-fail || true
    
    # Extract summary
    CHECKOV_FAILED=$(checkov -d "$TERRAFORM_DIR" --quiet --output json | jq -r '.summary.failed' 2>/dev/null || echo "0")
    CHECKOV_PASSED=$(checkov -d "$TERRAFORM_DIR" --quiet --output json | jq -r '.summary.passed' 2>/dev/null || echo "0")
    
    echo "Checkov Results: $CHECKOV_PASSED passed, $CHECKOV_FAILED failed"
    print_result $CHECKOV_FAILED "Checkov scan completed"
else
    echo "Checkov not installed. Installing..."
    pip install checkov
    checkov -d "$TERRAFORM_DIR" \
        --quiet \
        --output sarif \
        --output-file-path "$REPORTS_DIR/checkov-results.sarif" \
        --download-external-modules true \
        --framework terraform \
        --soft-fail || true
fi

# 2. TFLint Security Scan
print_section "Running TFLint Security Scan"
if command_exists tflint; then
    echo "Running TFLint..."
    tflint --init
    tflint --format json > "$REPORTS_DIR/tflint-results.json" 2>/dev/null || true
    
    # Check for issues
    TFLINT_ISSUES=$(jq -r '.issues | length' "$REPORTS_DIR/tflint-results.json" 2>/dev/null || echo "0")
    print_result $TFLINT_ISSUES "TFLint scan completed"
else
    echo "TFLint not installed. Skipping..."
fi

# 3. Terraform Security Scan
print_section "Running Terraform Security Scan"
if command_exists terraform; then
    echo "Validating Terraform configuration..."
    terraform validate
    print_result $? "Terraform validation completed"
    
    echo "Checking Terraform format..."
    terraform fmt -check -recursive
    print_result $? "Terraform format check completed"
else
    echo "Terraform not installed. Skipping..."
fi

# 4. Bandit Security Scan (for Python code)
print_section "Running Bandit Security Scan"
if command_exists bandit; then
    echo "Scanning Python files for security issues..."
    find . -name "*.py" -not -path "./.venv/*" -not -path "./venv/*" | xargs bandit -f json -o "$REPORTS_DIR/bandit-results.json" || true
    
    # Check for high severity issues
    BANDIT_HIGH=$(jq -r '.results[] | select(.issue_severity == "HIGH") | .issue_text' "$REPORTS_DIR/bandit-results.json" 2>/dev/null | wc -l || echo "0")
    print_result $BANDIT_HIGH "Bandit scan completed"
else
    echo "Bandit not installed. Installing..."
    pip install bandit
    find . -name "*.py" -not -path "./.venv/*" -not -path "./venv/*" | xargs bandit -f json -o "$REPORTS_DIR/bandit-results.json" || true
fi

# 5. Generate Security Summary Report
print_section "Generating Security Summary Report"
cat > "$SECURITY_DIR/security-summary.md" << EOF
# Security Scan Summary

Generated on: $(date)

## Scan Results

### Checkov (Infrastructure Security)
- **Status**: Completed
- **Passed**: $CHECKOV_PASSED
- **Failed**: $CHECKOV_FAILED
- **Report**: [checkov-results.sarif](../reports/checkov-results.sarif)

### TFLint (Terraform Linting)
- **Status**: Completed
- **Issues Found**: $TFLINT_ISSUES
- **Report**: [tflint-results.json](../reports/tflint-results.json)

### Terraform Validation
- **Status**: Completed
- **Configuration Valid**: ✅
- **Format Check**: ✅

### Bandit (Python Security)
- **Status**: Completed
- **High Severity Issues**: $BANDIT_HIGH
- **Report**: [bandit-results.json](../reports/bandit-results.json)

## Security Recommendations

1. **Critical Issues**: Address any failed Checkov checks immediately
2. **High Severity**: Review and fix high-severity Bandit findings
3. **Best Practices**: Follow AWS security best practices for all resources
4. **Regular Scans**: Run this scan regularly in CI/CD pipeline

## Next Steps

1. Review detailed reports in the \`reports/\` directory
2. Address security findings based on priority
3. Update security policies as needed
4. Schedule regular security audits

EOF

echo -e "${GREEN}📋 Security summary generated: $SECURITY_DIR/security-summary.md${NC}"

# 6. Generate SARIF report for GitHub Code Scanning
print_section "Generating SARIF Report for GitHub"
if [ -f "$REPORTS_DIR/checkov-results.sarif" ]; then
    echo "SARIF report available for GitHub Code Scanning"
    echo "File: $REPORTS_DIR/checkov-results.sarif"
else
    echo "No SARIF report generated"
fi

# 7. Final Summary
print_section "Security Scan Summary"
echo -e "${GREEN}✅ Security scan completed successfully!${NC}"
echo -e "📁 Reports saved in: $REPORTS_DIR/"
echo -e "📋 Summary saved in: $SECURITY_DIR/security-summary.md"
echo -e "🔍 Review the reports and address any security findings"

# Exit with appropriate code
if [ "$CHECKOV_FAILED" -gt 0 ] || [ "$TFLINT_ISSUES" -gt 0 ] || [ "$BANDIT_HIGH" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Security issues found. Please review and address them.${NC}"
    exit 1
else
    echo -e "${GREEN}🎉 No critical security issues found!${NC}"
    exit 0
fi 