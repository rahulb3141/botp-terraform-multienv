variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "cidr_block" {
  type    = string
  default = "10.20.0.0/16"
}
