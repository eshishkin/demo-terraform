terraform {
  required_providers {
    yandex = {
      source = "registry.terraform.io/yandex-cloud/yandex"
    }
  }
}

resource "yandex_vpc_network" "vpc" {
  name = "terraform-network"
}

resource "yandex_vpc_subnet" "subnet" {
  zone           = var.availability_zone
  network_id     = yandex_vpc_network.vpc.id
  v4_cidr_blocks = ["192.168.0.0/16"]
}
