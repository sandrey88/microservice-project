# ========================================
# RDS Outputs
# ========================================
output "rds_endpoint" {
  description = "Endpoint для підключення до RDS instance"
  value       = var.use_aurora ? null : try(aws_db_instance.standard[0].endpoint, null)
}

output "rds_address" {
  description = "Hostname RDS instance"
  value       = var.use_aurora ? null : try(aws_db_instance.standard[0].address, null)
}

output "rds_port" {
  description = "Port RDS instance"
  value       = var.use_aurora ? null : try(aws_db_instance.standard[0].port, null)
}

output "rds_id" {
  description = "ID RDS instance"
  value       = var.use_aurora ? null : try(aws_db_instance.standard[0].id, null)
}

output "rds_arn" {
  description = "ARN RDS instance"
  value       = var.use_aurora ? null : try(aws_db_instance.standard[0].arn, null)
}

# ========================================
# Aurora Outputs
# ========================================
output "aurora_cluster_endpoint" {
  description = "Writer endpoint для Aurora cluster"
  value       = var.use_aurora ? try(aws_rds_cluster.aurora[0].endpoint, null) : null
}

output "aurora_reader_endpoint" {
  description = "Reader endpoint для Aurora cluster"
  value       = var.use_aurora ? try(aws_rds_cluster.aurora[0].reader_endpoint, null) : null
}

output "aurora_cluster_id" {
  description = "ID Aurora cluster"
  value       = var.use_aurora ? try(aws_rds_cluster.aurora[0].id, null) : null
}

output "aurora_cluster_arn" {
  description = "ARN Aurora cluster"
  value       = var.use_aurora ? try(aws_rds_cluster.aurora[0].arn, null) : null
}

output "aurora_cluster_members" {
  description = "Список членів Aurora cluster"
  value       = var.use_aurora ? try(aws_rds_cluster.aurora[0].cluster_members, []) : []
}

# ========================================
# Common Outputs
# ========================================
output "db_name" {
  description = "Назва бази даних"
  value       = var.db_name
}

output "db_username" {
  description = "Master username"
  value       = var.username
  sensitive   = true
}

output "db_port" {
  description = "Database port"
  value       = var.use_aurora ? 5432 : try(aws_db_instance.standard[0].port, 5432)
}

output "security_group_id" {
  description = "ID security group для database"
  value       = aws_security_group.rds.id
}

output "subnet_group_name" {
  description = "Назва DB subnet group"
  value       = aws_db_subnet_group.default.name
}

output "db_type" {
  description = "Тип бази даних (RDS або Aurora)"
  value       = var.use_aurora ? "Aurora" : "RDS"
}

output "connection_string" {
  description = "Connection string для підключення до БД"
  value = var.use_aurora ? (
    "postgresql://${var.username}:${var.password}@${try(aws_rds_cluster.aurora[0].endpoint, "pending")}:5432/${var.db_name}"
    ) : (
    "postgresql://${var.username}:${var.password}@${try(aws_db_instance.standard[0].address, "pending")}:${try(aws_db_instance.standard[0].port, 5432)}/${var.db_name}"
  )
  sensitive = true
}
