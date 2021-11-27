variable "name" {
  description = "Define name to tag all the resources with"
  type        = string
}

variable "start_schedule" {
  description = "Define cloudwatch event schedule to trigger start event"
  type        = string
  default     = "cron(0 8 ? * MON-FRI *)"
}

variable "stop_schedule" {
  description = "Define cloudwatch event schedule to trigger stop event"
  type        = string
  default     = "cron(0 18 ? * MON-FRI *)"
}

variable "schedule_ec2" {
  description = "Enable/Disable schedule for ec2"
  type        = any
  default     = false
}

variable "schedule_asg" {
  description = "Enable/Disable schedule for autoscaling groups"
  type        = any
  default     = false
}

variable "schedule_rds" {
  description = "Enable/Disable schedule for rds resources"
  type        = any
  default     = false
}

variable "schedule_tags" {
  description = "Custom tags on aws resources"
  type        = list(string)
  default     = null
}

variable "permissions_boundary" {
  description = "Lambda function permissions boundary"
  type        = string
  default     = null
}
