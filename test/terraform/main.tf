provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      "test" = "true"
      "module" = "terraform-aws-lambda"
    }
  }
}

variable "random_prefix" {
  description = "Random prefix for the lambda function"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "provided.al2"
}

resource "aws_s3_bucket" "test" {
  bucket = "${lower(var.random_prefix)}-test-bucket"
  force_destroy = true
}

module "lambda" {
  source         = "../../"
  code_dir       = "${path.module}/src/"
  name           = "${var.random_prefix}-test-lambda"
  enable_tracing = true
  runtime        = var.runtime
  additional_iam_statements = [
    {
      actions   = ["s3:PutObject"]
      resources = [aws_s3_bucket.test.arn, "${aws_s3_bucket.test.arn}/*"]
    }
  ]
  environment_variables = {
    "RECEIPT_BUCKET" = aws_s3_bucket.test.bucket
  }
}

resource "aws_lambda_invocation" "test" {
  function_name = module.lambda.function_name
  input         = ""

  depends_on = [
    module.lambda
  ]
}

output "lambda_arn" {
  value = module.lambda.function_arn
}

output "lambda_result" {
  value = aws_lambda_invocation.test.result
}