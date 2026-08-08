# --- Least-privilege replacement for AdministratorAccess on the `admin` group ---
#
# Scoped to what this repo's Terraform actually provisions (EC2/VPC networking,
# the S3 tfstate + CloudTrail-logs buckets, the DynamoDB lock table, CloudTrail,
# Access Analyzer) plus read-only access to the AWS console surfaces already in
# use (billing, Cost Explorer, Compute Optimizer, GuardDuty, DevOps Guru, Health).
#
# EC2 doesn't support resource-level permissions for most actions used here, so
# it's scoped by aws:RequestedRegion instead of resource ARNs.

data "aws_iam_policy_document" "least_privilege" {
  statement {
    sid    = "EC2NetworkAndCompute"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:CreateVpc", "ec2:DeleteVpc", "ec2:ModifyVpcAttribute",
      "ec2:CreateSubnet", "ec2:DeleteSubnet", "ec2:ModifySubnetAttribute",
      "ec2:CreateInternetGateway", "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway", "ec2:DetachInternetGateway",
      "ec2:CreateRouteTable", "ec2:DeleteRouteTable",
      "ec2:CreateRoute", "ec2:DeleteRoute",
      "ec2:AssociateRouteTable", "ec2:DisassociateRouteTable",
      "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateKeyPair", "ec2:ImportKeyPair", "ec2:DeleteKeyPair",
      "ec2:RunInstances", "ec2:TerminateInstances",
      "ec2:StartInstances", "ec2:StopInstances",
      "ec2:ModifyInstanceAttribute", "ec2:ModifyInstanceMetadataOptions",
      "ec2:AllocateAddress", "ec2:ReleaseAddress",
      "ec2:AssociateAddress", "ec2:DisassociateAddress",
      "ec2:CreateTags", "ec2:DeleteTags",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["eu-west-1"]
    }
  }

  statement {
    sid       = "EC2DescribeGlobal"
    effect    = "Allow"
    actions   = ["ec2:DescribeRegions", "ec2:DescribeAvailabilityZones"]
    resources = ["*"]
  }

  statement {
    sid    = "ProjectS3Buckets"
    effect = "Allow"
    actions = [
      "s3:CreateBucket", "s3:DeleteBucket", "s3:ListBucket",
      "s3:GetObject", "s3:PutObject", "s3:DeleteObject",
      "s3:GetBucketVersioning", "s3:PutBucketVersioning",
      "s3:GetEncryptionConfiguration", "s3:PutEncryptionConfiguration",
      "s3:GetBucketPolicy", "s3:PutBucketPolicy", "s3:DeleteBucketPolicy",
      "s3:GetBucketAcl", "s3:PutBucketAcl",
      "s3:GetBucketPublicAccessBlock", "s3:PutBucketPublicAccessBlock",
      "s3:GetLifecycleConfiguration", "s3:PutLifecycleConfiguration",
      "s3:GetBucketTagging", "s3:PutBucketTagging",
      "s3:GetBucketLocation", "s3:GetBucketOwnershipControls", "s3:PutBucketOwnershipControls",
      # Read-only attributes the AWS provider fetches on every refresh of
      # aws_s3_bucket, even when unset - avoids repeated AccessDenied round-trips.
      "s3:GetBucketCORS", "s3:GetBucketLogging", "s3:GetBucketRequestPayment",
      "s3:GetBucketWebsite", "s3:GetAccelerateConfiguration",
      "s3:GetBucketObjectLockConfiguration", "s3:GetReplicationConfiguration",
      "s3:GetBucketNotification",
    ]
    resources = [
      "arn:aws:s3:::resume-live-*",
      "arn:aws:s3:::resume-live-*/*",
    ]
  }

  statement {
    sid       = "S3BucketDiscovery"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }

  statement {
    sid    = "ProjectDynamoDBLockTable"
    effect = "Allow"
    actions = [
      "dynamodb:CreateTable", "dynamodb:DeleteTable", "dynamodb:DescribeTable",
      "dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:DeleteItem",
      "dynamodb:UpdateTable", "dynamodb:TagResource", "dynamodb:ListTagsOfResource",
      "dynamodb:DescribeContinuousBackups", "dynamodb:DescribeTimeToLive",
      "dynamodb:UpdateContinuousBackups", "dynamodb:UpdateTimeToLive",
    ]
    resources = ["arn:aws:dynamodb:eu-west-1:${data.aws_caller_identity.current.account_id}:table/resume-live-*"]
  }

  statement {
    sid    = "CloudTrailAndAccessAnalyzer"
    effect = "Allow"
    actions = [
      "cloudtrail:GetTrailStatus", "cloudtrail:DescribeTrails", "cloudtrail:ListTrails",
      "cloudtrail:CreateTrail", "cloudtrail:UpdateTrail", "cloudtrail:DeleteTrail",
      "cloudtrail:StartLogging", "cloudtrail:StopLogging",
      "cloudtrail:GetEventSelectors", "cloudtrail:PutEventSelectors",
      "cloudtrail:ListTags", "cloudtrail:AddTags",
      "cloudtrail:LookupEvents",
      "access-analyzer:*",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["eu-west-1"]
    }
  }

  statement {
    sid    = "IAMSelfServiceForTerraform"
    effect = "Allow"
    actions = [
      "iam:GetUser", "iam:GetGroup", "iam:ListAccessKeys",
      "iam:ListAttachedGroupPolicies", "iam:ListGroupsForUser",
      "iam:GetPolicy", "iam:GetPolicyVersion", "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion", "iam:DeletePolicyVersion", "iam:SetDefaultPolicyVersion",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/iamadmin",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:group/admin",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/resume-live-least-privilege",
    ]
  }

  statement {
    sid    = "ReadOnlyConsoleSurfaces"
    effect = "Allow"
    actions = [
      "ce:Get*", "ce:Describe*",
      "budgets:ViewBudget", "budgets:Describe*",
      "health:Describe*",
      "compute-optimizer:Get*",
      "guardduty:Get*", "guardduty:List*",
      "devops-guru:Describe*", "devops-guru:List*",
      "aws-portal:View*",
      "account:Get*",
      "freetier:Get*",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "CallerIdentity"
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "least_privilege" {
  name        = "resume-live-least-privilege"
  description = "Scoped replacement for AdministratorAccess on the admin group - resume-live project only"
  policy      = data.aws_iam_policy_document.least_privilege.json
}

# Attached alongside AdministratorAccess for now so it can be validated with a
# real `terraform plan` before AdministratorAccess is detached (see docs/iam-audit.md).
resource "aws_iam_group_policy_attachment" "least_privilege" {
  group      = "admin"
  policy_arn = aws_iam_policy.least_privilege.arn
}
