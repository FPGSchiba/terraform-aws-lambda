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
  default     = "provided.al2"
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

variable "security_groups" {
  description = "List of security group rules to apply"
  type = list(object({
    name        = string
    description = string
    ingress_rules = list(object({
      type        = string
      from_port   = optional(number)
      to_port     = optional(number)
      ip_protocol = string
      cidr_block  = string
    }))
    egress_rules = list(object({
      type        = string
      from_port   = optional(number)
      to_port     = optional(number)
      ip_protocol = string
      cidr_block  = string
    }))
  }))
  validation {
    condition = alltrue([
      for sg in var.security_groups : alltrue([
        alltrue([for rule in sg.ingress_rules : contains(["ipv4", "ipv6"], rule.type)]),
        alltrue([for rule in sg.egress_rules : contains(["ipv4", "ipv6"], rule.type)])
      ])
    ])
    error_message = "Each rule.type must be either 'ipv4' or 'ipv6'."
  }
  default = []
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "List of subnet IDs to place the lambda function in"
  type        = list(string)
  default     = []
}
