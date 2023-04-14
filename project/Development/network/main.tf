# Module to deploy basic networking 

module "DevelopmentVPC" {
  source = "../../../modules/aws_network"
  #source       = "git@github.com:igeiman/aws_network.git"
  environment   = var.environment
  group_name    = var.group_name
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
}
