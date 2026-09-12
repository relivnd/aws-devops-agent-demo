# ── EKS Pod Identity for the simple-answer app ────────────────────────────────
#
# Grants the pod running the simple-answer app read access to the DynamoDB
# table holding the answer. The identity is bound to a single Kubernetes
# ServiceAccount in a single namespace via an EKS Pod Identity association, so
# no other workload on the cluster can assume this role.

locals {
  simple_answer_namespace       = "simple-answer"
  simple_answer_service_account = "simple-answer"
}

# Only the EKS Pod Identity service may assume this role. sts:TagSession is
# mandatory: EKS injects the cluster, namespace and service account as session
# tags, and the AssumeRole call fails without it.
data "aws_iam_policy_document" "simple_answer_trust" {
  statement {
    sid     = "AllowEksPodIdentityToAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "simple_answer" {
  name               = "${module.copebit_terraform_eks.cluster_name}-simple-answer"
  description        = "Pod Identity role for the simple-answer app: read access to the simple-answer DynamoDB table"
  assume_role_policy = data.aws_iam_policy_document.simple_answer_trust.json
  tags               = var.env_vars
}

# Least privilege: the app performs a single GetItem against one table.
# No KMS statement is required because the table is encrypted with the AWS
# managed key (aws/dynamodb). Switching the table to a customer managed key
# means adding kms:Decrypt (and kms:GenerateDataKey for writes) on that key.
data "aws_iam_policy_document" "simple_answer_dynamodb_read" {
  statement {
    sid       = "ReadSimpleAnswerTable"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem"]
    resources = [aws_dynamodb_table.simple_answer.arn]
  }
}

resource "aws_iam_role_policy" "simple_answer_dynamodb_read" {
  name   = "SimpleAnswerDynamoDbRead"
  role   = aws_iam_role.simple_answer.id
  policy = data.aws_iam_policy_document.simple_answer_dynamodb_read.json
}

resource "aws_eks_pod_identity_association" "simple_answer" {
  cluster_name    = module.copebit_terraform_eks.cluster_name
  namespace       = local.simple_answer_namespace
  service_account = local.simple_answer_service_account
  role_arn        = aws_iam_role.simple_answer.arn
  tags            = var.env_vars
}
