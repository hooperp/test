#!/bin/bash

# This is very raw as is POC only 

AMI_ID=ami-443a8d37
INSTANCE_TYPE=t1.micro
KEY_NAME=phooper-xps13

if [ -x ./delete-all.sh ] ; then 
    ./delete-all.sh 
else 
    echo "No delete script present [ ./delete-all.sh ]. Exiting"
    exit 1 
fi

# -----------------------------------------------------------------------------------------------------------------------------------------

echo "Creating VPC"
# Create VPC and name it
VPC_ID=`aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text`
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=vpcOrchestra

# -----------------------------------------------------------------------------------------------------------------------------------------

# Create internet gateway and attach to VPC 
echo "Creating INTERNET GATEWAY"
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId')
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=igwOrchestra 

# -----------------------------------------------------------------------------------------------------------------------------------------

# Create route table and attach to Internet Gateway
echo "Updating ROUTE TABLE"
ROUTE_TABLE_ID=$(aws ec2 describe-route-tables | grep ROUTETABLES | grep "$VPC_ID" | awk ' { print $2 } ' )
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID 1>/dev/null
aws ec2 create-tags --resources $ROUTE_TABLE_ID --tags Key=Name,Value=rtbOrchestra 

# -----------------------------------------------------------------------------------------------------------------------------------------

# subnets 
echo "Creating SUBNETS"
DMZ_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId' --availability-zone eu-west-1a)
aws ec2 create-tags --resources $DMZ_SUBNET_ID --tags Key=Name,Value=subDMZOrchestra

APP_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --query 'Subnet.SubnetId' --availability-zone eu-west-1b)
aws ec2 create-tags --resources $APP_SUBNET_ID --tags Key=Name,Value=subAPPOrchestra

DB_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 --query 'Subnet.SubnetId' --availability-zone eu-west-1c)
aws ec2 create-tags --resources $DB_SUBNET_ID --tags Key=Name,Value=subDBOrchestra

# -----------------------------------------------------------------------------------------------------------------------------------------

# Security groups
echo "Creating SECURITY GROUPS"
DMZ_SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name sgOrchestraDMZ --description "Orchestra DMZ Security Group" --vpc-id $VPC_ID)
aws ec2 create-tags --resources $DMZ_SECURITY_GROUP_ID --tags Key=Name,Value=sgOrchestraDMZ 

APP_SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name sgOrchestraAPP --description "Orchestra APP Security Group" --vpc-id $VPC_ID)
aws ec2 create-tags --resources $APP_SECURITY_GROUP_ID --tags Key=Name,Value=sgOrchestraAPP 

DB_SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name sgOrchestraDB --description "Orchestra DB Security Group" --vpc-id $VPC_ID)
aws ec2 create-tags --resources $DB_SECURITY_GROUP_ID --tags Key=Name,Value=sgOrchestraDB 

# -----------------------------------------------------------------------------------------------------------------------------------------

# Add security rules 
echo "Adding SECURITY RULES"
aws ec2 authorize-security-group-ingress --group-id $DMZ_SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $APP_SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $DB_SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-egress --group-id $DMZ_SECURITY_GROUP_ID --protocol tcp --port 8140 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id $APP_SECURITY_GROUP_ID --protocol tcp --port 8140 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id $DB_SECURITY_GROUP_ID --protocol tcp --port 8140 --cidr 0.0.0.0/0

# -----------------------------------------------------------------------------------------------------------------------------------------

# Images 
echo "Building servers"
DMZ_INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $DMZ_SECURITY_GROUP_ID --subnet-id $DMZ_SUBNET_ID --query 'Instances[*].InstanceId' --private-ip-address 10.0.1.10 --associate-public-ip-address)
aws ec2 create-tags --resources $DMZ_INSTANCE_ID --tags Key=Name,Value=ciweb01

APP_INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $APP_SECURITY_GROUP_ID --subnet-id $APP_SUBNET_ID --query 'Instances[*].InstanceId' --private-ip-address 10.0.2.10 --associate-public-ip-address)
aws ec2 create-tags --resources $APP_INSTANCE_ID --tags Key=Name,Value=ciapp01

DB_INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $DB_SECURITY_GROUP_ID --subnet-id $DB_SUBNET_ID --query 'Instances[*].InstanceId' --private-ip-address 10.0.3.10 --associate-public-ip-address)
aws ec2 create-tags --resources $DB_INSTANCE_ID --tags Key=Name,Value=cidb01

# -----------------------------------------------------------------------------------------------------------------------------------------
