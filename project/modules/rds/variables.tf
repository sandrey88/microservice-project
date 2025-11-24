variable "name" {
  description = "Назва інстансу або кластера RDS"
  type        = string
}

variable "use_aurora" {
  description = "Використовувати Aurora замість звичайної RDS (true/false)"
  type        = bool
  default     = false
}

# ========================================
# RDS-specific variables
# ========================================
variable "engine" {
  description = "Database engine для RDS (postgres, mysql)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Версія database engine для RDS"
  type        = string
  default     = "16.4"
}

variable "parameter_group_family_rds" {
  description = "Parameter group family для RDS (postgres16, mysql8.0)"
  type        = string
  default     = "postgres16"
}

# ========================================
# Aurora-specific variables
# ========================================
variable "engine_cluster" {
  description = "Database engine для Aurora (aurora-postgresql, aurora-mysql)"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version_cluster" {
  description = "Versія database engine для Aurora"
  type        = string
  default     = "15.3"
}

variable "parameter_group_family_aurora" {
  description = "Parameter group family для Aurora (aurora-postgresql15, aurora-mysql8.0)"
  type        = string
  default     = "aurora-postgresql15"
}

variable "aurora_instance_count" {
  description = "Кількість інстансів в Aurora кластері (включаючи writer)"
  type        = number
  default     = 2
}

variable "aurora_replica_count" {
  description = "Кількість reader реплік в Aurora кластері"
  type        = number
  default     = 1
}

# ========================================
# Common variables
# ========================================
variable "instance_class" {
  description = "Клас інстансу (db.t3.small, db.t3.medium, db.r5.large)"
  type        = string
  default     = "db.t3.small"
}

variable "allocated_storage" {
  description = "Розмір сховища в GB (тільки для RDS)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Назва бази даних"
  type        = string
}

variable "username" {
  description = "Master username для БД"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "Master password для БД"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "ID VPC для security group"
  type        = string
}

variable "subnet_private_ids" {
  description = "Список ID приватних підмереж"
  type        = list(string)
}

variable "subnet_public_ids" {
  description = "Список ID публічних підмереж"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Чи доступна БД публічно"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Чи використовувати Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Період зберігання backup в днях"
  type        = number
  default     = 7
}

variable "parameters" {
  description = "Map параметрів для parameter group"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags для ресурсів"
  type        = map(string)
  default     = {}
}

variable "skip_final_snapshot" {
  description = "Пропустити final snapshot при видаленні"
  type        = bool
  default     = false
}
