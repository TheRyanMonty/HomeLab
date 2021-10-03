# HomeLab Setup

## Open Questions
  - How to do backups? (kubernetes cron job?)
  - How to deploy NFS for kubernetes (and use for backups?)
  - How to use traefik in k3s?
  - Implement Ansible for server build steps

## All servers:
Set timezone: 
```sudo timedatectl set-timezone America/Chicago```

Install qemu-guest-agent for VMs: 
```sudo apt install qemu-guest-agent```

Setup vi as shell browser: 
```echo "set -o vi" >> ~/.bashrc```


## Kubernetes:

Install K3S: 
* ```curl -sfL https://get.k3s.io | sh -```

Install Longhorn: 
* ```kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml```

How to tell which pod is on which node: 
* ```kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName --all-namespaces```


## Homelab1: Load balancer
Install nginx:
* ```sudo apt install nginx```
Critical file(s) to backups:
  /etc/nginx/conf.d/*

Install ddclient:
* ```sudo apt install ddclient```
Critical file(s) to backups:
  /etc/ddclient.conf

Install Certbot: https://certbot.eff.org/lets-encrypt/ubuntufocal-nginx
Ensure snapd is up to date: 
* ```sudo snap install core; sudo snap refresh core```

Install certbot: 
* ```sudo snap install --classic certbot```

Create logical link: 
* ```sudo ln -s /snap/bin/certbot /usr/bin/certbot```

Get and install cert: 
* ```sudo certbot --nginx```


## Homelab2 - Test Dev Box

## Homelab3 - Backup server (?)
Bad usb hub udev rule (Hardware issue on this box):
* ```echo "ACTION==\"add\", SUBSYSTEMS==\"usb\", RUN+=\"/bin/sh -c 'echo 0 > /sys/bus/usb/devices/usb7/authorized_default'\"" > /etc/udev/rules.d/01-usb_disable_bad_device.rules```

