#!/bin/bash

# Check if stack name is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <StackName>"
  exit 1
fi

STACK_NAME=$1

# Initiate stack deletion
aws cloudformation delete-stack --stack-name $STACK_NAME

# Wait for the stack to be deleted
echo "Waiting for stack $STACK_NAME to be deleted..."
while true; do
  STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].StackStatus" --output text 2>&1)
  
  if [[ "$STACK_STATUS" == "DELETE_COMPLETE" ]]; then
    echo "Stack $STACK_NAME has been deleted."
    break
  elif [[ "$STACK_STATUS" == "DELETE_FAILED" ]]; then
    echo "Stack deletion failed for $STACK_NAME."
    exit 1
  elif [[ "$STACK_STATUS" == *"ValidationError"* && "$STACK_STATUS" == *"does not exist"* ]]; then
    echo "Stack $STACK_NAME deleted (or never created)."
    break
  else
    echo "Current stack status: $STACK_STATUS. Waiting..."
    sleep 10
  fi
done