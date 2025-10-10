resource "aws_security_group" "this" {
  for_each = { for sg in var.security_groups : sg.name => sg }

  name_prefix = "${each.key}-"
  description = each.value.description
  vpc_id      = data.aws_vpc.this.id

  tags = merge(
    {
      Name = each.key
    },
    var.tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "this_ipv4" {
  for_each = { for rule in local.ipv4_rules_ingress : "${rule.security_group_name}-${rule.ip_protocol}-${replace(rule.cidr_block, "/", "-")}" => rule }

  security_group_id = aws_security_group.this[each.value.security_group_name].id
  cidr_ipv4         = each.value.cidr_block
  from_port         = each.value.from_port
  ip_protocol       = each.value.ip_protocol
  to_port           = each.value.to_port
}

resource "aws_vpc_security_group_ingress_rule" "this_ipv6" {
  for_each = { for rule in local.ipv6_rules_ingress : "${rule.security_group_name}-${rule.ip_protocol}-${replace(rule.cidr_block, "/", "-")}" => rule }

  security_group_id = aws_security_group.this[each.value.security_group_name].id
  cidr_ipv6         = each.value.cidr_block
  from_port         = each.value.from_port
  ip_protocol       = each.value.ip_protocol
  to_port           = each.value.to_port
}

resource "aws_vpc_security_group_egress_rule" "this_ipv4" {
  for_each = { for rule in local.ipv4_rules_egress : "${rule.security_group_name}-${rule.ip_protocol}-${replace(rule.cidr_block, "/", "-")}" => rule }

  security_group_id = aws_security_group.this[each.value.security_group_name].id
  cidr_ipv4         = each.value.cidr_block
  from_port         = each.value.from_port
  ip_protocol       = each.value.ip_protocol
  to_port           = each.value.to_port
}

resource "aws_vpc_security_group_egress_rule" "this_ipv6" {
  for_each = { for rule in local.ipv6_rules_egress : "${rule.security_group_name}-${rule.ip_protocol}-${replace(rule.cidr_block, "/", "-")}" => rule }

  security_group_id = aws_security_group.this[each.value.security_group_name].id
  cidr_ipv6         = each.value.cidr_block
  from_port         = each.value.from_port
  ip_protocol       = each.value.ip_protocol
  to_port           = each.value.to_port
}

