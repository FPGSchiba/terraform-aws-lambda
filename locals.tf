locals {
  elements           = split("/", trimsuffix(var.code_dir, "/"))
  is_go_build_lambda = var.runtime == "provided.al2" && var.handler == null
  is_linux           = data.uname.localhost.operating_system != "windows"
  build_output_file  = "./tf_generated/${var.name}/bootstrap"
  build_input_file   = "${trimsuffix(var.code_dir, "/")}/${var.main_filename}"
  build_tags         = join(" ", var.go_build_tags)
  build_command      = local.is_linux ? "cd ${var.code_dir} && go mod tidy && GOOS=linux GOARCH=amd64 CGO_ENABLED=0 GOFLAGS=-trimpath go build -mod=readonly -ldflags='-s -w' -tags \"${local.build_tags}\" -o \"${abspath(local.build_output_file)}\" \"${abspath(local.build_input_file)}\"" : "$Env:GOOS=\"linux\"; $Env:GOARCH=\"amd64\"; cd \"${var.code_dir}\"; go mod tidy; go build \"${local.build_tags}\" -o \"${abspath(local.build_output_file)}\" \"${abspath(local.build_input_file)}\""
}

locals {
  output_file = "${join("/", slice(local.elements, 0, length(local.elements) - 1))}/${var.name}.zip"
}

locals {
  ipv4_rules_ingress = flatten([
    for sg in var.security_groups : [
      for rule in sg.rules : {
        security_group_name = sg.name
        from_port           = lookup(rule, "from_port", null)
        to_port             = lookup(rule, "to_port", null)
        ip_protocol         = rule.ip_protocol
        cidr_blocks         = rule.ipv4_cidr_blocks
      } if rule.type == "ingress"
    ]
  ])
  ipv6_rules_ingress = flatten([
    for sg in var.security_groups : [
      for rule in sg.rules : {
        security_group_name = sg.name
        from_port           = lookup(rule, "from_port", null)
        to_port             = lookup(rule, "to_port", null)
        ip_protocol         = rule.ip_protocol
        cidr_blocks         = rule.ipv6_cidr_blocks
      } if rule.type == "ingress"
    ]
  ])
  ipv4_rules_egress = flatten([
    for sg in var.security_groups : [
      for rule in sg.rules : {
        security_group_name = sg.name
        from_port           = lookup(rule, "from_port", null)
        to_port             = lookup(rule, "to_port", null)
        ip_protocol         = rule.ip_protocol
        cidr_blocks         = rule.ipv4_cidr_blocks
      } if rule.type == "egress"
    ]
  ])
  ipv6_rules_egress = flatten([
    for sg in var.security_groups : [
      for rule in sg.rules : {
        security_group_name = sg.name
        from_port           = lookup(rule, "from_port", null)
        to_port             = lookup(rule, "to_port", null)
        ip_protocol         = rule.ip_protocol
        cidr_blocks         = rule.ipv6_cidr_blocks
      } if rule.type == "egress"
    ]
  ])
}
