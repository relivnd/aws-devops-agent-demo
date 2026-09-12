resource "random_string" "this" {
  length  = 6
  special = false
  lower   = true
  upper   = false
}

module "copebit_terraform_kms" {
  source            = "gitlab-external.copebit.ch/tofu-registry/kms/aws"
  version           = "~> 3.0.1"
  env_vars          = merge(var.env_vars, tomap({ namespace = random_string.this.result }))
  multi_region      = false
  create_efs_key    = true
  use_extended_name = true
}

module "copebit_terraform_default_ebs_encryption" {
  source      = "gitlab-external.copebit.ch/tofu-registry/default-ebs-encryption/aws"
  version     = "~> 3.0.4"
  env_vars    = var.env_vars
  kms_key_arn = module.copebit_terraform_kms.ebs_key_arn
}

module "copebit_terraform_s3" {
  source        = "gitlab-external.copebit.ch/tofu-registry/s3/aws"
  version       = "~> 4.0.1" # change in customer environments to pinned releases "~> 4.0.0".
  env_vars      = merge(var.env_vars, tomap({ namespace = random_string.this.result }))
  for_each      = toset(var.s3_bucket_duties)
  kms_key_id    = module.copebit_terraform_kms.s3_key_arn
  bucket_duty   = each.key
  force_destroy = true
  backup_type   = "none"
}

module "copebit_terraform_vpc" {
  source             = "gitlab-external.copebit.ch/tofu-registry/vpc/aws"
  version            = "~> 3.3.0"
  name               = "${var.cluster_name}-${random_string.this.result}-vpc"
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  env_vars           = merge(var.env_vars, tomap({ namespace = random_string.this.result }))
  kms_key_arn        = module.copebit_terraform_kms.default_key_arn
  s3_log_destination = module.copebit_terraform_s3["logs"].bucket_arn
  additional_public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}-${random_string.this.result}" = "shared"
    "kubernetes.io/role/elb"                                                 = 1
    "karpenter.sh/discovery"                                                 = "${var.cluster_name}-${random_string.this.result}"
  }
  additional_private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}-${random_string.this.result}" = "shared"
    "kubernetes.io/role/internal-elb"                                        = 1
    "karpenter.sh/discovery"                                                 = "${var.cluster_name}-${random_string.this.result}"
  }
}

module "copebit_terraform_sns" {
  source                     = "gitlab-external.copebit.ch/tofu-registry/sns/aws"
  version                    = "~> 3.0.0"
  env_vars                   = merge(var.env_vars, tomap({ namespace = random_string.this.result }))
  subscriber_email_addresses = var.subscriber_email_addresses
}

resource "aws_security_group" "this" {
  name        = "allow-tls-${var.cluster_name}-${random_string.this.result}"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.copebit_terraform_vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.copebit_terraform_vpc.vpc_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.env_vars, tomap({ namespace = random_string.this.result }))
}

module "copebit_terraform_eks" {
  source                              = "gitlab-external.copebit.ch/tofu-registry/eks/aws"
  version                             = "21.0.0"
  env_vars                            = var.env_vars
  cluster_name                        = "${var.cluster_name}-${random_string.this.result}"
  vpc_id                              = module.copebit_terraform_vpc.vpc_id
  private_subnet_ids                  = [module.copebit_terraform_vpc.private_subnet_one_az_a_id, module.copebit_terraform_vpc.private_subnet_one_az_b_id, module.copebit_terraform_vpc.private_subnet_one_az_c_id]
  additional_control_plane_cidrs      = [module.copebit_terraform_vpc.vpc_cidr]
  keys_bucket                         = module.copebit_terraform_s3["keys"].bucket_id
  backup_type                         = var.backup_type
  jumphost_sg_id                      = aws_security_group.this.id
  public_access_cidrs                 = var.public_access_cidrs
  kms_key_id                          = module.copebit_terraform_kms.default_key_arn
  kubernetes_version                  = var.kubernetes_version
  create_service_linked_role          = var.create_service_linked_role
  cloudwatch_log_group_retention_days = var.cloudwatch_log_group_retention_days
  node_egress_cidrs                   = var.node_egress_cidrs
  control_plane_egress_cidrs          = var.control_plane_egress_cidrs
  #enabled_log_types              = var.enabled_log_types (should be used in production)
  enabled_log_types = [] #just for testing purposes we disable the logs, as they are spammy and create unnecessary costs during testing.
  spot_nodegroup_settings = {
    create          = false
    instance_types  = ["t3.large", "t3.medium"]
    min_size        = 3
    max_size        = 5
    desired_size    = 3
    node_group_name = "spot-node-group"
  }

