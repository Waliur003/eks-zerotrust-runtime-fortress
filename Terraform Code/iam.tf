resource "aws_iam_role" "EKS-Fortress-ControlPlane-Role" {
  name = "EKS-Fortress-ControlPlane-Role"

  #Appended the necessary session tagging principal parameter for EKS automated infrastructure tasks
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.EKS-Fortress-ControlPlane-Role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_block_storage_policy_attachment" {
  role       = aws_iam_role.EKS-Fortress-ControlPlane-Role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_compute_policy_attachment" {
  role       = aws_iam_role.EKS-Fortress-ControlPlane-Role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_load_balancing_policy_attachment" {
  role       = aws_iam_role.EKS-Fortress-ControlPlane-Role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_networking_policy_attachment" {
  role       = aws_iam_role.EKS-Fortress-ControlPlane-Role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
}

# --- WORKER NODE POLICY BOUNDARIES --- #

resource "aws_iam_role" "eks_Fortress_WorkerNode-Role" {
  name = "eks_Fortress_WorkerNode-Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
  role       = aws_iam_role.eks_Fortress_WorkerNode-Role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_ecr_readonly_policy_attachment" {
  role       = aws_iam_role.eks_Fortress_WorkerNode-Role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_cni_policy_attachment" {
  role       = aws_iam_role.eks_Fortress_WorkerNode-Role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}