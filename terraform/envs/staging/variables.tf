variable "region" {
  type    = string
  default = "us-east-1"
}

variable "env" {
  type    = string
  default = "staging"
}

variable "cidr_block" {
  type    = string
  default = "10.30.0.0/16"
}
