variable "title" {
  type        = string
  description = "Simple variable example"
  default     = "Star Wars"
}


variable "droids" {
  type        = set(string)
  description = "Set of droids"
  default     = ["C3-PO", "R2-D2", /*"BB-8"*/]
}


variable "pilots" {
  type = list(object({
    name  = string
    email = string
    droid = optional(string, null)
  }))

  description = "Complex variable example; may be much much more complex than that"

  validation {
    condition     = length(var.pilots) == length(toset([for p in var.pilots : p.email]))
    error_message = "Pilot email address must be unique."
  }

  default = [
    {
      email = "han.solo@starwars.com"
      name  = "Han Solo"
    },
    {
      email = "lea.organa@starwars.com"
      name  = "Lea Organa"
      droid = "C3-PO"
    },
    {
      email = "luke.skywalker@starwars.com"
      name  = "Luke Skywalker"
      droid = "R2-D2"
    },
    # {
    #   email = "rey@starwars.com"
    #   name  = "Rey"
    #   droid = "BB-8"
    # },
  ]
}


locals {
  pilots = {
    for user in var.pilots : user.name => user
  }
}


data "local_file" "galaxy_map" {
  filename = "galaxy_map.jpg"
}


resource "null_resource" "spaceship" {
  for_each = local.pilots

  triggers = {
    email       = each.value.email
    description = "${var.title} character: ${each.key}"
    galaxy_map  = data.local_file.galaxy_map.content_sha1
    droid_id    = try(module.droid[each.value.droid].droid_id, null)
  }
}


module "droid" {
  source = "./modules/droid"

  for_each = var.droids

  name = each.key
}


output "spaceship_info" {
  description = "Spaceship information for each pilot"

  value = [
    for pilot in local.pilots : {
      ship_id             = resource.null_resource.spaceship[pilot.name].id
      name                = pilot.name
      galaxy_map_checksum = resource.null_resource.spaceship[pilot.name].triggers.galaxy_map
      droid = try({
        name = pilot.droid
        id   = module.droid[pilot.droid].droid_id
      }, null)
    }
  ]
}
