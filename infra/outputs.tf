output "cluster_arn" {
  value       = module.copebit_terraform_eks.cluster_arn
  description = "EKS Cluster ARN"
}

output "oidc_provider_url" {
  value       = module.copebit_terraform_eks.oidc_provider_url
  description = "OIDC Provider URL"
}

output "oidc_provider_arn" {
  value       = module.copebit_terraform_eks.oidc_provider_arn
  description = "OIDC Provider URL"
}

output "endpoint" {
  value       = module.copebit_terraform_eks.endpoint
  description = "EKS Cluster API endpoint"
}

output "private_key" {
  value       = module.copebit_terraform_eks.private_key
  description = "Download Private key to access the worker nodes."
}

output "kube_config" {
  value       = module.copebit_terraform_eks.kube_config
  description = "Run this command to get the KubeConfig file for this cluster."
}

output "auto_node_role_name" {
  value       = module.copebit_terraform_eks.auto_node_role_name
  description = "EKS node instance role name"
}

output "auto_node_role_arn" {
  value       = module.copebit_terraform_eks.auto_node_role_arn
  description = "EKS node instance role arn"
}

output "spot_node_role_arn" {
  value       = module.copebit_terraform_eks.node_role_arn
  description = "EKS spot node instance role arn"
}

output "spot_node_role_name" {
  value       = module.copebit_terraform_eks.node_role_name
  description = "EKS spot node instance role name"
}

output "cluster_name" {
  value       = module.copebit_terraform_eks.cluster_name
  description = "EKS Cluster Name"
}

output "cluster_version" {
  value       = module.copebit_terraform_eks.cluster_version
  description = "The Kubernetes version for the cluster."
}

output "certificate_authority_data" {
  value       = module.copebit_terraform_eks.certificate_authority_data
  description = "Base64 encoded certificate data required to communicate with the cluster."
}

# SNS
output "sns_alert_topic_arn" {
  value       = module.copebit_terraform_sns.alerts_topic_arn
  description = "ARN of the SNS alert topic."
}

# KMS
output "kms_default_key_arn" {
  value       = module.copebit_terraform_kms.default_key_arn
  description = "ARN of the default KMS key used for encryption."
}

output "kms_efs_key_arn" {
  value       = module.copebit_terraform_kms.efs_key_arn
  description = "ARN of the EFS KMS key used for encryption."
}

output "kms_s3_key_arn" {
  value       = module.copebit_terraform_kms.s3_key_arn
  description = "ARN of the S3 KMS key used for encryption."
}

# S3
output "s3_asset_bucket_name" {
  value       = module.copebit_terraform_s3["assets"].bucket_id
  description = "Name of the assets bucket"
}

output "logs_bucket_name" {
  value       = module.copebit_terraform_s3["logs"].bucket_id
  description = "Name of the logging bucket"
}

# VPC
output "vpc_id" {
  value       = module.copebit_terraform_vpc.vpc_id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = module.copebit_terraform_vpc.vpc_cidr
  description = "VPC CIDR"
}

output "vpc_private_subnet_one_az_a_id" {
  value       = module.copebit_terraform_vpc.private_subnet_one_az_a_id
  description = "ID of the private subnet in AZ A."
}

output "vpc_private_subnet_one_az_b_id" {
  value       = module.copebit_terraform_vpc.private_subnet_one_az_b_id
  description = "ID of the private subnet in AZ B."
}

output "vpc_private_subnet_one_az_c_id" {
  value       = module.copebit_terraform_vpc.private_subnet_one_az_c_id
  description = "ID of the private subnet in AZ C."
}

output "deletion_protection_setting" {
  value       = module.copebit_terraform_eks.deletion_protection_setting
  description = "EKS Deletion Protection Setting"
}

# ── Auto Mode Enhanced Logging ────────────────────────────────────────────────

output "auto_logging_enabled_log_types" {
  value       = module.copebit_terraform_eks_auto_mode[*].enabled_log_types
  description = "List of Auto Mode log types enabled for CloudWatch delivery."
}

output "auto_logging_log_group_names" {
  value       = module.copebit_terraform_eks_auto_mode[*].log_group_names
  description = "Map of log type to CloudWatch Log Group name."
}

output "terratest_tags" {
  value       = var.terratest_tags
  description = "Terratest Tags"
}

# ── simple-answer app ─────────────────────────────────────────────────────────

output "simple_answer_table_name" {
  value       = aws_dynamodb_table.simple_answer.name
  description = "Name of the DynamoDB table holding the answer."
}

output "simple_answer_table_arn" {
  value       = aws_dynamodb_table.simple_answer.arn
  description = "ARN of the DynamoDB table holding the answer."
}

output "simple_answer_role_arn" {
  value       = aws_iam_role.simple_answer.arn
  description = "ARN of the Pod Identity role assumed by the simple-answer pods."
}

output "simple_answer_image_repository" {
  value       = "${module.demo_app_ecr_repository.registry_url}/${module.demo_app_ecr_repository.repository_name}"
  description = "ECR repository for the simple-answer container image (tag with :v1 etc.)."
}
