terraform {
  required_providers {
    yandex = {
      source = "registry.terraform.io/yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.99"
}

provider "yandex" {
  zone                     = var.availability_zone
  folder_id                = var.folder_id
  service_account_key_file = "authorized_key.json"
}

module "vpc" {
  source = "./vpc"
}

resource "yandex_logging_group" "group1" {
  name      = "default"
  folder_id = var.folder_id
}

module "queue" {
  source = "./queue"

  folder_id = var.folder_id
}

module "s3_storage" {
  source = "./s3"

  folder_id = var.folder_id
}

module "s3_handler" {
  source = "./s3-handler"

  folder_id = var.folder_id
  bucket    = module.s3_storage.bucket_id
  queue     = module.queue.processed_queue_url
}

module "ydb_storage" {
  source = "./ydb"

  folder_id = var.folder_id
}

module "stats_handler" {
  source = "./stats-handler"

  folder_id    = var.folder_id
  ydb_endpoint = module.ydb_storage.ydb_endpoint
  queue        = module.queue.processed_queue_arn
}