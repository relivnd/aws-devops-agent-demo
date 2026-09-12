variable "env_vars" {
  type        = map(any)
  description = "Environment variables for main module"
  default = {
    namespace = "copebit"
    stage     = "test"
    name      = "eks"
    TF-Module = "eks"
    delimiter = "-"
  }
}

variable "terratest_tags" {
  description = "Tags to be used by terratests"
  type        = map(any)
  default     = null
}

variable "aws_region" {
  type        = string
  description = "AWS Region to use"
  default     = "eu-central-1"
}

variable "subscriber_email_addresses" {
  description = "Subscription emails for events & alerts."
  type        = map(list(string))
  default = {
    "alerts"          = ["copebit-example@copebit.ch"]
    "critical_alerts" = ["copebit-example@copebit.ch"]
    "events"          = ["copebit-example@copebit.ch"]
    "pipeline_events" = ["copebit-example@copebit.ch"]
  }
}

variable "s3_bucket_duties" {
  type        = list(string)
  description = "S3 buckets that need to be created"
  default     = ["logs", "keys", "assets"]
}

variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster that is being provisioned."
  default     = "copebit-eks-cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "The desired Kubernetes version for your cluster."
  default     = "1.35"
}

variable "backup_type" {
  type        = string
  description = <<EOF
  AWS backup plan for EKS Nodes and Karpenter Nodes. Short Backup plan retains backup for 2 years(24 months) and long backup plan
  retains backup for 5 years if cold storage is supported on product being provisioned
EOF
  default     = "none"
  validation {
    condition     = contains(["long", "short", "none", "short-local", "long-local", "short-remote", "long-remote"], var.backup_type)
    error_message = "It can be either long, short, short-local, long-local, short-remote and long-remote. Select none if you don't want to perform backup."
  }
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "CIDR(s) to allow public access to Kubernetes API. Should only be used for non-production environments."
  default     = ["0.0.0.0/0"]
}

# Create Addons
variable "install_coredns_addon" {
  type        = bool
  description = "Install coredns add-on. Set `enable_cilium` to false when using this."
  default     = false
}

variable "install_kube_proxy_addon" {
  type        = bool
  description = "Install kube-proxy add-on"
  default     = false
}

variable "install_vpc_cni_addon" {
  type        = bool
  description = "Install vpc-cni add-on"
  default     = false
}

variable "install_cloudwatch_observability_addon" {
  type        = bool
  description = "Install cloudwatch observability add-on"
  default     = true
}

variable "install_eks_pod_identity_addon" {
  type        = bool
  description = "Install eks pod identity add-on"
  default     = true
}

variable "install_ebs_csi_driver_addon" {
  type        = bool
  description = "Install ebs-csi driver add-on"
  default     = false
}

variable "install_efs_csi_driver_addon" {
  type        = bool
  description = "Install efs-csi driver add-on"
  default     = true
}

variable "install_s3_csi_driver_addon" {
  type        = bool
  description = "Install s3-csi driver add-on"
  default     = true
}

variable "install_metrics_server_addon" {
  type        = bool
  description = "Install metrics-server add-on"
  default     = true
}

variable "install_cert_manager_addon" {
  type        = bool
  description = "Install cert-manager add-on"
  default     = true
}

variable "install_external_dns_addon" {
  type        = bool
  description = "Install external DNS add-on"
  default     = true
}

variable "install_kube_state_metrics_addon" {
  type        = bool
  description = "Install kube-state-metrics add-on"
  default     = true
}

# Addon Versions
variable "core_dns_add_on_version" {
  type        = string
  description = "Provide the add_on version for coreddns."
  default     = null
}

variable "kube_proxy_add_on_version" {
  type        = string
  description = "Provide the add_on version for kube-proxy."
  default     = null
}

variable "vpc_cni_add_on_version" {
  type        = string
  description = "Provide the add_on version for vpc-cni."
  default     = null
}

variable "aws_ebs_csi_driver_add_on_version" {
  type        = string
  description = "Provide the add_on version for aws-ebs-csi-driver."
  default     = null
}

variable "aws_efs_csi_driver_add_on_version" {
  type        = string
  description = "Provide the add_on version for aws-efs-csi-driver."
  default     = null
}

variable "aws_s3_csi_driver_add_on_version" {
  type        = string
  description = "Provide the add_on version for aws-s3-csi-driver."
  default     = null
}

variable "cloudwatch_observability_add_on_version" {
  type        = string
  description = "Provide the add_on version for cloudwatch observability"
  default     = null
}

