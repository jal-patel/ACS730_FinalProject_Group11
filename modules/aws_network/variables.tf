#TO DO = Define Environment Variable with type string
#TO DO = Define group_name Variable with type string
#TO DO = Define ami Variable with type string
#TO DO = Define instance_type Variable with type string
#TO DO = Define key_name Variable with type string

# Define variables
variable "environment" {
  default = "Development"
  type    = string
}
variable "group_name" {
  default = "Group11"
  type    = string
}
variable "ami" {
  default = "ami-06e46074ae430fba6"
  type    = string
}
variable "instance_type" {
  default = "t2.micro"
  type    = string
}
variable "key_name" {
  default = "access"
  type    = string
}
