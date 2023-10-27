variable "availability_zone" {
  type = string
  default = "ru-central1-a"
  validation {
    condition = contains(["ru-central1-a", "ru-central1-b"], var.availability_zone)
    error_message = "Unsupported availability zone"
  }
}

variable "folder_id" {
  type = string
  default = "b1gnpc2soi6i8a0er087"
}