# --- Business-hours scheduling for the k3s instance ---
#
# Running 24/7 costs ~$199.73/year on-demand (t3.small, eu-west-1). Running
# only 8am-7pm Europe/Berlin, weekdays, cuts that to ~11 hrs x 5 days = 55
# hrs/week (~32.7% of a full week) - roughly $65/year, a ~67% reduction with
# zero commitment, versus a 1yr Reserved Instance's ~41% max discount which
# still bills for all 8,760 hrs whether the instance is running or not.
#
# EventBridge Scheduler calls ec2:StartInstances/StopInstances directly via
# its AWS SDK "universal target" integration - no Lambda or SSM Automation
# document needed.
#
# Deliberately references the instance by its known ID/ARN rather than
# aws_instance.k3s - this repo currently has unmerged branches with
# conflicting main.tf state (see docs/vpc-architecture.md, docs/iam-audit.md),
# so tying this to the instance resource would pull in unrelated pending
# diffs (AMI replacement, security group revert) on a plan/apply here.

locals {
  k3s_instance_id  = "i-0f97889aa2cb383a6"
  k3s_instance_arn = "arn:aws:ec2:eu-west-1:828876760854:instance/i-0f97889aa2cb383a6"
}

data "aws_iam_policy_document" "scheduler_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "resume-live-instance-scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduler_trust.json

  tags = { Name = "resume-live-instance-scheduler" }
}

data "aws_iam_policy_document" "scheduler_permissions" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:StartInstances", "ec2:StopInstances"]
    resources = [local.k3s_instance_arn]
  }
}

resource "aws_iam_role_policy" "scheduler" {
  name   = "start-stop-resume-live-instance"
  role   = aws_iam_role.scheduler.id
  policy = data.aws_iam_policy_document.scheduler_permissions.json
}

resource "aws_scheduler_schedule" "start" {
  name       = "resume-live-start"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 8 ? * MON-FRI *)"
  schedule_expression_timezone = "Europe/Berlin"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      InstanceIds = [local.k3s_instance_id]
    })
  }
}

resource "aws_scheduler_schedule" "stop" {
  name       = "resume-live-stop"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 19 ? * MON-FRI *)"
  schedule_expression_timezone = "Europe/Berlin"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      InstanceIds = [local.k3s_instance_id]
    })
  }
}
