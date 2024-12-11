variable "name" {
  type        = string
  description = "Name of the lambda function"
}

variable "code_dir" {
  type        = string
  description = "Path to the code directory"
}

variable "handler" {
  type        = string
  default     = null
  description = "Lambda handler"
}

variable "main_filename" {
  type        = string
  description = "Main filename of the lambda function (only needed for go Lambda functions)"
  default     = "main.go"
}

variable "runtime" {
  type        = string
  default     = "python3.8"
  description = "Lambda runtime"
}

variable "additional_iam_statements" {
  type = list(object({
    actions   = list(string)
    resources = list(string)
  }))
  default     = []
  description = "Additional permissions added to the lambda function"
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Environment variables used by the function"
}

variable "timeout" {
  type        = number
  default     = 3
  description = "Number of seconds, unitl the lmabda timeouts"
}

variable "layer_arns" {
  type        = list(string)
  default     = []
  description = "Layers attached to the lambda function"
}

variable "enable_tracing" {
  type        = bool
  default     = false
  description = "Enable active tracing"
}
