# -------------------------------------------------------------------
# IAM Roles
# -------------------------------------------------------------------

data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                  = "${local.tags.appname}-lambda-role"
  assume_role_policy    = data.aws_iam_policy_document.this.json
  #permissions_boundary  = join("", ["arn:aws:iam::", "644594778971", ":policy/WorkloadPermissionsBoundary"])
  permissions_boundary  = var.permissions_boundary 
  tags                  = local.tags
}

data "aws_iam_policy_document" "asg_policy" {
  statement {
    actions = [
      "autoscaling:DescribeScalingProcessTypes",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeTags",
      "autoscaling:CreateOrUpdateTags",
      "autoscaling:SuspendProcesses",
      "autoscaling:ResumeProcesses",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "asg_role_policy" {
  name   = "${local.tags.appname}-asg-role-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.asg_policy.json
}

data "aws_iam_policy_document" "ec2_policy" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:CreateTags",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances",
      "ec2:TerminateSpotInstances",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "ec2_role_policy" {
  name   = "${local.tags.appname}-ec2-role-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.ec2_policy.json
}

data "aws_iam_policy_document" "rds_policy" {
  statement {
    actions = [
      "rds:DescribeDBClusters",
      "rds:AddTagsToResource",
      "rds:ListTagsForResource",
      "rds:StartDBCluster",
      "rds:StopDBCluster",
      "rds:StartDBInstance",
      "rds:StopDBInstance",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "rds_role_policy" {
  name   = "${local.tags.appname}-rds-role-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.rds_policy.json
}

data "aws_iam_policy_document" "tag_resources_policy" {
  statement {
    actions = [
      "tag:GetResources",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "tag_resources_role_policy" {
  name   = "${local.tags.appname}-tag_resources_role_policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.tag_resources_policy.json
}

data "aws_iam_policy_document" "kms_policy" {
  statement {
    actions = [
      "kms:TagResource",
      "kms:UntagResource",
      "kms:Get*",
      "kms:List*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:Create*",
      "kms:Delete*",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "kms_role_policy" {
  name   = "${local.tags.appname}-kms_role_policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.kms_policy.json
}


data "aws_iam_policy_document" "lambda_logging_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.this.arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_logging_role_policy" {
  name   = "${local.tags.appname}-lambda-logging-role-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.lambda_logging_policy.json
}

# -------------------------------------------------------------------
# Lambda Function 
# -------------------------------------------------------------------

data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/app"
  output_path = "${path.module}/.aws_scheduler.zip" # The version should match with the latest git tag
}

resource "aws_lambda_function" "this" {
  filename      = data.archive_file.this.output_path
  function_name = local.tags.appname 
  role          = aws_iam_role.this.arn
  handler       = "aws_scheduler.app.lambda_handler"
  runtime       = "python3.9"
  timeout       = "500"

  environment {
    variables = {
      ENV_VAR     = "env_var" 
    }
  }
  tags = local.tags
}

# -------------------------------------------------------------------
# CloudWatch Rules
# -------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "start-schedule-rule" {
  name                = "${local.tags.appname}-start-schedule"
  schedule_expression = var.start_schedule
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "start-schedule-target" {
  arn  = aws_lambda_function.this.arn
  rule = aws_cloudwatch_event_rule.start-schedule-rule.name
  input = jsonencode({
    scheduler = {
      action = "start"
      resources = {
          asg = var.schedule_asg
          rds = var.schedule_rds
          ec2 = var.schedule_ec2
      }
      tags = var.schedule_tags
    }
  })
}

resource "aws_lambda_permission" "start-schedule-permission" {
  statement_id  = "cloudwatch-start-schedule-rule-allowed"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  function_name = aws_lambda_function.this.function_name
  source_arn    = aws_cloudwatch_event_rule.start-schedule-rule.arn
}

resource "aws_cloudwatch_event_rule" "stop-schedule-rule" {
  name                = "${local.tags.appname}-stop-schedule"
  schedule_expression = var.stop_schedule
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "stop-schedule-target" {
  arn  = aws_lambda_function.this.arn
  rule = aws_cloudwatch_event_rule.stop-schedule-rule.name
  input = jsonencode({
    scheduler = {
      action = "stop"
      resources = {
          asg = var.schedule_asg
          rds = var.schedule_rds
          ec2 = var.schedule_ec2
      }
      tags = var.schedule_tags
    }
  })
}

resource "aws_lambda_permission" "stop-schedule-permission" {
  statement_id  = "cloudwatch-stop-schedule-rule-allowed"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  function_name = aws_lambda_function.this.function_name
  source_arn    = aws_cloudwatch_event_rule.stop-schedule-rule.arn
}

# -------------------------------------------------------------------
# CloudWatch logs 
# -------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.tags.appname}"
  retention_in_days = 7 
  tags              = local.tags
}