variable "eks_pod_identity_add_on_version" {
  type        = string
  description = "Provide the add on version for eks pod identity"
  default     = null
}

variable "metrics_server_add_on_version" {
  type        = string
  description = "Provide the add on version for metrics server"
  default     = null
}

variable "cert_manager_add_on_version" {
  type        = string
  description = "Provide the add on version for cert manager"
  default     = null
}

variable "external_dns_add_on_version" {
  type        = string
  description = "Provide the add on version for external dns"
  default     = null
}

variable "kube_state_metrics_add_on_version" {
  type        = string
  description = "Provide the add on version for kube-state-metrics"
  default     = null
}

variable "auto_mode_config" {
  type        = any
  description = "Auto mode configuration"
  default = {
    enabled    = true
    node_pools = ["system", "general-purpose"]
  }
}

variable "create_auto_compute_nodeclass" {
  type        = bool
  description = "Specify whetehr to create node class for auto compute mode"
  default     = true
}

variable "fargate_profiles" {
  type = map(object({
    name       = string
    subnet_ids = list(string)
    selectors = list(object({
      namespace = optional(string)
      labels    = optional(map(string))
    }))
  }))
  description = "Configuration for the fargate profiles"
  default     = {}
}

variable "extra_access_entries" {
  type = map(object({
    principal_arn     = string
    type              = optional(string, "STANDARD")
    kubernetes_groups = optional(list(string))
    policy_associations = map(object({
      policy_arn = string
      access_scope = object({
        namespaces = optional(list(string))
        type       = string
      })
    }))
  }))
  description = "Map of the IAM entities to grant access to the K8s groups"
  default     = {}
}

variable "create_service_linked_role" {
  type        = string
  description = "Create service linked role for spot instances"
  default     = false
}

variable "control_plane_egress_cidrs" {
  type        = list(string)
  description = "CIDR blocks for control plane security group egress. Restricts outbound traffic from the EKS control plane. Defaults to VPC CIDR when empty. Include VPC CIDR and any subnet CIDRs where nodes/VPC endpoints reside."
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.control_plane_egress_cidrs :
      can(regex("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(/([0-9]|[1-2][0-9]|3[0-2]))$", cidr)) ||
      can(regex("^[0-9a-fA-F:]+/([0-9]|[1-9][0-9]|1[0-2][0-8])$", cidr))
    ])
    error_message = "CIDRs must be IPv4 (x.x.x.x/0-32) or IPv6 (e.g. ::/0 or 2001:db8::/32)."
  }
}

variable "node_egress_cidrs" {
  type        = list(string)
  description = "CIDR blocks for node security group egress. Overrides upstream egress_all rule. Defaults to control_plane_egress_cidrs when empty. Set to [\"0.0.0.0/0\"] if nodes need unrestricted internet (e.g. no VPC endpoints for ECR)."
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.node_egress_cidrs :
      can(regex("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(/([0-9]|[1-2][0-9]|3[0-2]))$", cidr)) ||
      can(regex("^[0-9a-fA-F:]+/([0-9]|[1-9][0-9]|1[0-2][0-8])$", cidr))
    ])
    error_message = "CIDRs must be IPv4 (x.x.x.x/0-32) or IPv6 (e.g. ::/0 or 2001:db8::/32)."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "enabled_log_types" {
  type        = list(string)
  description = "Controlplane logging enabled. Expected values: api, audit, authenticator, controllerManager, scheduler"
  default     = ["api", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition     = alltrue([for log_type in var.enabled_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)])
    error_message = "Invalid log type. Expected values: api, audit, authenticator, controllerManager, scheduler"
  }
}

# crossplane-pod-identity-association
variable "create_crossplane_pod_identity_association" {
  description = "Whether to create pod identity association for Crossplane"
  type        = bool
  default     = false
}

variable "crossplane_pod_identity_associations" {
  description = "Map of Crossplane pod identity associations"
  type = map(object({
    service_account = string
    iam_policy_arns = map(string)
    deny_policy     = bool
  }))
  default = {
    provider_aws_s3 = {
      service_account = "provider-aws-s3-sa"
      iam_policy_arns = {}
      deny_policy     = false
    }
    provider_aws_iam = {
      service_account = "provider-aws-iam-sa"
      iam_policy_arns = {}
      deny_policy     = false
    }
  }
}

# ebs-csi-pod-identity-association
variable "create_ebs_csi_pod_identity_association" {
  description = "Whether to create pod identity association for EBS CSI driver"
  type        = bool
  default     = false
}

