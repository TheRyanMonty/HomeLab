#!/bin/bash
################################################################################
##
##      post_vm_build.sh
##
################################################################################

# Elevate privs
if [ $EUID -ne 0 ]; then 
  echo "Execution failed: Please run with 'sudo ./post_vm_build.sh'"
  exit 1
fi

# Timezone & Packages
timedatectl set-timezone America/Chicago
apt update && apt install -y qemu-guest-agent nfs-common

# Configure Shell (Both Local and Root)
# Using $SUDO_USER ensures we find your home dir even if running as root
TARGET_FILES="/root/.bashrc"
[ -n "$SUDO_USER" ] && TARGET_FILES+=("/home/$SUDO_USER/.bashrc")

for RC in "${TARGET_FILES[@]}"; do
    echo "set -o vi" >> "$RC"
    echo "export EDITOR='vim'" >> "$RC"
    echo "alias sagdu='sudo apt update; sudo apt dist-upgrade -y'" >> "$RC"
done

# Update and upgrade
apt dist-upgrade -y

# K3S / Longhorn Overrides
cat <<EOF >> /etc/sysctl.conf
###################################################################
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
net.ipv4.ip_forward=1
EOF

# 6. Apply sysctl changes immediately
sysctl -p

exit 0

