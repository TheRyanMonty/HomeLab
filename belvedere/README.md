At the proxmox host level ensure the GRUB_CMDLINE_LINUX_DEFAULT activates intel_iommu in the file /etc/default/grub:
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"
```

Run the following command to modify the /etc/modules file to add the lines
```
echo "vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd">>/etc/modules
```

Enable IOMMU interrupt remapping:
```
echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf
echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf
```

Blacklist drivers from the host so the host won't use them:
```
echo "blacklist radeon" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf
```
using output from:
```
lspci | grep vga
```
Get needed info - example:
root@homelab-proxmox:~# lspci | grep -i vga
01:00.0 VGA compatible controller: NVIDIA Corporation TU106 [GeForce RTX 2070 Rev. A] (rev a1)
02:00.0 VGA compatible controller: NVIDIA Corporation GP107 [GeForce GTX 1050 Ti] (rev a1)
root@homelab-proxmox:~# lspci -n -s 01:00
01:00.0 0300: 10de:1f07 (rev a1)
01:00.1 0403: 10de:10f9 (rev a1)
01:00.2 0c03: 10de:1ada (rev a1)
01:00.3 0c80: 10de:1adb (rev a1)


I want to share my 2070, so 01:00 - and need the vendor codes for the .0 and .1 entries (10de:1f07, 10de:10f9) - from there we construct the next command:
```
echo "options vfio-pci ids=10de:1f07,10de:10f9 disable_vga=1"> /etc/modprobe.d/vfio.conf
```
Now we update initramfs:
```
update-initramfs -u
```
and then reboot:
```
reboot
```

Configure the VM to use it

Set the /etc/pve/qemu-server/<vmid>.conf (my vmid is 104) file to enable q35
```
echo "machine: q35">>/etc/pve/qemu-server/104.conf
```
Install Graphics Driver:
```
sudo ubuntu-drivers autoinstall
```
