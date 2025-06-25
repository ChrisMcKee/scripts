#!/bin/bash

# Output file
OUTPUT_FILE="organizations_imports.tf"
> "$OUTPUT_FILE"

echo "# Terraform import blocks for AWS Organizations resources" >> "$OUTPUT_FILE"
echo >> "$OUTPUT_FILE"

# 1. aws_organizations_organization
ORG_ID=$(aws organizations describe-organization --query 'Organization.Id' --output text)
echo "import {
  to = aws_organizations_organization.main
  id = \"$ORG_ID\"
}" >> "$OUTPUT_FILE"
echo >> "$OUTPUT_FILE"

# 2. aws_organizations_account
aws organizations list-accounts --query 'Accounts[].{Id:Id, Name:Name}' --output json | jq -c '.[]' | while read -r account; do
    ID=$(echo "$account" | jq -r '.Id')
    NAME=$(echo "$account" | jq -r '.Name' | tr -cd '[:alnum:]_')
    echo "import {
  to = aws_organizations_account.${NAME}_${ID}
  id = \"$ID\"
}" >> "$OUTPUT_FILE"
    echo >> "$OUTPUT_FILE"
done

# 3. aws_organizations_delegated_administrator
aws organizations list-delegated-administrators \
  --query 'DelegatedAdministrators[].{Id:Id, Email:Email}' --output json | jq -c '.[]' | while read -r admin; do
    ID=$(echo "$admin" | jq -r '.Id')
    EMAIL=$(echo "$admin" | jq -r '.Email' | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]')
    
    # Get all service principals for this delegated admin
    for PRINCIPAL in $(aws organizations list-delegated-services-for-account \
        --account-id "$ID" \
        --query 'DelegatedServices[].ServicePrincipal' \
        --output text); do

        PRINCIPAL_CLEAN=$(echo "$PRINCIPAL" | tr -cd '[:alnum:]')
        echo "import {
  to = aws_organizations_delegated_administrator.${EMAIL}_${ID}_${PRINCIPAL_CLEAN}
  id = \"${ID}/${PRINCIPAL}\"
}" >> "$OUTPUT_FILE"
        echo >> "$OUTPUT_FILE"
    done
done

# 4. aws_organizations_organizational_unit
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text)
aws organizations list-organizational-units-for-parent --parent-id "$ROOT_ID" --query 'OrganizationalUnits[].{Id:Id, Name:Name}' --output json | jq -c '.[]' | while read -r ou; do
    ID=$(echo "$ou" | jq -r '.Id')
    NAME=$(echo "$ou" | jq -r '.Name' | tr -cd '[:alnum:]_')
    echo "import {
  to = aws_organizations_organizational_unit.${NAME}_${ID}
  id = \"$ID\"
}" >> "$OUTPUT_FILE"
    echo >> "$OUTPUT_FILE"
done

# 5. aws_organizations_policy
aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query 'Policies[].{Id:Id, Name:Name}' --output json | jq -c '.[]' | while read -r policy; do
    ID=$(echo "$policy" | jq -r '.Id')
    NAME=$(echo "$policy" | jq -r '.Name' | tr -cd '[:alnum:]_')
    echo "import {
  to = aws_organizations_policy.${NAME}_${ID}
  id = \"$ID\"
}" >> "$OUTPUT_FILE"
    echo >> "$OUTPUT_FILE"
done

# 6. aws_organizations_policy_attachment
for POLICY_ID in $(aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query 'Policies[].Id' --output text); do
    for TARGET_ID in $(aws organizations list-targets-for-policy --policy-id "$POLICY_ID" --query 'Targets[].TargetId' --output text); do
        echo "import {
  to = aws_organizations_policy_attachment.policy_attachment_${POLICY_ID}_${TARGET_ID}
  id = \"${TARGET_ID}:${POLICY_ID}\"
}" >> "$OUTPUT_FILE"
        echo >> "$OUTPUT_FILE"
    done
done

# 7. aws_organizations_resource_policy
RESOURCE_POLICY=$(aws organizations describe-resource-policy --query 'ResourcePolicy.PolicyDocument' --output text 2>/dev/null)
if [ -n "$RESOURCE_POLICY" ]; then
    echo "import {
  to = aws_organizations_resource_policy.main
  id = \"main\"
}" >> "$OUTPUT_FILE"
    echo >> "$OUTPUT_FILE"
fi

echo "Terraform import blocks written to $OUTPUT_FILE"
