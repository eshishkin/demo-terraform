terraform {
  required_providers {
    yandex = {
      source = "registry.terraform.io/yandex-cloud/yandex"
    }
  }
}


resource "yandex_iam_service_account" "sa-queue-admin" {
  name = "sa-queue-admin"
}

resource "yandex_resourcemanager_folder_iam_member" "queue-admin-binding" {
  folder_id = var.folder_id
  role      = "ymq.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa-queue-admin.id}"
}

resource "yandex_iam_service_account_static_access_key" "sa-queue-admin-static-key" {
  service_account_id = yandex_iam_service_account.sa-queue-admin.id
  description        = "Static access key for object storage"
}

resource "yandex_message_queue" "processed_requests_queue" {
  name                        = "processed"
  visibility_timeout_seconds  = 600
  receive_wait_time_seconds   = 5

  access_key = yandex_iam_service_account_static_access_key.sa-queue-admin-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-queue-admin-static-key.secret_key
}