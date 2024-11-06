#!/bin/bash

# Function to load environment variables from .env file
load_env() {
    if [ -f .env ]; then
        echo "Loading configuration from .env file..."
        set -a
        source .env
        set +a
        return 0
    fi
    return 1
}

# Function to validate required parameters
validate_params() {
    local missing_params=()
    
    [[ -z "$STACK_NAME" ]] && missing_params+=("STACK_NAME")
    [[ -z "$VPC_ID" ]] && missing_params+=("VPC_ID")
    [[ -z "$EC2_SUBNET_ID" ]] && missing_params+=("EC2_SUBNET_ID")
    [[ -z "$VALKEY_SUBNET_IDS" ]] && missing_params+=("VALKEY_SUBNET_IDS")
    [[ -z "$EC2_KEY_NAME" ]] && missing_params+=("EC2_KEY_NAME")
    [[ -z "$MY_IP" ]] && missing_params+=("MY_IP")
    
    if [ ${#missing_params[@]} -ne 0 ]; then
        echo "Error: Missing required parameters: ${missing_params[*]}"
        echo "Please provide them either in .env file or as command line arguments"
        echo "Usage: $0 <StackName> <VpcId> <Ec2SubnetId> <ServerlessValkeySubnetIds> <KeyName> <MyIP>"
        echo "Example: $0 valkey-ec2-stack vpc-12345678 subnet-12345678 subnet-12345678,subnet-87654321 my-ec2-key xxx.xxx.xxx.xxx"
        exit 1
    fi
}

# Try to load from .env file first
if ! load_env; then
    # If .env doesn't exist or couldn't be loaded, use command line arguments
    if [ $# -eq 6 ]; then
        STACK_NAME=$1
        VPC_ID=$2
        EC2_SUBNET_ID=$3
        VALKEY_SUBNET_IDS=$4
        EC2_KEY_NAME=$5
        MY_IP=$6
    fi
fi

# Validate that we have all required parameters
validate_params

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