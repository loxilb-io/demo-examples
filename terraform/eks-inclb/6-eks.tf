# IAM role for eks

locals {
	cluster-iam-role-name = "eks-cluster-loxilb-demo"
}

resource "aws_iam_role" "demo" {
  name = "${local.cluster-iam-role-name}"
  tags = {
    tag-key = "${local.cluster-iam-role-name}"
  }

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "eks.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
POLICY
}

# eks policy attachment

resource "aws_iam_role_policy_attachment" "demo-AmazonEKSClusterPolicy" {
  role       = aws_iam_role.demo.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# bare minimum requirement of eks

resource "aws_eks_cluster" "demo" {
  name     = "demo"
  role_arn = aws_iam_role.demo.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private-us-east-1a.id,
      aws_subnet.private-us-east-1b.id,
      aws_subnet.public-us-east-1a.id,
      aws_subnet.public-us-east-1b.id
      #aws_subnet.public-us-east-1-atl-2a.id,
      #aws_subnet.private-us-east-1-atl-2a.id,
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.demo-AmazonEKSClusterPolicy]
}

output "eks_endpoint" {
  value = aws_eks_cluster.demo.endpoint
}

output "eks_ca_cert" {
  value = aws_eks_cluster.demo.certificate_authority[0].data
}
