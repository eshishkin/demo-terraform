terraform {
  required_providers {
    yandex = {
      source = "registry.terraform.io/yandex-cloud/yandex"
    }
  }
}

resource "yandex_ydb_database_serverless" "database" {
  name      = "test-ydb-serverless"
  deletion_protection = false

  serverless_database {
    enable_throttling_rcu_limit = false
    storage_size_limit          = 1
  }
}

resource "yandex_ydb_table" "table" {
  path = "stats"
  connection_string = yandex_ydb_database_serverless.database.ydb_full_endpoint

  column {
    name = "object_id"
    type = "Utf8"
    not_null = true
  }
  column {
    name = "stats"
    type = "Utf8"
    not_null = true
  }

  primary_key = ["object_id"]

}

