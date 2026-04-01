variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "cidr_block" {
  type    = string
  default = "10.40.0.0/16"
}
