output "processed_queue_url" {
  value = yandex_message_queue.processed_requests_queue.id
}

output "processed_queue_arn" {
  value = yandex_message_queue.processed_requests_queue.arn
}