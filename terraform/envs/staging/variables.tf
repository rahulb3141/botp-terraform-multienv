variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "cidr_block" {
  type = string
  default = "10.1.0.0/16"
}
