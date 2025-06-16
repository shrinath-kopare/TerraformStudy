# resource "null_resource" "debug_path_module" {
#   provisioner "local-exec" {
#     command = "echo path.module is: ${path.module}"
#   }
# }
resource "null_resource" "debug_path_module" {
  provisioner "local-exec" {
    command = "echo Absolute path is: ${abspath(path.module)}"
  }
}