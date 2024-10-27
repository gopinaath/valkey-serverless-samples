#!/bin/bash

echo on

# Check if VPC ID is provided as an argument
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <VpcId> <SubnetIds>"
  echo "Example: $0 vpc-12345678 subnet-12345678,subnet-87654321"
  exit 1
fi

VPC_ID=$1
EC2_SUBNET_ID=$2

echo "VPC ID: $VPC_ID"
echo "EC2 Subnet ID: $EC2_SUBNET_ID"

# Get the list of Subnet IDs
# SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text)

# echo "Subnet IDs: $SUBNET_IDS"

# Convert space-separated Subnet IDs to comma-separated
# SUBNET_IDS_CSV=$(echo $SUBNET_IDS | tr ' ' ',')

# echo "Subnet IDs CSV: $SUBNET_IDS_CSV"

# Run the CloudFormation command with the Subnet IDs as a parameter
# aws cloudformation create-stack \
#   --stack-name valkey-ec2-stack \
#   --template-body file://combined-valkey-with-ec2-tunnel.yaml \
#   --parameters \
#     ParameterKey=VpcId,ParameterValue=$VPC_ID \
#     ParameterKey=Ec2SubnetId,ParameterValue=$EC2_SUBNET_ID \
#     ParameterKey=KeyName,ParameterValue=mbp-valkey-ec2 \
#     ParameterKey=MyIP,ParameterValue=108.185.168.226/32


    aws cloudformation update-stack \
  --stack-name valkey-ec2-stack \
  --template-body file://combined-valkey-with-ec2-tunnel.yaml \
  --parameters \
    ParameterKey=VpcId,ParameterValue=$VPC_ID \
    ParameterKey=Ec2SubnetId,ParameterValue=$EC2_SUBNET_ID \
    ParameterKey=KeyName,ParameterValue=mbp-valkey-ec2 \
    ParameterKey=MyIP,ParameterValue=108.185.168.226/32