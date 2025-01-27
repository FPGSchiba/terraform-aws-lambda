data "uname" "localhost" {}

locals {
  elements           = split("/", trimsuffix(var.code_dir, "/"))
  is_go_build_lambda = var.runtime == "provided.al2" && var.handler == null
  is_linux           = data.uname.localhost.operating_system != "windows"
  build_output_file  = "./tf_generated/${var.name}/bootstrap"
  build_input_file   = "${trimsuffix(var.code_dir, "/")}/${var.main_filename}"
  build_command      = local.is_linux ? "cd ${var.code_dir} && go mod tidy && GOOS=linux GOARCH=amd64 CGO_ENABLED=0 GOFLAGS=-trimpath go build -mod=readonly -ldflags='-s -w' -o \"${abspath(local.build_output_file)}\" \"${abspath(local.build_input_file)}\"" : "$Env:GOOS=\"linux\"; $Env:GOARCH=\"amd64\"; cd \"${var.code_dir}\"; go mod tidy; go build -o \"${abspath(local.build_output_file)}\" \"${abspath(local.build_input_file)}\""
}

locals {
  output_file = "${join("/", slice(local.elements, 0, length(local.elements) - 1))}/${var.name}.zip"
}
