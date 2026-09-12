resource "awscc_devopsagent_agent_space" "demo-devops-space" {
  name        = "demo-devops-space"
  description = "This space is for demo purposes"
  operator_app = {
    idc = {
      idc_instance_arn      = "arn:aws:sso:::instance/ssoins-6987995e1cadc282"
      operator_app_role_arn = aws_iam_role.devops_agent_operator_app.arn
    }
  }
}

# resource "awscc_devopsagent_association" "example" {
#   agent_space_id = awscc_devopsagent_agent_space.example.agent_space_id
#   service_id     = "codecommit"
#   configuration = {
#     source_aws = {
#       repository_arn     = "arn:aws:codecommit:us-east-1:697621333100:repository/example-repo"
#       account_id         = "697621333100"
#       account_type       = "source"
#       assumable_role_arn = "arn:aws:iam::697621333100:role/devops-agent-role"
#     }
#   }
# }

# resource "awscc_devopsagent_service" "name" {

# }

# --- Operator app role (web app / IdC auth flow) ------------------------------

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  # Hardcoded on purpose: referencing awscc_devopsagent_agent_space.demo-devops-space
  # here would create a dependency cycle, because the Agent Space references the
  # role ARN in its operator_app block.
  devops_agent_space_arn = "arn:aws:aidevops:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:agentspace/cf5474b0-741d-4cf6-9e8f-9730cd1171a5"

  # Account owning the IAM Identity Center instance / identity store
  # (arn:aws:sso:::instance/ssoins-6987995e1cadc282).
  devops_agent_identity_store_account_id = "478763546586"
}

data "aws_iam_policy_document" "devops_agent_operator_app_trust" {
  statement {
    sid     = "AllowDevOpsAgentToAssumeOperatorAppRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["aidevops.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.devops_agent_space_arn]
    }
  }

  # Required for the IdC flow: lets the service propagate the Identity Center
  # identity into the assumed session. Without it operators get
  # "You are not authorized to view this Agent Space".
  statement {
    sid     = "TrustedIdentityPropagation"
    effect  = "Allow"
    actions = ["sts:SetContext"]

    principals {
      type        = "Service"
      identifiers = ["aidevops.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.devops_agent_space_arn]
    }

    condition {
      test     = "ForAllValues:ArnEquals"
      variable = "sts:RequestContextProviders"
      values   = ["arn:aws:iam::aws:contextProvider/IdentityCenter"]
    }

    condition {
      test     = "Null"
      variable = "sts:RequestContextProviders"
      values   = ["false"]
    }
  }
}

resource "aws_iam_role" "devops_agent_operator_app" {
  name               = "DevOpsAgentRole-WebappIDC-jajliovv"
  description        = "Operator app role for the DevOps Agent Space web app (IAM Identity Center auth flow)"
  assume_role_policy = data.aws_iam_policy_document.devops_agent_operator_app_trust.json
}

resource "aws_iam_role_policy_attachment" "devops_agent_operator_app" {
  role       = aws_iam_role.devops_agent_operator_app.name
  policy_arn = "arn:aws:iam::aws:policy/AIDevOpsOperatorAppAccessPolicy"
}

# Step 5 (IdC only). Step 4 (CMK) is not needed: the Agent Space uses the
# service-owned key, no kms_key_arn is set.
data "aws_iam_policy_document" "devops_agent_operator_app_idc" {
  statement {
    sid    = "AllowDevOpsAgentSSOAccess"
    effect = "Allow"
    actions = [
      "sso:ListInstances",
      "sso:DescribeInstance",
    ]
    resources = ["*"]
  }

  statement {
    sid     = "AllowDevOpsAgentIDCUserAccess"
    effect  = "Allow"
    actions = ["identitystore:DescribeUser"]
    resources = [
      "arn:aws:identitystore::${local.devops_agent_identity_store_account_id}:identitystore/*",
      "arn:aws:identitystore:::user/*",
    ]
  }

  statement {
    sid       = "AllowKmsAccessViaIdentityStore"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:identitystore:identitystore-arn"
      values   = ["arn:*:identitystore::*:identitystore/*"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["identitystore.*.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "devops_agent_operator_app_idc" {
  name   = "DevOpsAgentWebAppIdcAccess"
  role   = aws_iam_role.devops_agent_operator_app.id
  policy = data.aws_iam_policy_document.devops_agent_operator_app_idc.json
}
