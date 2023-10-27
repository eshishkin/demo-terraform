terraform {
  required_providers {
    yandex = {
      source = "registry.terraform.io/yandex-cloud/yandex"
    }
  }
}

locals {
  users = {
    sa-statistics-handler = toset(["ymq.reader", "ydb.editor"]),
    sa-function-invoker = toset(["functions.functionInvoker"])
  }
}

resource "yandex_iam_service_account" "sa-statistics-handler" {
  name = "sa-statistic-handler"
}

resource "yandex_iam_service_account" "sa-function-invoker" {
  name = "sa-on-message-function-invoker"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-statistics-handler-binding" {
  for_each = local.users.sa-statistics-handler
  folder_id = var.folder_id
  role      = each.key
  member    = "serviceAccount:${yandex_iam_service_account.sa-statistics-handler.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "function-invoker-binding" {
  for_each = local.users.sa-function-invoker
  folder_id = var.folder_id
  role      = each.key
  member    = "serviceAccount:${yandex_iam_service_account.sa-function-invoker.id}"
}

data "archive_file" "function_archive" {
  type        = "zip"
  source_dir  = "${path.module}/handler"
  output_path = "${path.module}/handler.zip"
}

resource "yandex_function" "statistics-processor" {
  name               = "statistics-processor"
  description        = "A function that handles statistics for an image provided by Vision API"
  user_hash          = "v1.0.0"
  runtime            = "python311"
  entrypoint         = "handler.handle"
  memory             = "128"
  execution_timeout  = "120"
  service_account_id = yandex_iam_service_account.sa-statistics-handler.id

  environment = {
    YDB_ENDPOINT          = var.ydb_endpoint
  }

  content {
    zip_filename = data.archive_file.function_archive.output_path
  }
}

resource "yandex_function_trigger" "on_message_trigger" {
  name = "on-message-trigger"

  function {
    id                 = yandex_function.statistics-processor.id
    service_account_id = yandex_iam_service_account.sa-function-invoker.id
  }

  message_queue {
    batch_cutoff       = 0
    batch_size         = 1
    queue_id           = var.queue
    service_account_id = yandex_iam_service_account.sa-statistics-handler.id
  }
}