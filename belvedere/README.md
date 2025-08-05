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

TODO: Needed: Whisper, piper, Ollama

Ollama install:
```
curl -fsSL https://ollama.com/install.sh | sh
```
After the install, you have to ensure ollama starts *after* the gpu is recognized, note the 'After' and 'Requires' stanzas in the example below for the service file. Also you need the other environment variable to integrate with home assistant.
```
monty@belvedere:~$ cat /etc/systemd/system/ollama.service
[Unit]
Description=Ollama Service
After=sys-bus-pci-drivers-nvidia.device
Requires=sys-bus-pci-drivers-nvidia.device

[Service]
ExecStart=/usr/local/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
Environment="OLLAMA_HOST=0.0.0.0:11434"

[Install]
WantedBy=default.target
```
Pull down the llama3 model
```
ollama pull llama3
```
Run the llama3 model
```
ollama run llama3
```
Watch graphics card performance to ensure it's being used
```
watch -n 0.5 nvidia-smi
```
Install openwebui

Install Docker
 Add Docker's official GPG key:
```
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```
Add the repository to Apt sources:
```
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```
Install Docker
```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
Run Open WebUi Docker Container
```
docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main
```
