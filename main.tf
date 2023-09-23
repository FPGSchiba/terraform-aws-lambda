resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.lambda.arn}:*"
    ]
  }

  dynamic "statement" {
    for_each = var.enable_tracing ? [{}] : []
    content {
      actions = [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords",
        "xray:GetSamplingRules",
        "xray:GetSamplingTargets",
        "xray:GetSamplingStatisticSummaries"
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = { for s in var.additional_iam_statements : sha1(jsonencode(s)) => s }
    content {
      actions   = statement.value["actions"]
      resources = statement.value["resources"]
    }
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "${var.name}-lambda-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

data "archive_file" "init" {
  type        = "zip"
  source_dir  = var.code_dir
  output_path = local.output_file
}
resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.init.output_path
  function_name    = var.name
  role             = aws_iam_role.lambda.arn
  handler          = var.handler
  runtime          = var.runtime
  source_code_hash = data.archive_file.init.output_base64sha256
  timeout          = var.timeout
  layers           = var.layer_arns

  dynamic "environment" {
    for_each = length(var.environment_variables) == 0 ? [] : [{}]
    content {
      variables = var.environment_variables
    }
  }

  dynamic "tracing_config" {
    for_each = var.enable_tracing ? [{}] : []
    content {
      mode = "Active"
    }
  }
}
