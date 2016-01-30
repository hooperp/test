#!/bin/bash

# This is very raw as is POC only 

# Create VPC and name it
VPCID=`aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text`
aws ec2 create-tags --resources $VPCID --tags Key=Name,Value=vpcOrchestra


# subnets 

DMZ_SUBNET=$(aws ec2 create-subnet --vpc-id $VPCID --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId')
aws ec2 create-tags --resources $DMZ_SUBNET --tags Key=Name,Value=subDMZOrchestra

APP_SUBNET=$(aws ec2 create-subnet --vpc-id $VPCID --cidr-block 10.0.2.0/24 --query 'Subnet.SubnetId')
aws ec2 create-tags --resources $APP_SUBNET --tags Key=Name,Value=subAPPOrchestra

DB_SUBNET=$(aws ec2 create-subnet --vpc-id $VPCID --cidr-block 10.0.3.0/24 --query 'Subnet.SubnetId')
aws ec2 create-tags --resources $DB_SUBNET --tags Key=Name,Value=subDBOrchestra

