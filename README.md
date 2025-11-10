# terraform-aws-lambda

A module to easy build and deploy GoLang and Python Lambda functions.

## Usage

### Python

```hcl
module "lambda" {
  source = "github.com/elastic-infra/terraform-aws-lambda"

  name = "my-lambda"
  code_dir = "${path.module}/lambda" # Directory with the python code
  runtime = "python3.8"
  handler = "lambda.handler"
  environment_variables = {
    "ENV_VAR" = "value"
  }
}
```

### Go

It detects go automatically, when `handler == null` (default) and `runtime == "provided.al2"`. 

```hcl
module "lambda" {
  source = "github.com/elastic-infra/terraform-aws-lambda"

  code_dir       = "${path.module}/src/" # Directory with the go code
  name           = "${var.random_prefix}-test-lambda"
  enable_tracing = true
  runtime        = "provided.al2"
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
```

### With VPC

To enable VPC support, provide `vpc_id` parameter.
It always gives the lambda access to all subnets in the VPC.
IPv6 Dual stack is always enabled on the lambda.
The `type` field in the security group rules can be either `ipv4` or `ipv6`.

```hcl
module "lambda" {
  source = "github.com/elastic-infra/terraform-aws-lambda"

  name    = "my-lambda"
  code_dir = "${path.module}/lambda" # Directory with the python code
  runtime = "python3.8"
  handler = "lambda.handler"
  vpc_id = aws_vpc.main.id
  security_groups = [
    {
      name        = "allow-http"
      description = "Allow HTTP inbound traffic"
      ingress_rules = [
        {
          type        = "ipv4"
          from_port   = 80
          to_port     = 80
          ip_protocol = "tcp"
          cidr_block  = "0.0.0.0/0"
        }
      ]
      egress_rules = [
        {
          type        = "ipv4"
          from_port   = 0
          to_port     = 0
          ip_protocol = "-1"
          cidr_block  = "0.0.0.0/0"
        }
      ]
    }
  ]
  environment_variables = {
    "ENV_VAR" = "value"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5 |
| <a name="requirement_uname"></a> [uname](#requirement\_uname) | 0.2.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.2 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
| <a name="provider_uname"></a> [uname](#provider\_uname) | 0.2.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.this_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.this_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.this_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.this_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [terraform_data.build](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [archive_file.build](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.non_build](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_iam_policy_document.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [uname_uname.localhost](https://registry.terraform.io/providers/julienlevasseur/uname/0.2.3/docs/data-sources/uname) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_iam_statements"></a> [additional\_iam\_statements](#input\_additional\_iam\_statements) | Additional permissions added to the lambda function | <pre>list(object({<br/>    actions   = list(string)<br/>    resources = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_app_log_level"></a> [app\_log\_level](#input\_app\_log\_level) | Log level for the application logs | `string` | `"INFO"` | no |
| <a name="input_code_dir"></a> [code\_dir](#input\_code\_dir) | Path to the code directory | `string` | n/a | yes |
| <a name="input_enable_tracing"></a> [enable\_tracing](#input\_enable\_tracing) | Enable active tracing | `bool` | `false` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variables used by the function | `map(string)` | `{}` | no |
| <a name="input_go_additional_ldflags"></a> [go\_additional\_ldflags](#input\_go\_additional\_ldflags) | Additional -X ldflags for go build command as key-value pairs (e.g., {"github.com/fpgschiba/volleygoals/router.SelectedHandler" = "GetTeam"}) | `map(string)` | `{}` | no |
| <a name="input_go_build_tags"></a> [go\_build\_tags](#input\_go\_build\_tags) | Build tags for go build command | `list(string)` | `[]` | no |
| <a name="input_handler"></a> [handler](#input\_handler) | Lambda handler | `string` | `null` | no |
| <a name="input_json_logging"></a> [json\_logging](#input\_json\_logging) | Enable structured JSON logging | `bool` | `false` | no |
| <a name="input_layer_arns"></a> [layer\_arns](#input\_layer\_arns) | Layers attached to the lambda function | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the lambda function | `string` | n/a | yes |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Lambda runtime | `string` | `"provided.al2"` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | List of security group rules to apply | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    rules = list(object({<br/>      type             = string<br/>      from_port        = optional(number)<br/>      to_port          = optional(number)<br/>      ip_protocol      = string<br/>      ipv4_cidr_blocks = list(string)<br/>      ipv6_cidr_blocks = list(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The IDs of the subnets where the lambda function will be deployed | `list(string)` | `[]` | no |
| <a name="input_system_log_level"></a> [system\_log\_level](#input\_system\_log\_level) | Log level for the system logs | `string` | `"WARN"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resources | `map(string)` | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Number of seconds, unitl the lmabda timeouts | `number` | `3` | no |
| <a name="input_vpc_dualstack"></a> [vpc\_dualstack](#input\_vpc\_dualstack) | Whether to deploy the lambda function in a dualstack VPC (IPv4 and IPv6). Only used if vpc\_networked is true. | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC where the lambda function will be deployed | `string` | `null` | no |
| <a name="input_vpc_networked"></a> [vpc\_networked](#input\_vpc\_networked) | Whether to deploy the lambda function in a VPC | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_function_arn"></a> [function\_arn](#output\_function\_arn) | Arn of the created lambda function |
| <a name="output_function_invoke_arn"></a> [function\_invoke\_arn](#output\_function\_invoke\_arn) | Invoke Arn used by the API gateway |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | Name of the created lambda function |
| <a name="output_function_role_arn"></a> [function\_role\_arn](#output\_function\_role\_arn) | Arn of the created lambda function role |
| <a name="output_function_role_id"></a> [function\_role\_id](#output\_function\_role\_id) | Id of the created lambda function role |
<!-- END_TF_DOCS -->