  auto_mode_config = var.auto_mode_config

  fargate_profiles     = var.fargate_profiles
  extra_access_entries = var.extra_access_entries
  deletion_protection  = var.deletion_protection
}

module "copebit_terraform_eks_addons" {
  source              = "gitlab-external.copebit.ch/tofu-registry/eks/aws//modules/addons"
  env_vars            = var.env_vars
  cluster_name        = module.copebit_terraform_eks.cluster_name
  kubernetes_version  = module.copebit_terraform_eks.cluster_version
  sns_alert_topic_arn = module.copebit_terraform_sns.alerts_topic_arn
  oidc_provider_arn   = module.copebit_terraform_eks.oidc_provider_arn

  vpc_cni                  = { enabled = var.install_vpc_cni_addon, version = var.vpc_cni_add_on_version }
  kube_proxy               = { enabled = var.install_kube_proxy_addon, version = var.kube_proxy_add_on_version }
  coredns                  = { enabled = var.install_coredns_addon, version = var.core_dns_add_on_version }
  cloudwatch_observability = { enabled = var.install_cloudwatch_observability_addon, version = var.cloudwatch_observability_add_on_version }
  eks_pod_identity         = { enabled = var.install_eks_pod_identity_addon, version = var.eks_pod_identity_add_on_version }
  ebs_csi_driver           = { enabled = var.install_ebs_csi_driver_addon, use_pod_identity = var.create_ebs_csi_pod_identity_association, version = var.aws_ebs_csi_driver_add_on_version }
  efs_csi_driver           = { enabled = var.install_efs_csi_driver_addon, use_pod_identity = var.create_efs_csi_pod_identity_association, version = var.aws_efs_csi_driver_add_on_version }
  s3_csi_driver = {
    enabled               = var.install_s3_csi_driver_addon
    use_pod_identity      = var.create_s3_csi_pod_identity_association
    version               = var.aws_s3_csi_driver_add_on_version
    bucket_list           = [module.copebit_terraform_s3["assets"].bucket_id]
    bucket_paths          = { (module.copebit_terraform_s3["assets"].bucket_id) = ["*"] }
    kms_arns              = [module.copebit_terraform_kms.s3_key_arn]
    storage_class_aliases = ["assets"]
    storage_classes = {
      assets = {
        bucket = module.copebit_terraform_s3["assets"].bucket_id
      }
    }
  }
  metrics_server     = { enabled = var.install_metrics_server_addon, version = var.metrics_server_add_on_version }
  external_dns       = { enabled = var.install_external_dns_addon, version = var.external_dns_add_on_version }
  cert_manager       = { enabled = var.install_cert_manager_addon, version = var.cert_manager_add_on_version }
  kube_state_metrics = { enabled = var.install_kube_state_metrics_addon, version = var.kube_state_metrics_add_on_version }
}

module "copebit_terraform_eks_auto_mode" {
  count        = var.create_auto_compute_nodeclass ? 1 : 0
  source       = "gitlab-external.copebit.ch/tofu-registry/eks/aws//modules/auto-mode"
  env_vars     = var.env_vars
  cluster_name = module.copebit_terraform_eks.cluster_name
  cluster_arn  = module.copebit_terraform_eks.cluster_arn

  # ── Enhanced Logging ────────────────────────────────────────────────────────
  enable_compute_logging        = var.enable_compute_logging
  enable_block_storage_logging  = var.enable_block_storage_logging
  enable_load_balancing_logging = var.enable_load_balancing_logging
  enable_networking_logging     = var.enable_networking_logging
  retention_days                = var.logging_retention_days
  kms_key_id                    = var.logging_kms_key_id

  # ── Compute (NodeClass + NodePool) ──────────────────────────────────────────
  nodeclass = var.create_auto_compute_nodeclass ? {
    name = "auto-mode-nodeclass"
    role = module.copebit_terraform_eks.auto_node_role_name
    subnet_selector_terms = [{
      tags = {
        "Network"                         = "Private"
        "kubernetes.io/role/internal-elb" = "1"
      }
    }]
    security_group_selector_terms = [{
      id = module.copebit_terraform_eks.node_security_group_id
    }]
    snat_policy               = "Random"
    network_policy            = "DefaultAllow"
    network_policy_event_logs = "Enabled"
    ephemeral_storage = {
      size = "20Gi"
    }
    backup_type = "none"
  } : null

