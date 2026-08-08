# IAM Least-Privilege Audit — resume-live

Date: 2026-08-08
Scope: IAM identities used to manage the resume-live project (AWS account 828876760854, region `eu-west-1`). Other unrelated identities in this shared account (`patientping-*`) were out of scope and untouched.

## Before

| Identity | Policy | Issue |
|---|---|---|
| User `iamadmin` (member of group `admin`) | `AdministratorAccess` (AWS managed) | Full account admin used for interactive Terraform/CLI work — no least-privilege boundary. |
| Role `DemoRoleForEC2` | `IAMReadOnlyAccess` | Not attached to any running instance (the `resume-live` EC2 instance has no instance profile at all). Orphaned, left as-is — out of scope. |

`rds-monitoring-role` and `aws-ec2-spot-fleet-tagging-role` are AWS-managed service-linked roles with appropriately scoped policies; no action needed.

## Why usage-based generation wasn't possible yet

IAM Access Analyzer's policy-generation feature reads from CloudTrail logs. This account had **no CloudTrail trail at all**, so there was zero history to generate a policy from. `iamadmin` was also only ~60 days old, so even enabling CloudTrail today can't retroactively produce 90 days of data.

IAM's built-in Service Last Accessed data (no CloudTrail required) was checked as a substitute, but only showed activity for 21 of ~200 possible services — notably missing `s3` and `iam` despite the project's Terraform managing an S3-backed state bucket. That gap meant the data couldn't be trusted to build a policy on its own (it would have broken the S3 backend).

## What was done

1. **Enabled CloudTrail** (`terraform/main.tf`) — multi-region trail, log file validation on, logs to a dedicated `resume-live-cloudtrail-logs-<account-id>` bucket (versioned, SSE, public access blocked, 365-day lifecycle expiry). Provides the audit trail for future Access Analyzer policy generation and general detective coverage.
2. **Enabled IAM Access Analyzer** (`terraform/main.tf`) — two analyzers:
   - `resume-live-external-access` (type `ACCOUNT`): flags resources shared outside the account.
   - `resume-live-unused-access` (type `ACCOUNT_UNUSED_ACCESS`, 90-day threshold): continuously flags unused permissions, roles, and access keys — the ongoing least-privilege signal that doesn't depend on the CloudTrail backlog.
3. **Drafted a scoped policy** (`terraform/iam.tf`, `resume-live-least-privilege`) from what `terraform/main.tf` actually provisions:
   - EC2 networking/compute — scoped by `aws:RequestedRegion = eu-west-1` (EC2 doesn't support resource-level permissions for most of these actions, so region is the practical boundary).
   - S3 — scoped to `arn:aws:s3:::resume-live-*` (state bucket + CloudTrail logs bucket only).
   - DynamoDB — scoped to the `resume-live-*` lock table.
   - CloudTrail + Access Analyzer management, scoped to `eu-west-1`.
   - IAM self-service (read own user/group, manage the version history of this one policy) — scoped to the specific `iamadmin` user, `admin` group, and `resume-live-least-privilege` policy ARNs only.
   - Read-only console access for billing/Cost Explorer/Compute Optimizer/GuardDuty/DevOps Guru/Health, matching what Service Last Accessed showed was actually being used.
4. **Validated before cutover**:
   - `aws iam simulate-custom-policy` against the policy in isolation (not the live account, which still had AdministratorAccess) confirmed all required actions (`ec2:RunInstances`, `s3:PutObject` on the state bucket, `dynamodb:PutItem` on the lock table, `cloudtrail:DescribeTrails`, etc.) evaluate to `allowed`, and confirmed out-of-scope actions (`iam:CreateUser`, EC2 in `us-east-1`, S3 on an unrelated bucket) evaluate to `implicitDeny`.
   - Attached the new policy to the `admin` group **alongside** `AdministratorAccess` first, then detached `AdministratorAccess` and ran a real `terraform plan` against production credentials to confirm nothing broke.
   - The live test caught two gaps the simulator missed — the AWS provider's refresh calls `s3:GetBucketCORS` and `dynamodb:DescribeContinuousBackups` even when those features are unset. Added the missing read-only actions (scoped to the same project-only ARNs) and re-verified a clean `terraform plan`.

## After

`iamadmin` → group `admin` → `resume-live-least-privilege` only. No AWS-managed broad policy remains attached to any identity in the resume-live scope.

## Rollback

If something unexpected breaks: `aws iam attach-group-policy --group-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess`. The AWS account root user is also always available as an ultimate fallback, independent of any IAM policy changes made here.

## Follow-ups (not yet done)

- Once CloudTrail has accumulated real usage history (30-90 days), re-run IAM Access Analyzer's policy generation against that trail and diff it against `resume-live-least-privilege` to catch anything over- or under-scoped.
- `resume-live-unused-access` analyzer findings should be reviewed periodically — it will flag if any of the granted actions go unused.
- `DemoRoleForEC2` (IAMReadOnlyAccess, unattached) is orphaned and outside this project's scope; consider removing it separately.
