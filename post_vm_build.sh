#!/bin/bash
################################################################################
##
##      post_vm_build.sh
##
################################################################################

#Set timezone:
sudo timedatectl set-timezone America/Chicago
#Install qemu-guest-agent for VMs:
sudo apt install qemu-guest-agent nfs-common
#Setup vi as shell browser:
echo "set -o vi" >> ~/.bashrc; sudo echo "set -o vi" >> ~/.bashrc
#update and upgrade
sudo apt update; sudo apt upgrade

exit 0
