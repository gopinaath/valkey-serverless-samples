# shiny-octo-adventure


```

aws cloudformation create-stack  --stack-name serverless-valkey-stack  --template-body file://serverless-valkey.yaml

  ```

```

aws cloudformation create-stack ^
  --stack-name valkey-ec2-stack ^
  --template-body file://valkey-ec2.yaml ^
  --parameters ^
    ParameterKey=VpcId,ParameterValue=vpc-xxxxxxxx ^
    ParameterKey=SubnetId,ParameterValue=subnet-xxxxxxxx ^
    ParameterKey=KeyName,ParameterValue=your-key-pair ^
    ParameterKey=MyIP,ParameterValue=your-ip/32

  
  aws cloudformation create-stack \
  --stack-name valkey-ec2-stack \
  --template-body file://valkey-ec2.yaml \
  --parameters \
    ParameterKey=VpcId,ParameterValue=vpc-xxxxxxxx \
    ParameterKey=SubnetId,ParameterValue=subnet-xxxxxxxx \
    ParameterKey=KeyName,ParameterValue=your-key-pair \
    ParameterKey=MyIP,ParameterValue=your-ip/32

```

```
aws cloudformation delete-stack  --stack-name serverless-valkey-stack

```

```
aws cloudformation delete-stack  --stack-name valkey-ec2-stack
```

