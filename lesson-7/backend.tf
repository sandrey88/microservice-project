terraform {
  backend "s3" {
    bucket         = "terraform-state-andrii-lesson7"
    key            = "lesson-7/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-locks-lesson7"
    encrypt        = true
  }
}
