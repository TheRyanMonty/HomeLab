# HomeLab Setup

Port listing/planning:
- 8000 = Kubernetes Dashboard
- 8001 = Longhorn Storage Management Dashboard
- 8002 = Wordpress / Main Blog Site
- 8003 = Wordpress Database Access

## Open Questions
  - How to do backups? (kubernetes cron job?)
  - How to deploy NFS for kubernetes (and use for backups?)
  - How to use traefik in k3s?
  - Implement Ansible for server build steps
  - How to disable control-plane/master server from longhorn automatically?

## All servers:
Set timezone, install qemu-guest-agent, set vi as shell browser and update/upgrade packages:
* ```curl -sfL https://raw.githubusercontent.com/TheRyanMonty/HomeLab/main/post_vm_build.sh | sh -```

## Kubernetes:

## pm-k3s-s1:
Install K3S: 
* ```curl -sfL https://get.k3s.io | sh -```

Get node token for use on agents:
* ```cat /var/lib/rancher/k3s/server/node-token```

Install Kubernetes Dashboard:
* ```kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml```

Run the assist pieces to make it accessible on port 8000:
* ```kubectl apply -f https://raw.githubusercontent.com/TheRyanMonty/HomeLab/main/K3S/kubernetes-dashboard-assist.yaml```

Get the token for kubernetes dashboard:
* ```kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"```

Install Longhorn for distributed clustered storage management:
* ```kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.2.2/deploy/longhorn.yaml```

Expose longhorn ui on port 8001:
* ```kubectl apply -f https://raw.githubusercontent.com/TheRyanMonty/HomeLab/main/K3S/longhorn-expose-frontend.yaml```

Set longhorn as default storage provider
* ```kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'```
* ```kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'```

Ensure longhorn is default storage provider
* ```kubectl get storageclass```

Set default replicas to two if only two workload servers are used (otherwise all volumes will be in a degraded state) and disable the master/control plane server from scheduling via the web ui.

Set taint for server so workloads are scheduled on agents and not on this master server:
* ```kubectl taint nodes pm-k3s-s1 key1=value1:NoSchedule```

## pm-k3s-wl1:

Insert the output from node token cat command above on the command below for K3S_TOKEN variable and run on pm-k3s2:
* ```curl -sfL https://get.k3s.io | K3S_URL=https://192.168.86.35:6443 K3S_TOKEN=<insert_from_above> sh -```

Setup the ability to run kubectl from this workload server:

On server node pm-k3s-s1
* ```sudo cp /etc/rancher/k3s/k3s.yaml /tmp/config```
* ```sudo chmod +r /tmp/config```

On workload server pm-k3s-wl1
* ```mkdir -p ~/.kube/```
* ```sudo scp pm-k3s-s1:/tmp/config ~/.kube/```
* ```chmod 600 ~/.kube/config```
* ```ls -al ~/.kube/config```

Test
* ```kubectl get pods --all-namespaces```

Install Wordpress:
* Deploy secrets file and run (example file: https://github.com/TheRyanMonty/HomeLab/blob/main/K3S/example-wordpress-secrets.yaml), ex:
* ```kubectl apply -f wordpress-secrets.yaml```
* Set context for the wordpress namespace:
* ```kubectl config set-context --current --namespace=wordpress```
* Deploy the non-secret info:
* ```kubectl apply -f https://raw.githubusercontent.com/TheRyanMonty/HomeLab/main/K3S/wordpress-prod.yaml```



## K3S Cheat Cheat:
To execute a command on a pod:
* ```kubectl exec --stdin --tty <pod_name> -- /bin/bash```

To scale a deployment:
* ```kubectl scale deployment/<deployment_name> --replicas=10```

To set context to a namespace:
* ```kubectl config set-context --current --namespace=<namespace>```

To store a secret, it must be encoded base64 via yaml file:
* ```echo '<user or password in plain text>' | base64```

To decode a secret, you must also use base64:
* ```echo '<encoded user or password>' | base64 --decode```

How to tell which pod is on which node: 
* ```kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName --all-namespaces```

How to uninstall k3s:
* ```/usr/local/bin/k3s-uninstall.sh```

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

Install NFS:
* ```sudo apt install nfs-kernel-server```


