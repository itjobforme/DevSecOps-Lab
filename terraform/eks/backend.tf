terraform {
  backend "s3" {
    bucket         = "devsecops-blog-0a1a509edae085e7"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}