  nodepool = var.create_auto_compute_nodeclass ? {
    name                 = "auto-mode-nodepool"
    compute_type         = ["auto"]
    capacity_type        = ["spot", "on-demand"]
    instance_category    = ["c", "m", "r"]
    instance_cpu         = ["1", "2", "4", "8", "16", "32", "36", "48", "64", "72", "96", "128", "192"]
    kubernetes_arch      = ["amd64", "arm64"]
    consolidation_policy = "WhenEmptyOrUnderutilized"
    consolidate_after    = "0s"
    cpu_limit            = "1000"
    memory_limit         = "1000Gi"
    volume_size          = "20"
    expire_after         = "720h"
    weight               = 10
    labels               = {}
    taints               = []
  } : null
}


module "copebit_terraform_eks_pod_identity" {
  source                                                                = "gitlab-external.copebit.ch/tofu-registry/eks/aws//modules/pod-identity"
  env_vars                                                              = var.env_vars
  cluster_name                                                          = module.copebit_terraform_eks.cluster_name
  create_ebs_csi_pod_identity_association                               = var.create_ebs_csi_pod_identity_association
  create_efs_csi_pod_identity_association                               = var.create_efs_csi_pod_identity_association
  create_s3_csi_pod_identity_association                                = var.create_s3_csi_pod_identity_association
  create_aws_load_balancer_pod_identity_association                     = var.create_aws_load_balancer_pod_identity_association
  create_vpc_cni_pod_identity_association                               = var.create_vpc_cni_pod_identity_association
  create_aws_cw_observability_pod_identity_association                  = var.create_aws_cw_observability_pod_identity_association
  create_crossplane_pod_identity_association                            = var.create_crossplane_pod_identity_association
  create_external_secrets_pod_identity_association                      = var.create_external_secrets_pod_identity_association
  external_secrets_secrets_manager_arns                                 = var.external_secrets_secrets_manager_arns
  create_external_dns_pod_identity_association                          = var.create_external_dns_pod_identity_association
  create_sftpgo_pod_identity_association                                = var.create_sftpgo_pod_identity_association
  create_velero_pod_identity_association                                = var.create_velero_pod_identity_association
  sftpgo_policy_arns                                                    = var.sftpgo_policy_arns
  velero_s3_bucket_arns                                                 = var.velero_s3_bucket_arns
  create_secret_csi_pod_identity_association                            = var.create_secret_csi_pod_identity_association
  secret_csi_policy_arns                                                = var.secret_csi_policy_arns
  create_flux_pod_identity_association                                  = var.create_flux_pod_identity_association
  flux_policy_arns                                                      = var.flux_policy_arns
  create_image_reflector_automation_controller_pod_identity_association = var.create_image_reflector_automation_controller_pod_identity_association
  crossplane_pod_identity_associations                                  = var.crossplane_pod_identity_associations
  create_kube_audit_rest_pod_identity_association                       = var.create_kube_audit_rest_pod_identity_association
  kube_audit_rest_logging_bucket                                        = module.copebit_terraform_s3["logs"].bucket_id

  # Mount S3 CSI Config (Setting all these vars is mandatory if Pod Identity is selected for pod permissions)
  s3_csi_bucket_list = [
    module.copebit_terraform_s3["assets"].bucket_id
  ]
  s3_csi_bucket_paths = {
    (module.copebit_terraform_s3["assets"].bucket_id) = ["*"]
  }
}

# ── ArgoCD EKS Capability ─────────────────────────────────────────────────────

data "aws_iam_policy_document" "argocd_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["capabilities.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "argocd_capability" {
  name               = "${var.cluster_name}-${random_string.this.result}-argocd-capability"
  assume_role_policy = data.aws_iam_policy_document.argocd_assume_role.json
  tags               = var.env_vars
}

resource "aws_eks_capability" "argocd" {
  cluster_name              = module.copebit_terraform_eks.cluster_name
  capability_name           = "argocd"
  type                      = "ARGOCD"
  role_arn                  = aws_iam_role.argocd_capability.arn
  delete_propagation_policy = "RETAIN"

  configuration {
    argo_cd {
      aws_idc {
        idc_instance_arn = "arn:aws:sso:::instance/ssoins-6987995e1cadc282"
      }
      namespace = "argocd"
      rbac_role_mapping {
        role = "ADMIN"
        identity {
          id   = "13245802-30a1-708c-1300-e097f74df6e3"
          type = "SSO_USER"
        }
      }
    }
  }

  tags = var.env_vars
}

# ── ECR Repository for Demo App ───────────────────────────────────────────────

module "demo_app_ecr_repository" {
  source  = "gitlab-external.copebit.ch/tofu-registry/ecr/aws"
  version = "3.2.1"

  repository_name = "simple-answer"
}
