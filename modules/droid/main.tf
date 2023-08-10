resource "null_resource" "droid" {
  triggers = {
    name = var.name
  }
}
