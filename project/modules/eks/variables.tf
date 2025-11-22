variable "cluster_name" {
  description = "Назва EKS кластера"
  type        = string
}

variable "subnet_ids" {
  description = "Список ID підмереж для EKS"
  type        = list(string)
}

variable "instance_type" {
  description = "Тип інстансу для worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "desired_size" {
  description = "Бажана кількість worker nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Максимальна кількість worker nodes"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Мінімальна кількість worker nodes"
  type        = number
  default     = 1
}
