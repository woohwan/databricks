resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.project_name}-pg"
  engine         = "postgres"
  engine_version = var.engine_version

  instance_class    = var.db_instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_master_password
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.publicly_accessible

  multi_az                = false
  backup_retention_period = 1
  apply_immediately       = true
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Name = "${var.project_name}-pg"
  }
}
