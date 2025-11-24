# ========================================
# Standard RDS Instance
# ========================================
resource "aws_db_instance" "standard" {
  count = var.use_aurora ? 0 : 1

  identifier        = var.name
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.username
  password = var.password

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.standard[0].name

  multi_az            = var.multi_az
  publicly_accessible = var.publicly_accessible

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  deletion_protection = false

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(
    var.tags,
    {
      Name = var.name
      Type = "RDS"
    }
  )
}

# ========================================
# Standard RDS Parameter Group
# ========================================
resource "aws_db_parameter_group" "standard" {
  count = var.use_aurora ? 0 : 1

  name        = "${var.name}-rds-params"
  family      = var.parameter_group_family_rds
  description = "Parameter group for ${var.name} RDS instance"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-rds-params"
    }
  )
}
