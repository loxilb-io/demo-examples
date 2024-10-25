locals {
	iam_role_name = "eks-loxilb-demo"
}

data "aws_iam_policy_document" "eks_loxilb_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:loxilb"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_loxilb" {
  assume_role_policy = data.aws_iam_policy_document.eks_loxilb_assume_role_policy.json
  name               = "${local.iam_role_name}"
}

resource "aws_iam_policy" "eks_loxilb" {
  name = "eks-cluster-demo-policy"

  policy = jsonencode({
    Statement = [{
      Effect   = "Allow"
      Action = "*"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_loxilb_attach" {
  role       = aws_iam_role.eks_loxilb.name
  policy_arn = aws_iam_policy.eks_loxilb.arn
}

output "eks_loxilb_arn" {
  value = aws_iam_role.eks_loxilb.arn
}

/*
provider "kubernetes" {
  host                   = aws_eks_cluster.demo.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.demo.certificate_authority[0].data)
  token                  = aws_eks_cluster.token
}

resource "kubernetes_service_account" "loxilb" {
  metadata {
    name      = "loxilb"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks_loxilb.arn
    }
  }
}

resource "kubernetes_cluster_role" "loxilb" {
  metadata {
    name = "loxilb"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "loxilb" {
  metadata {
    name = "loxilb"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "loxilb"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "loxilb"
    namespace = "kube-system"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.0"

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.eks_loxilb.arn
      username = "loxilb"
      groups   = ["system:masters"]
    },
  ]
}
*/
