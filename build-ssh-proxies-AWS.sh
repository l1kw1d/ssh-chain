#!/bin/bash

# Number of instances to create
NUM_INSTANCES=5

# AWS details
INSTANCE_TYPE="t2.micro"
IMAGE_ID="ami-0abcdef1234567890" # Replace with a valid Ubuntu AMI for your region
KEY_PAIR_NAME="your-key-pair-name"
SECURITY_GROUP_ID="your-security-group-id"

# SSH details
SSH_USER="ubuntu"
SSH_KEY_PATH="~/.ssh/id_rsa"
SSH_PORT=12345  # local port for SSH tunnel

# Proxychains config file
PROXYCHAINS_CONF="/etc/proxychains.conf"

# Ensure SSH key is present and has correct permissions
chmod 600 $SSH_KEY_PATH

# Create instances and setup SSH tunnel
for ((i=1; i<=NUM_INSTANCES; i++))
do
  # Create instance
  INSTANCE_ID=$(aws ec2 run-instances --image-id $IMAGE_ID --instance-type $INSTANCE_TYPE --key-name $KEY_PAIR_NAME --security-group-ids $SECURITY_GROUP_ID --query 'Instances[0].InstanceId' --output text)

  # Wait for instance to be running
  aws ec2 wait instance-running --instance-ids $INSTANCE_ID

  # Get instance IP
  INSTANCE_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

  # Setup SSH tunnel
  ssh -fN -D $SSH_PORT -i $SSH_KEY_PATH $SSH_USER@$INSTANCE_IP

  # Add to Proxychains config
  echo "socks5 127.0.0.1 $SSH_PORT" >> $PROXYCHAINS_CONF

  # Increment local port for next SSH tunnel
  ((SSH_PORT++))
done
