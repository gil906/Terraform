#!/bin/bash

LB_IP=$1

if [ -z "$LB_IP" ]; then
  echo "Usage: $0 <LB_IP>"
  exit 1
fi

# Wait for VM to be ready (replace with more robust mechanism if needed)
sleep 60

# Send HTTP request to NGINX VMs
curl http://${LB_IP}
