output "config_map" {
  value = local.config_map_aws_auth
}

output "oidc_issuer" {
  value = aws_eks_cluster.prod_cluster.identity[0].oidc[0].issuer
}

output "node_role" {
  value = aws_iam_role.prod-node.name
}

output "version" {
  value = aws_eks_cluster.prod_cluster.version
}