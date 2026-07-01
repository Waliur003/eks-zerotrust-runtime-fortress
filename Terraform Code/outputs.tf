output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "kubeconfig_connection_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}