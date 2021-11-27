variable "ec2_dev_count" {
  description = "Number of ec2 instances to provision for dev envir"
  type        = number
  default     = 1
}

variable "asg_dev_count" {
  description = "Number of autoscaling groups to provision for dev envir"
  type        = number
  default     = 1
}

variable "cap_dev_count" {
  description = "Autoscaling group capacity in dev envir"
  type        = number
  default     = 1
}

variable "rds_dev_count" {
  description = "Number of rds instances to provision for dev envir"
  type        = number
  default     = 1
}

variable "ec2_tst_count" {
  description = "Number of ec2 instances to provision for tst envir"
  type        = number
  default     = 1
}

variable "asg_tst_count" {
  description = "Number of autoscaling groups to provision for tst envir"
  type        = number
  default     = 1
}

variable "cap_tst_count" {
  description = "Autoscaling group capacity in tst envir"
  type        = number
  default     = 1
}
variable "rds_tst_count" {
  description = "Number of rds instances to provision for tst envir"
  type        = number
  default     = 1
}

variable "ec2_prd_count" {
  description = "Number of ec2 instances to provision for prod envir"
  type        = number
  default     = 1
}

variable "asg_prd_count" {
  description = "Number of autoscaling groups to provision for prod envir"
  type        = number
  default     = 1
}

variable "cap_prd_count" {
  description = "Autoscaling group capacity in prd envir"
  type        = number
  default     = 1
}

variable "rds_prd_count" {
  description = "Number of rds instances to provision for prod envir"
  type        = number
  default     = 1
}

variable "vpc_cidr_block" {
  description   = "CIDR block for VPC"
  type          = string
  default       = "10.0.0.0/16"
}

variable "vpc_subnet_primary_block" {
  description   = "CIDR block for VPC subnet"
  type          = string
  default       = "10.0.12.0/24"
}

variable "vpc_subnet_secondary_block" {
  description   = "CIDR block for VPC subnet"
  type          = string
  default       = "10.0.14.0/24"
}
