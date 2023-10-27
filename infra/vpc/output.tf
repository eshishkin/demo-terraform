output "subnet_id" {
  value = yandex_vpc_subnet.subnet.id
}

output "network_id" {
  value = yandex_vpc_network.vpc.id
}