# efs-csi-pod-identity-association
variable "create_efs_csi_pod_identity_association" {
  description = "Whether to create pod identity association for EFS CSI driver"
  type        = bool
  default     = false
}

# s3-csi-pod-identity-association
variable "create_s3_csi_pod_identity_association" {
  description = "Whether to create pod identity association for S3 CSI driver"
  type        = bool
  default     = false
}

# sftpgo
variable "create_sftpgo_pod_identity_association" {
  description = "Whether to create pod identity association for SFTPGo"
  type        = bool
  default     = false
}

variable "sftpgo_policy_arns" {
  description = "SFTPGO Policy ARNS"
  type        = map(string)
  default     = {}
}

# aws-load-balancer
variable "create_aws_load_balancer_pod_identity_association" {
  description = "Whether to create pod identity association for AWS Load Balancer Controller"
  type        = bool
  default     = false
}

# velero
variable "create_velero_pod_identity_association" {
  description = "Whether to create pod identity association for Velero"
  type        = bool
  default     = false
}

variable "velero_s3_bucket_arns" {
  description = "S3 bucket ARNs for Velero backups"
  type        = string
  default     = ""
}

# External Secrets
variable "create_external_secrets_pod_identity_association" {
  description = "Whether to create pod identity for external secrets"
  type        = bool
  default     = false
}

variable "external_secrets_secrets_manager_arns" {
  description = "Specify the secret manager arns of the secrets external-secret should access"
  type        = list(string)
  default     = ["*"]
}

# AWS CW Observability Pod Identity
variable "create_aws_cw_observability_pod_identity_association" {
  description = "Whether to create pod identity for AWS CW Observability"
  type        = bool
  default     = true
}

# External DNS Pod Identity
variable "create_external_dns_pod_identity_association" {
  description = "Whether to create pod identity for external dns"
  type        = bool
  default     = false
}

# VPC CNI Pod Identity
variable "create_vpc_cni_pod_identity_association" {
  description = "Whether to create pod identity for VPC CNI"
  type        = bool
  default     = false
}

# secret-csi-pod-identity-association
variable "create_secret_csi_pod_identity_association" {
  description = "Whether to create pod identity association for Secret CSI"
  type        = bool
  default     = false
}

variable "secret_csi_policy_arns" {
  description = "List of IAM policy ARNs to attach to Secret CSI role"
  type        = map(string)
  default     = {}
}

variable "cloudwatch_log_group_retention_days" {
  description = "The number of days to retain EKS cluster CloudWatch logs."
  type        = number
  default     = 30
}

variable "create_flux_pod_identity_association" {
  description = "Whether to create pod identity for FluxCD"
  type        = bool
  default     = true
}

variable "flux_policy_arns" {
  description = "List of IAM policy ARNs to attach to Flux role"
  type        = map(string)
  default = {
    ecr_read_only = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    ecr_pull_only = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  }
}

variable "create_image_reflector_automation_controller_pod_identity_association" {
  description = "Whether to create pod identity for Image Reflector Automation & Image Automation Controller Controller"
  type        = bool
  default     = true
}

# ── Auto Mode Enhanced Logging ────────────────────────────────────────────────

variable "enable_compute_logging" {
  description = "Enable delivery of Auto Mode (compute) logs to CloudWatch."
  type        = bool
  default     = true
}

variable "enable_block_storage_logging" {
  description = "Enable delivery of EBS CSI driver (block-storage) logs to CloudWatch."
  type        = bool
  default     = true
}

variable "enable_load_balancing_logging" {
  description = "Enable delivery of AWS Load Balancer Controller (load-balancing) logs to CloudWatch."
  type        = bool
  default     = true
}

variable "enable_networking_logging" {
  description = "Enable delivery of VPC CNI / IPAM (networking) logs to CloudWatch."
  type        = bool
  default     = true
}

variable "logging_retention_days" {
  description = "Number of days to retain logs in each CloudWatch Log Group."
  type        = number
  default     = 30
}

variable "logging_kms_key_id" {
  description = "Optional ARN of a KMS key to encrypt CloudWatch Log Groups. If omitted, AWS-managed encryption is used."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Protects the cluster from deleting accidently"
  type        = bool
  default     = false
}

# kube-audit-rest-pod-identity-association
variable "create_kube_audit_rest_pod_identity_association" {
  description = "Whether to create pod identity association for kube-audit-rest"
  type        = bool
  default     = false
}
