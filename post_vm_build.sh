#!/bin/bash
################################################################################
##
##      post_vm_build.sh
##
################################################################################

#Set timezone:
sudo timedatectl set-timezone America/Chicago
#Install qemu-guest-agent for VMs:
sudo apt install -y qemu-guest-agent nfs-common
#Setup vi as shell browser:
echo "set -o vi" >> ~/.bashrc
#Set default editor to vi/vim
echo "export EDITOR='vim'" >> ~/.bashrc
#update and upgrade
sudo apt update; sudo apt dist-upgrade -y

exit 0
