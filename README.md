# valkey-serverless-samples

.env file

```
STACK_NAME=valkey-ec2-stack
VPC_ID=vpc-12345678
EC2_SUBNET_ID=subnet-12345678
VALKEY_SUBNET_IDS=\"subnet-12345678,subnet-87654321\"
EC2_KEY_NAME=my_ec2_key
MY_IP=100.100.100.100/32

```



./create-or-update-stack.sh valkey-ec2-stack vpc-12345678 subnet-12345678 \"subnet-12345678,subnet-87654321\" my_ec2_key 100.100.100.100/32
