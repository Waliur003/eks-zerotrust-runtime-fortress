module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = "1.30"

  vpc_id     = aws_vpc.project8_vpc.id 
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  create_iam_role = false
  iam_role_arn    = aws_iam_role.EKS-Fortress-ControlPlane-Role.arn

  endpoint_private_access = true
  endpoint_public_access  = true
  endpoint_public_access_cidrs = [var.admin_ip]

  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

  enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Converted from a List to a Map to match module v21+ type constraints
  addons = { 
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
      })
    }
  }

  eks_managed_node_groups = {
    private-fortress-nodes = {
      name           = "private-fortress-nodes"
      ami_type       = "AL2023_x86_64"
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 3
      desired_size = 2

      capacity_type = "ON_DEMAND"

      create_iam_role = false
      node_role_arn   = aws_iam_role.eks_Fortress_WorkerNode-Role.arn

      labels = {
        role = "private-compute"
      }

      tags = {
        NodeGroup = "private-fortress-nodes"
      }
    }
  }

  tags = {
    Environment = "Zero-Trust-Fortress"
    Project     = "Project-05"
  }
}