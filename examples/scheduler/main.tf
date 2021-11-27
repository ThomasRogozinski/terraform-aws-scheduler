provider "aws" {
  region = local.region
}

locals {
  region = "ap-southeast-2"
}

# example scheduler which shuts down resources 6PM AEST
# and starts them up at 8AM AEST on weekdays
module "my-scheduler" {
  source          = "../../"
  name            = "my-scheduler"
  start_schedule  = "cron(0 9 ? * MON-FRI *)"
  stop_schedule   = "cron(0 17 ? * MON-FRI *)" 
  schedule_ec2    = true
  schedule_asg    = true
  schedule_rds    = true
  schedule_tags   = [ "scheduled-dev", "scheduled-tst"  ]
}

/*
# example scheduler shutting down and starting up 
# aws resources every 10 minutes
module "test-scheduler" {
  source          = "../../"
  name            = "test-scheduler"
  start_schedule  = "cron(0,10,20,30,40,50 * ? * * *)"
  stop_schedule   = "cron(5,15,25,35,45,55 * ? * * *)"
  schedule_ec2    = true
  schedule_asg    = true
  schedule_rds    = true
  schedule_tags   = [ "scheduled-dev", "scheduled-tst" ]
}
*/