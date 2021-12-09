#!/bin/bash
################################################################################
##
##      post_vm_build.sh
##
################################################################################

#Set timezone:
sudo timedatectl set-timezone America/Chicago
#Install qemu-guest-agent for VMs:
sudo apt install qemu-guest-agent
#Setup vi as shell browser:
echo "set -o vi" >> ~/.bashrc; sudo echo "set -o vi" >> ~/.bashrc

exit 0
