#!/bin/bash

# Check if required arguments are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ] || [ -z "$6" ]; then
  echo "Usage: $0 <StackName> <VpcId> <Ec2SubnetId> <ServerlessValkeySubnetIds> <KeyName> <MyIP>"
  echo "Example: $0 valkey-ec2-stack vpc-12345678 subnet-12345678 subnet-12345678,subnet-87654321 my-ec2-key xxx.xxx.xxx.xxx"
  exit 1
fi

STACK_NAME=$1
VPC_ID=$2
EC2_SUBNET_ID=$3
VALKEY_SUBNET_IDS=$4
EC2_KEY_NAME=$5
MY_IP=$6

# Check if the stack exists
STACK_EXISTS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME 2>&1)

if [[ "$STACK_EXISTS" == *"ValidationError"* && "$STACK_EXISTS" == *"does not exist"* ]]; then
  echo "Stack $STACK_NAME does not exist. Creating stack..."
  aws cloudformation create-stack \
    --stack-name $STACK_NAME \
    --template-body file://combined-valkey-with-ec2-tunnel.json \
    --parameters \
      ParameterKey=VpcId,ParameterValue=$VPC_ID \
      ParameterKey=Ec2SubnetId,ParameterValue=$EC2_SUBNET_ID \
      ParameterKey=ValkeySubnetIds,ParameterValue=$VALKEY_SUBNET_IDS \
      ParameterKey=KeyName,ParameterValue=$EC2_KEY_NAME \
      ParameterKey=MyIP,ParameterValue=$MY_IP
else
  echo "Stack $STACK_NAME exists. Updating stack..."
  aws cloudformation update-stack \
    --stack-name $STACK_NAME \
    --template-body file://combined-valkey-with-ec2-tunnel.json \
    --parameters \
      ParameterKey=VpcId,ParameterValue=$VPC_ID \
      ParameterKey=Ec2SubnetId,ParameterValue=$EC2_SUBNET_ID \
      ParameterKey=ValkeySubnetIds,ParameterValue=$VALKEY_SUBNET_IDS \
      ParameterKey=KeyName,ParameterValue=$EC2_KEY_NAME \
      ParameterKey=MyIP,ParameterValue=$MY_IP
fi