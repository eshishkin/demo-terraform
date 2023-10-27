terraform {
  required_providers {
    yandex = {
      source = "registry.terraform.io/yandex-cloud/yandex"
    }
  }
}

data "yandex_resourcemanager_folder" "folder" {
  folder_id = var.folder_id
}

locals {
  cloud_id = data.yandex_resourcemanager_folder.folder.cloud_id
}

resource "yandex_iam_service_account" "s3-editor-service-account" {
  name = "s3-editor-service-account"
}

resource "yandex_resourcemanager_folder_iam_member" "s3-editor-binding" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.s3-editor-service-account.id}"
}

resource "yandex_iam_service_account_static_access_key" "sa-editor-static-key" {
  service_account_id = yandex_iam_service_account.s3-editor-service-account.id
  description        = "Static access key for object storage"
}

resource "yandex_storage_bucket" "storage" {
  bucket = "${local.cloud_id}-${var.folder_id}-input-storage"

  access_key = yandex_iam_service_account_static_access_key.sa-editor-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-editor-static-key.secret_key
}