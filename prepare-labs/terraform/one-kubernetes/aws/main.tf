data "aws_eks_cluster_versions" "_" {
  default_only = true
}

module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "~> 21.0"
  name                                     = var.cluster_name
  kubernetes_version                       = data.aws_eks_cluster_versions._.cluster_versions[0].cluster_version
  vpc_id                                   = local.vpc_id
  subnet_ids                               = local.subnet_ids
  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true
  upgrade_policy = {
    # The default policy is EXTENDED, which incurs additional costs
    # when running an old control plane. We don't advise to run old
    # control planes, but we also don't want to incur costs if an
    # old version is chosen accidentally.
    support_type = "STANDARD"
  }

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  eks_managed_node_groups = {
    x86 = {
      name           = "x86"
      instance_types = [local.node_size]
      min_size       = var.min_nodes_per_pool
      max_size       = var.max_nodes_per_pool
      desired_size   = var.min_nodes_per_pool
    }
  }
}

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_vpc_security_group_ingress_rule" "_" {
  security_group_id = module.eks.node_security_group_id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
  description       = "Allow all traffic to Kubernetes nodes (so that we can use NodePorts, hostPorts, etc.)"
}