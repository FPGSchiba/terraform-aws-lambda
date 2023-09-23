locals {
  elements = split("/", trimsuffix(var.code_dir, "/"))
}

locals {
  output_file = "${join("/", slice(local.elements, 0, length(local.elements) - 1))}/${var.name}.zip"
}

