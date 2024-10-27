#!/bin/bash

# Check if VPC ID is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <VpcId>"
  exit 1
fi

VPC_ID=$1

# Get the list of Subnet IDs
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text)

# Convert space-separated Subnet IDs to comma-separated
SUBNET_IDS_CSV=$(echo $SUBNET_IDS | tr ' ' ',')

# Write to .env file
echo "SubnetIds=$SUBNET_IDS_CSV" > .env

echo "Subnet IDs have been written to .env file."