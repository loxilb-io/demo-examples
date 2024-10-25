# Configure the AWS Provider

locals {
  eks_loxilb_arn = "${aws_iam_role.eks_loxilb.arn}"
  new_role_yaml = <<-EOF
    - groups:
      - system:masters
      rolearn: "${aws_iam_role.eks_loxilb.arn}"
      username: loxilb
    EOF
}

data "aws_eks_cluster_auth" "demo" {
  name = "demo"

  depends_on = [
    aws_eks_cluster.demo,
  ]
}

provider "kubernetes" {
  host                   = aws_eks_cluster.demo.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.demo.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.demo.token
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

data "kubernetes_config_map" "aws_auth" {
  metadata {
    name = "aws-auth"
    namespace = "kube-system"
  }

 depends_on = [
    aws_eks_cluster.demo,
 ]
}

resource "null_resource" "wait_cluster" {
  provisioner "local-exec" {
    command = "sleep 120"
  }

  depends_on = [
    aws_eks_cluster.demo,
    aws_eks_node_group.lz-worker-nodes,
    aws_eks_node_group.worker-nodes
  ]
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  force = true

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    # Convert to list, make distinict to remove duplicates, and convert to yaml as mapRoles is a yaml string.
    # replace() remove double quotes on "strings" in yaml output.
    # distinct() only apply the change once, not append every run.
    mapRoles = replace(yamlencode(distinct(concat(yamldecode(data.kubernetes_config_map.aws_auth.data.mapRoles), yamldecode(local.new_role_yaml)))), "\"", "")
  }

  lifecycle {
    ignore_changes = []
    //prevent_destroy = true
  }

  depends_on = [
    null_resource.wait_cluster
  ]
}


resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "rm -f kubeconfig"
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region us-east-1 --name ${aws_eks_cluster.demo.name}"
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region us-east-1 --name ${aws_eks_cluster.demo.name} --kubeconfig kubeconfig"
  }

  provisioner "local-exec" {
    command = "kubectl create configmap kubeconfig --from-file=kubeconfig -n kube-system"
  }

  depends_on = [
    aws_eks_cluster.demo
  ]
}
