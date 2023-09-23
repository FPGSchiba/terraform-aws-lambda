output "function_arn" {
  value       = aws_lambda_function.lambda.arn
  description = "Arn of the created lambda function"
}

output "function_name" {
  value       = aws_lambda_function.lambda.function_name
  description = "Name of the created lambda function"
}

output "function_role_id" {
  value       = aws_iam_role.lambda.id
  description = "Id of the created lambda function role"
}

output "function_role_arn" {
  value       = aws_iam_role.lambda.arn
  description = "Arn of the created lambda function role"
}

output "function_invoke_arn" {
  value       = aws_lambda_function.lambda.invoke_arn
  description = "Invoke Arn used by the API gateway"
}
