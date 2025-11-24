# ========================================
# Aurora Cluster
# ========================================
resource "aws_rds_cluster" "aurora" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = "${var.name}-cluster"
  engine             = var.engine_cluster
  engine_version     = var.engine_version_cluster
  database_name      = var.db_name
  master_username    = var.username
  master_password    = var.password

  db_subnet_group_name            = aws_db_subnet_group.default.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora[0].name

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-cluster-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  deletion_protection = false
  storage_encrypted   = true

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-cluster"
      Type = "Aurora"
    }
  )
}

# ========================================
# Aurora Writer Instance
# ========================================
resource "aws_rds_cluster_instance" "aurora_writer" {
  count = var.use_aurora ? 1 : 0

  identifier         = "${var.name}-writer"
  cluster_identifier = aws_rds_cluster.aurora[0].id
  instance_class     = var.instance_class
  engine             = var.engine_cluster
  engine_version     = var.engine_version_cluster

  db_subnet_group_name = aws_db_subnet_group.default.name
  publicly_accessible  = var.publicly_accessible

  performance_insights_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-writer"
      Role = "Writer"
    }
  )
}

# ========================================
# Aurora Reader Replicas
# ========================================
resource "aws_rds_cluster_instance" "aurora_readers" {
  count = var.use_aurora ? var.aurora_replica_count : 0

  identifier         = "${var.name}-reader-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora[0].id
  instance_class     = var.instance_class
  engine             = var.engine_cluster
  engine_version     = var.engine_version_cluster

  db_subnet_group_name = aws_db_subnet_group.default.name
  publicly_accessible  = var.publicly_accessible

  performance_insights_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-reader-${count.index + 1}"
      Role = "Reader"
    }
  )
}

# ========================================
# Aurora Cluster Parameter Group
# ========================================
resource "aws_rds_cluster_parameter_group" "aurora" {
  count = var.use_aurora ? 1 : 0

  name        = "${var.name}-aurora-params"
  family      = var.parameter_group_family_aurora
  description = "Cluster parameter group for ${var.name} Aurora cluster"

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
      Name = "${var.name}-aurora-params"
    }
  )
}
