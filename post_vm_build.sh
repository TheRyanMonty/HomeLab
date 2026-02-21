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
sudo echo "set -o vi">>/root/.bashrc
#Set default editor to vi/vim
echo "export EDITOR='vim'" >> ~/.bashrc
sudo echo "export EDITOR='vim'" >> /root/.bashrc
#update and upgrade
sudo apt update; sudo apt dist-upgrade -y

##Added for K3S nodes, but shouldn't hurt any other VM
echo "###################################################################
# Kubernetes & Longhorn specific overrides
# Fixes: failed to create fsnotify watcher: too many open files
###################################################################

# Increase the number of inotify user instances
# Default is often 128; 1024 is recommended for clusters with many volumes
fs.inotify.max_user_instances=1024

# Increase the number of inotify user watches
# Default is 8192; 1048576 is standard for Longhorn/distributed storage
fs.inotify.max_user_watches=1048576

# Ensure IP forwarding is enabled for K3s networking (Flannel/Calico)
net.ipv4.ip_forward=1">>/etc/sysctl.conf

exit 0
