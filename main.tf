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

resource "null_resource" "build" {
  count = local.is_go_build_lambda ? 1 : 0

  triggers = {
    dir_sha1    = sha1(join("", [for f in fileset(var.code_dir, "*") : filesha1("${var.code_dir}/${f}")]))
    file_exists = fileexists(local.build_input_file)
  }

  provisioner "local-exec" {
    command     = local.build_command
    interpreter = local.is_linux ? ["bash", "-c"] : ["PowerShell", "-Command"]
  }
}

data "archive_file" "non_build" {
  count = local.is_go_build_lambda ? 0 : 1

  type        = "zip"
  source_dir  = var.code_dir
  output_path = local.output_file
}

data "archive_file" "build" {
  count = local.is_go_build_lambda ? 1 : 0

  type        = "zip"
  source_file = local.build_output_file
  output_path = local.output_file

  depends_on = [
    null_resource.build
  ]
}

resource "aws_lambda_function" "lambda" {
  filename         = local.is_go_build_lambda ? data.archive_file.build[0].output_path : data.archive_file.non_build[0].output_path
  function_name    = var.name
  role             = aws_iam_role.lambda.arn
  handler          = local.is_go_build_lambda ? "bootstrap" : var.handler
  runtime          = var.runtime
  source_code_hash = local.is_go_build_lambda ? data.archive_file.build[0].output_base64sha256 : data.archive_file.non_build[0].output_base64sha256
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
