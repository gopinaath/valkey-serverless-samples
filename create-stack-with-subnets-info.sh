#!/bin/bash

echo on

# Check if VPC ID is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <VpcId>"
  exit 1
fi

VPC_ID=$1

# Get the list of Subnet IDs
# SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text)

# echo "Subnet IDs: $SUBNET_IDS"

# Convert space-separated Subnet IDs to comma-separated
# SUBNET_IDS_CSV=$(echo $SUBNET_IDS | tr ' ' ',')

# echo "Subnet IDs CSV: $SUBNET_IDS_CSV"

# Run the CloudFormation command with the Subnet IDs as a parameter
aws cloudformation create-stack \
  --stack-name valkey-ec2-stack \
  --template-body file://combined-valkey-with-ec2-tunnel.yaml \
  --parameters \
    ParameterKey=VpcId,ParameterValue=$VPC_ID \
    ParameterKey=SubnetId,ParameterValue=subnet-8b59ffef \
    ParameterKey=KeyName,ParameterValue=mbp-valkey-ec2 \
    ParameterKey=MyIP,ParameterValue=172.115.152.148/32