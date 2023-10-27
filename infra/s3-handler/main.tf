terraform {
  required_providers {
    yandex = {
      source = "registry.terraform.io/yandex-cloud/yandex"
    }
  }
}

locals {
  users = {
    sa-bucket-new-object-handler = toset(["storage.viewer", "ymq.writer", "ai.vision.user"]),
    sa-function-invoker          = toset(["functions.functionInvoker"])
  }
}

data "archive_file" "function_archive" {
  type        = "zip"
  source_dir  = "${path.module}/handler"
  output_path = "${path.module}/handler.zip"
}

resource "yandex_iam_service_account" "sa-bucket-new-object-handler" {
  name = "sa-bucket-object-handler"
}

resource "yandex_iam_service_account" "sa-function-invoker" {
  name = "sa-on-bucket-change-function-invoker"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-bucket-new-object-handler-binding" {
  for_each  = local.users.sa-bucket-new-object-handler
  folder_id = var.folder_id
  role      = each.key
  member    = "serviceAccount:${yandex_iam_service_account.sa-bucket-new-object-handler.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "function-invoker-binding" {
  for_each  = local.users.sa-function-invoker
  folder_id = var.folder_id
  role      = each.key
  member    = "serviceAccount:${yandex_iam_service_account.sa-function-invoker.id}"
}

resource "yandex_iam_service_account_static_access_key" "sa-bucket-new-object-handler-aws-static-key" {
  service_account_id = yandex_iam_service_account.sa-bucket-new-object-handler.id
  description        = "AWS compatible static access key for object handler"
}

resource "yandex_function" "new-object-processor" {
  name               = "new-object-processor"
  description        = "A function that handles new object creation in a bucket"
  user_hash          = "v1.0.0"
  runtime            = "python311"
  entrypoint         = "handler.handle"
  memory             = "128"
  execution_timeout  = "120"
  service_account_id = yandex_iam_service_account.sa-bucket-new-object-handler.id

  environment = {
    S3_ENDPOINT           = "https://storage.yandexcloud.net"
    YC_QUEUE_ENDPOINT     = "https://message-queue.api.cloud.yandex.net/"
    YC_QUEUE_URL          = var.queue
    AWS_ACCESS_KEY_ID     = yandex_iam_service_account_static_access_key.sa-bucket-new-object-handler-aws-static-key.access_key
    AWS_SECRET_ACCESS_KEY = yandex_iam_service_account_static_access_key.sa-bucket-new-object-handler-aws-static-key.secret_key
    AWS_DEFAULT_REGION    = "ru-central1"
    FOLDER_ID             = var.folder_id
  }

  content {
    zip_filename = data.archive_file.function_archive.output_path
  }
}

resource "yandex_function_trigger" "on_object_create_trigger" {
  name = "on-bucket-object-create-trigger"

  function {
    id                 = yandex_function.new-object-processor.id
    service_account_id = yandex_iam_service_account.sa-function-invoker.id
  }

  object_storage {
    bucket_id    = var.bucket
    create       = true
    batch_size   = 1
    batch_cutoff = 0
  }
}