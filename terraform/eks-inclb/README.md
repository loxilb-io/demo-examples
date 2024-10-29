# Build a high performance EKS Cluster using auto-scaled LoxiLB

This terraform scripts create an EKS cluster across main/local zone with loxilb as an auto-scalable and in-cluster load balancer.

![380345743-13b603f6-b430-4262-9869-bc047a1f91b1](https://github.com/user-attachments/assets/79bb5ca3-8790-46d2-92d1-9b0d89d10bf8)

## Prerequisites before starting
Make sure you have the latest versions of awscli, eksctl, kubectl and terraform tools configured in the host. The host should also have sufficient IAM privileges to do cluster operations among others.

## Steps to create the cluster
By default, these scipts will create an EKS cluster of 3 nodegroups in "us-east-1" region.

```
git clone https://github.com/loxilb-io/demo-examples
cd demo-examples/terraform/eks-inclb
terraform init
terraform apply
```

As per you need, you may also change the default paramenter as below:

In the `0-provider.tf`, we can specify the `region` for the cluster:
```
provider "aws" {
  region = "us-east-1"
}
```

In `1-vpc.tf`, specify the `cidr_block`
```
resource "aws_vpc" "k8svpc" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "k8svpc"
  }
}
```
And, accordingly change the subnet `cidr_block` in `3-subnets.tf` as well.

In `7-nodes.tf`, we can specify the `instance_types` for the EC2 instances:
```
  capacity_type  = "ON_DEMAND"
  instance_types = ["t2.large"]
```

## Cleanup
Use the command below to destroy all resources:
```
terraform destroy
```
