# Setting up Valkey Serverless Cache with EC2 Bastion Host on AWS

Valkey is a high-performance key-value store compatible with Redis protocols. This guide walks through setting up a serverless Valkey instance on AWS ElastiCache with a secure bastion host architecture. I'll use CloudFormation to automate the entire infrastructure deployment with parameterized VPC-Ids and Subnet Ids.  At the end of this exercise, AWS Elasticache Valkey can be accessed from the developer's local desktop.  

## Architecture Overview

My  setup consists of:
1. A serverless ElastiCache running Valkey
2. An EC2 bastion host for secure tunneling
3. Security groups for access control

## Infrastructure Components

Let's break down the key components of our CloudFormation template:

### EC2 and its Security Group

First, I create  security group that allows SSH from my IP (obtained using ``` curl checkip.amazonaws.com```).  


```json
"CombinedValkeyWithEC2TunnelSG": {
        "Type": "AWS::EC2::SecurityGroup",
        "Properties": {
          "GroupDescription": "Enable SSH access via port 22",
          "VpcId": {
            "Ref": "VpcId"
          },
          "SecurityGroupIngress": [
            {
              "IpProtocol": "tcp",
              "FromPort": "22",
              "ToPort": "22",
              "CidrIp": {
                "Ref": "MyIP"
              }
            }
          ]
        }
      }
```

Second, I create the EC2 instance and associate it with the security group I created in the first step.  


```json
      "CombinedValkeyWithEC2TunnelEC2Instance": {
        "Type": "AWS::EC2::Instance",
        "Properties": {
          "InstanceType": "t4g.nano",
          "SubnetId": {
            "Ref": "Ec2SubnetId"
          },
          "KeyName": {
            "Ref": "KeyName"
          },
          "SecurityGroupIds": [
            {
              "Ref": "CombinedValkeyWithEC2TunnelSG"
            }
          ],
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

### Serverless Valkey and its Security Group.

Now that previous two steps are completed, I create  security group that allows Valkey's ports(6379 and 6380) from the EC2 instance.  

```json
      "CombinedValkeyWithEC2TunnelElasticacheSG": {
        "Type": "AWS::EC2::SecurityGroup",
        "Properties": {
          "GroupDescription": "Enable Redis/Valkey access via port 6370-6380",
          "VpcId": {
            "Ref": "VpcId"
          },
          "SecurityGroupIngress": [
            {
              "IpProtocol": "tcp",
              "FromPort": "6379",
              "ToPort": "6380",
              "SourceSecurityGroupId": {
                "Ref": "CombinedValkeyWithEC2TunnelSG"
              }
            }
          ]
        }
      }

```

Finally, I deploy Valkey as a serverless ElastiCache.  I specify 2 subnets for the serverless Elasticache (one can specify up to 3 subnets).  

```json
"ServerlessCache": {
        "Type": "AWS::ElastiCache::ServerlessCache",
        "Properties": {
          "ServerlessCacheName": "CombinedValkeyWithEC2TunnelValkey",
          "Engine": "valkey",
          "DailySnapshotTime": "04:00",
          "SnapshotRetentionLimit": 7,
          "SecurityGroupIds": [
            {
              "Ref": "CombinedValkeyWithEC2TunnelElasticacheSG"
            }
          ],
          "SubnetIds": [
            {
              "Fn::Select": [
                "0",
                {
                  "Ref": "ValkeySubnetIds"
                }
              ]
            },
            {
              "Fn::Select": [
                "1",
                {
                  "Ref": "ValkeySubnetIds"
                }
              ]
            }
          ]
        }
      }
```

I specify ouptuts from AWS CloudFormation:

```json
    "Outputs": {
      "ServerlessCacheId": {
        "Description": "ID of the serverless cache",
        "Value": {
          "Ref": "ServerlessCache"
        }
      },
      "ServerlessCacheEndpoint": {
        "Description": "Endpoint for the serverless cache",
        "Value": {
          "Fn::GetAtt": [
            "ServerlessCache",
            "Endpoint.Address"
          ]
        }
      },
      "InstanceId": {
        "Description": "Instance ID of the newly created EC2 instance",
        "Value": {
          "Ref": "CombinedValkeyWithEC2TunnelEC2Instance"
        }
      },
      "PublicDNS": {
        "Description": "Public DNSName of the newly created EC2 instance",
        "Value": {
          "Fn::GetAtt": [
            "CombinedValkeyWithEC2TunnelEC2Instance",
            "PublicDnsName"
          ]
        }
      },
      "PublicIP": {
        "Description": "Public IP address of the newly created EC2 instance",
        "Value": {
          "Fn::GetAtt": [
            "CombinedValkeyWithEC2TunnelEC2Instance",
            "PublicIp"
          ]
        }
      },
      "SSHCommand": {
        "Description": "Command to SSH into the instance",
        "Value": {
          "Fn::Sub": "ssh -i ${KeyName}.pem ec2-user@${CombinedValkeyWithEC2TunnelEC2Instance.PublicIp}"
        }
      }
    }

```

Finally I run the CloudFormation template at the CLI.  One can also do the same using AWS Console.  
The parameters required for the CloudFormation CLI can be passed using command line parameters:

```shell
  aws cloudformation create-stack \
    --stack-name $STACK_NAME \
    --template-body file://combined-valkey-with-ec2-tunnel.json \
    --parameters \
      ParameterKey=VpcId,ParameterValue=vpc-12345678 \
      ParameterKey=Ec2SubnetId,ParameterValue=subnet-12345678 \
      ParameterKey=ValkeySubnetIds,ParameterValue=subnet-12345678,subnet-87654321 \
      ParameterKey=KeyName,ParameterValue=ec2-key \
      ParameterKey=MyIP,ParameterValue=XXX.XXX.XXX.XXX/32

```


## Accessing Valkey

After deployment, fro my laptop, I set up SSH tunnel:

```bash
ssh -i ${KeyName}.pem -L 6379:${ServerlessCache.Endpoint.Address}:6379 ec2-user@${EC2.PublicIp}
```

This creates a secure tunnel with port forwarding from my local machine to   Elasticache serverless Valkey through the bastion host.

In a separate shell window, I connect to Elasticache Valkey using ```redis-cli```:

```
% redis-cli --tls

127.0.0.1:6379> set name1 "John Smith"
OK
127.0.0.1:6379> get name1
"John Smith"

```

### Best Practices

1. Always use a bastion host for accessing Valkey.  
2. Open only the ports needed in the security group. 
3. Regularly update the bastion host, or better yet - provision it only when needed and then delete it. 

## Conclusion

This setup provides a secure, scalable Valkey deployment. The serverless nature of ElastiCache Valkey means I only pay for what I use, while the bastion host ensures secure access to my data store.

If you are following these steps, remember to regularly update security group rules, monitor access patterns, and keep the bastion host updated with the latest security patches.
