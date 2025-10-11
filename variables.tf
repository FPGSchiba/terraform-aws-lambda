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
    rules = list(object({
      type             = string
      from_port        = optional(number)
      to_port          = optional(number)
      ip_protocol      = string
      ipv4_cidr_blocks = list(string)
      ipv6_cidr_blocks = list(string)
    }))
  }))
  validation {
    condition = alltrue([
      for sg in var.security_groups : alltrue([
        alltrue([for rule in sg.rules : contains(["egress", "ingress"], rule.type)])
      ])
    ])
    error_message = "Each rule.type must be either 'egress' or 'ingress'."
  }
  default = []
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

variable "vpc_networked" {
  description = "Whether to deploy the lambda function in a VPC"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "The ID of the VPC where the lambda function will be deployed"
  type        = string
  default     = null
}

variable "go_build_tags" {
  description = "Build tags for go build command"
  type        = list(string)
  default     = []
}
