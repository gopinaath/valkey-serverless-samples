# Setting up Valkey Serverless Cache with EC2 Bastion Host on AWS

Valkey is a high-performance key-value store compatible with Redis protocols. This guide walks through setting up a serverless Valkey instance on AWS ElastiCache with a secure bastion host architecture. I'll use CloudFormation to automate the entire infrastructure deployment.

## Architecture Overview

My  setup consists of:
1. A serverless ElastiCache running Valkey
2. An EC2 bastion host for secure tunneling
3. Security groups for access control
4. Necessary networking components

## Infrastructure Components

Let's break down the key components of our CloudFormation template:

### Security Groups

First, we create two security groups:
1. For the EC2 bastion host (allows SSH from my IP, obtaine using ``` curl checkip.amazonaws.com```)
2. For the Valkey instance (allows access from the bastion host)

```json
"CombinedValkeyWithEC2TunnelSG": {
  "Type": "AWS::EC2::SecurityGroup",
  "Properties": {
    "GroupDescription": "Enable SSH access via port 22",
    "VpcId": { "Ref": "VpcId" },
    "SecurityGroupIngress": [
      {
        "IpProtocol": "tcp",
        "FromPort": "22",
        "ToPort": "22",
        "CidrIp": { "Ref": "MyIP" }
      }
    ]
  }
}
```

### Bastion Host Configuration

We deploy a t4g.nano instance with the necessary software:

```json
"CombinedValkeyWithEC2TunnelEC2Instance": {
  "Type": "AWS::EC2::Instance",
  "Properties": {
    "InstanceType": "t4g.nano",
    "ImageId": "ami-07dcfc8123b5479a8",
    "UserData": {
      "Fn::Base64": {
                "Fn::Join": [
                  "",
                  [
                    "#!/bin/bash\n",
                    "yum update -y\n",
                    "sudo yum install gcc jemalloc-devel openssl-devel tcl tcl-devel -y\n",
                    "wget https://github.com/valkey-io/valkey/archive/refs/tags/7.2.7.tar.gz\n",
                    "tar xvzf 7.2.7.tar.gz\n",
                    "cd valkey-7.2.7/\n",
                    "make BUILD_TLS=yes install\n"
                  ]
                ]
              }
    }
  }
}
```

### Serverless Valkey Configuration

The Valkey instance is deployed as a serverless ElastiCache:

```json
"ServerlessCache": {
  "Type": "AWS::ElastiCache::ServerlessCache",
  "Properties": {
    "ServerlessCacheName": "CombinedValkeyWithEC2TunnelValkey",
    "Engine": "valkey",
    "DailySnapshotTime": "04:00",
    "SnapshotRetentionLimit": 7,
    "SecurityGroupIds": [
      { "Ref": "CombinedValkeyWithEC2TunnelElasticacheSG" }
    ]
  }
}
```

## Deployment Process

1. Save the CloudFormation template as `combined-valkey-with-ec2-tunnel.json`
2. Use the provided bash script to deploy:

```bash
./create-or-update-stack.sh valkey-ec2-stack vpc-12345678 subnet-12345678 subnet-12345678,subnet-87654321
```

## Accessing Valkey

After deployment, use the output SSH tunnel command to connect:

```bash
ssh -NT -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes -i ${KeyName}.pem -L 6379:${ServerlessCache.Endpoint.Address}:6379 ec2-user@${EC2.PublicIp}
```

This creates a secure tunnel from your local machine to the Valkey instance through the bastion host.

## Best Practices

1. Always use a bastion host for accessing Valkey
2. Open only the ports needed in the security group. 
3. Regularly update the bastion host, or better yet - provision it only when needed and then delete it. 

## Conclusion

This setup provides a secure, scalable Valkey deployment. The serverless nature of ElastiCache means you only pay for what you use, while the bastion host ensures secure access to your data store.
