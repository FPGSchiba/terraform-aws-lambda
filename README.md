# terraform-aws-lambda

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.2 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

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
| [terraform_data.build](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [archive_file.build](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.non_build](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_iam_policy_document.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_iam_statements"></a> [additional\_iam\_statements](#input\_additional\_iam\_statements) | Additional permissions added to the lambda function | <pre>list(object({<br/>    actions   = list(string)<br/>    resources = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_code_dir"></a> [code\_dir](#input\_code\_dir) | Path to the code directory | `string` | n/a | yes |
| <a name="input_enable_tracing"></a> [enable\_tracing](#input\_enable\_tracing) | Enable active tracing | `bool` | `false` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variables used by the function | `map(string)` | `{}` | no |
| <a name="input_handler"></a> [handler](#input\_handler) | Lambda handler | `string` | `null` | no |
| <a name="input_layer_arns"></a> [layer\_arns](#input\_layer\_arns) | Layers attached to the lambda function | `list(string)` | `[]` | no |
| <a name="input_main_filename"></a> [main\_filename](#input\_main\_filename) | Main filename of the lambda function (only needed for go Lambda functions) | `string` | `"main.go"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the lambda function | `string` | n/a | yes |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Lambda runtime | `string` | `"python3.8"` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Number of seconds, unitl the lmabda timeouts | `number` | `3` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_function_arn"></a> [function\_arn](#output\_function\_arn) | Arn of the created lambda function |
| <a name="output_function_invoke_arn"></a> [function\_invoke\_arn](#output\_function\_invoke\_arn) | Invoke Arn used by the API gateway |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | Name of the created lambda function |
| <a name="output_function_role_arn"></a> [function\_role\_arn](#output\_function\_role\_arn) | Arn of the created lambda function role |
| <a name="output_function_role_id"></a> [function\_role\_id](#output\_function\_role\_id) | Id of the created lambda function role |
<!-- END_TF_DOCS -->
