data "uname" "localhost" {}

data "aws_vpc" "this" {
  count = var.vpc_networked ? 1 : 0

  id = var.vpc_id
}
