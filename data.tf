data "uname" "localhost" {}

data "aws_vpc" "this" {
  count = var.vpc_networked ? 1 : 0

  id = var.vpc_id
}

data "aws_subnets" "this" {
  count = var.vpc_networked ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}
