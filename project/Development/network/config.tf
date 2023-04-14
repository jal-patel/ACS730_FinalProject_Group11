#TO DO = Create terraform configuration for S3.

terraform {
  backend "s3" {
    bucket = "project-01-bucket"                    // Bucket where to SAVE Terraform State
    key    = "DevelopmentNetwork/terraform.tfstate" // Object name in the bucket to SAVE Terraform State
    region = "us-east-1"                            // Region where bucket is created
  }
}
