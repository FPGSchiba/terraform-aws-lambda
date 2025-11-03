locals {
  elements           = split("/", trimsuffix(var.code_dir, "/"))
  is_go_build_lambda = var.runtime == "provided.al2" && var.handler == null
  is_linux           = data.uname.localhost.operating_system != "windows"

  abs_code_dir      = abspath(var.code_dir)
  build_output_dir  = abspath("./tf_generated/${var.name}")
  build_output_file = "${local.build_output_dir}/bootstrap"
  temp_bootstrap    = "bootstrap_${var.name}"
  build_tags        = join(" ", var.go_build_tags)

  # Construct ldflags string from map
  base_ldflags     = "-s -w"
  x_flags          = [for key, value in var.go_additional_ldflags : "-X ${key}=${value}"]
  custom_ldflags   = join(" ", local.x_flags)
  combined_ldflags = local.custom_ldflags != "" ? "${local.base_ldflags} ${local.custom_ldflags}" : local.base_ldflags

  # Build in module dir, then move to target location
  build_command = local.is_linux ? "cd \"${local.abs_code_dir}\" && go mod tidy && GOOS=linux GOARCH=amd64 CGO_ENABLED=0 GOFLAGS=-trimpath go build -mod=readonly -ldflags='${local.combined_ldflags}' -tags \"${local.build_tags}\" -o \"${local.temp_bootstrap}\" . && mkdir -p \"${local.build_output_dir}\" && mv \"${local.temp_bootstrap}\" \"${local.build_output_file}\"" : "cd \"${local.abs_code_dir}\"; $Env:GOOS=\"linux\"; $Env:GOARCH=\"amd64\"; go mod tidy; go build -ldflags='${local.combined_ldflags}' -tags \"${local.build_tags}\" -o \"${local.temp_bootstrap}\" .; New-Item -ItemType Directory -Force -Path \"${local.build_output_dir}\" | Out-Null; Move-Item -Force \"${local.temp_bootstrap}\" \"${local.build_output_file}\""
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
