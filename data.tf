data "uname" "localhost" {}

data "aws_vpc" "this" {
  count = var.vpc_id == null ? 0 : 1

  id = var.vpc_id
}

data "aws_subnets" "this" {
  count = var.vpc_id == null ? 0 : 1

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}
