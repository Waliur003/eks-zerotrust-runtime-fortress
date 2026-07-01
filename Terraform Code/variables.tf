variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "admin_ip" {
  type        = string
  description = "Physical IP address of the administrator with mask (e.g., 198.51.100.14/32)"
}

variable "cluster_name" {
  type    = string
  default = "zero-trust-cluster"
}

variable "vpc_name" {
  type    = string
  default = "project5-fortress"
}

//Create public_subnet_1_cidr_block
variable "public_subnet_1_cidr_block" {
  type    = string
  default = "10.0.0.0/20"
}

//Create public_subnet_2_cidr_block
variable "public_subnet_2_cidr_block" {
  type    = string
  default = "10.0.16.0/20"
}

//Create private_subnet_1_cidr_block
variable "private_subnet_1_cidr_block" {
  type    = string
  default = "10.0.128.0/20"

}

//Create private_subnet_2_cidr_block
variable "private_subnet_2_cidr_block" {
  type    = string
  default = "10.0.144.0/20"
}