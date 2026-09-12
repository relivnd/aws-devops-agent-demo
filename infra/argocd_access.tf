# ── Kubernetes authorization for the ArgoCD capability ────────────────────────
#
# Enabling the ArgoCD capability creates an access entry for the capability IAM
# role, but grants it no Kubernetes RBAC on the local cluster — by design, see
# https://docs.aws.amazon.com/eks/latest/userguide/argocd-register-clusters.html
#
#   "An EKS Access Entry is automatically created for the local cluster with the
#    Argo CD Capability Role, but no Kubernetes RBAC permissions are granted by
#    default. This follows the principle of least privilege."
#
# The policies EKS attaches itself (AmazonEKSArgoCDClusterPolicy cluster-wide,
# AmazonEKSArgoCDPolicy in the argocd namespace) only cover ArgoCD's own
# bootstrap: namespace management, its CRDs and API discovery. Without an
# explicit grant, ArgoCD cannot build its cluster cache and every Application
# fails with a ComparisonError such as:
#
#   failed to load initial state of resource StatefulSet.apps: ... forbidden
#
# Demo environment: a single cluster-scoped cluster-admin association keeps this
# to one resource, and covers CRDs from add-ons (for example
# neuronmonitors.cloudwatch.aws.amazon.com) that the narrower managed policies
# such as AmazonEKSAdminViewPolicy do not.
#
# For production the EKS docs recommend the least-privilege split instead, since
# this policy is equivalent to system:masters:
#   * a ClusterRole with apiGroups/resources "*" and get/list/watch verbs, bound
#     to the group "eks-access-entry:<capability role arn>", for the cluster-wide
#     reads ArgoCD needs for discovery, health checks and drift detection
#   * AmazonEKSEditPolicy associated per target namespace, for the writes
resource "aws_eks_access_policy_association" "argocd_capability_cluster_admin" {
  cluster_name  = module.copebit_terraform_eks.cluster_name
  principal_arn = aws_iam_role.argocd_capability.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
