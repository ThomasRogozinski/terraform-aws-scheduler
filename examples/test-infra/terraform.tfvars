# set the variables describing number of resources of 
# certain type. To disable resource deployment set the number to 0
#
# dev - development environment
# tst - test environment
# prd - production tenvironment
#
# ec2 - standalone ec2
# asg - autoscaling group
# rds - amazon mariadb 

# configuration parameters for dev environment 
ec2_dev_count = 1
asg_dev_count = 1
cap_dev_count = 1
rds_dev_count = 1

# configuration parameters for tst environment
ec2_tst_count = 1
asg_tst_count = 1
cap_tst_count = 1
rds_tst_count = 1

# configuration parameters for prd environment
ec2_prd_count = 1
asg_prd_count = 1
cap_prd_count = 2
rds_prd_count = 1

