#!/bin/bash

# This is very raw as is POC only 

AMI_ID=ami-443a8d37
INSTANCE_TYPE=t1.micro
KEY_NAME=phooper-xps13

# Delete hostnames 
sudo sed -i '/cidb01/d' /etc/hosts 2>/dev/null
sudo sed -i '/ciweb01/d' /etc/hosts 2>/dev/null
sudo sed -i '/ciapp01/d' /etc/hosts 2>/dev/null

# Deleting CI tenant
VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=vpcOrchestra  --output json| grep VpcId | sed -e 's!",!!g' -e 's!^.*\"!!g' -e 's!",!!g')

[ -z "$VPC_ID" ] && exit 1 

for InstanceId in $(aws ec2 describe-instances --filters Name=vpc-id,Values=$VPC_ID --query 'Reservations[].Instances[].InstanceId' ) 
do
    echo "Deleting instance [ $InstanceId ]"
    aws ec2 terminate-instances --instance-ids $InstanceId
    INSTANCES_DELETED=Yes
done

[ "$INSTANCES_DELETED" = "Yes" ] && sleep 60

# Delete Subnets 
for SubnetId in $(aws ec2 describe-subnets  | grep $VPC_ID| awk ' { print $8 } ')
do 

    NACL_ID=$(aws ec2 describe-network-acls  | grep $SubnetId |  awk ' { print $3 } ')

    if [ "$NACL_ID" ] ; then 
        echo "DELETING NACL"
        aws ec2 delete-network-acl --network-acl-id  $NACL_ID >/dev/null 2>&1
    fi

    echo "DELETING SUBNET"
    aws ec2 delete-subnet --subnet-id $SubnetId

done

for RouteTableId in $(aws ec2 describe-route-tables  | grep $VPC_ID |  awk ' { print $2 } ')
do
    echo "DELETING ROUTE TABLE"
    aws ec2 delete-route-table --route-table-id $RouteTableId >/dev/null 2>&1
done

for SecurityGroupId in $(aws ec2 describe-security-groups  | grep $VPC_ID | grep -v "default" | awk ' { print $6 } ')
do 
    echo "DELETING SECURITY GROUPS"
    aws ec2 delete-security-group --group-id $SecurityGroupId 
done

# Detach internet gateway 
IGW_ID=$(aws ec2 describe-internet-gateways --filters Name=tag:Name,Values=igwOrchestra  --output json | grep "InternetGatewayId" | sed -e 's!",!!g' -e 's!^.*\"!!g' -e 's!",!!g')

[ "$IGW_ID" ] && { echo "DELETING IGW" ; aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID && aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID; } 

sleep 5 
# Delete the VPC 
echo "Deleting VPC [ $VPC_ID ]"
aws ec2 delete-vpc --vpc-id $VPC_ID
