# Цей блок має бути закоментований при першому запуску
# Після створення S3 та DynamoDB - розкоментуйте та виконайте terraform init -reconfigure

#terraform {
#  backend "s3" {
#    bucket         = "terraform-state-andrii-project"
#    key            = "project/terraform.tfstate"
#    region         = "eu-north-1"
#    dynamodb_table = "terraform-locks-project"
#    encrypt        = true
#  }
#}
