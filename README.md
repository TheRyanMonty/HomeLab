# HomeLab Setup

## Introduction

The purpose of this repo is, selfishly, to document the setup and configuration I have outside of my network as a reference point in the future. Unselfishly I hope putting this in a public space will help others who are attempting to do a similar setup (high level defined below) be able to do so in a way that's easier than my learning epxerience and to have as a reference point of a working configuration.

### Goals of the configuration:
1. To host a personal website/blog site via Kubernetes (I specifically chose k3s) and expose the website to the internet moderately securely
2. To have the flexibliity to setup multiple different sites/services with a single domain by using the kubernetes ingress
3. To leverage letsencrypt to rollout and keep up to date a valid TLS certificate for the exposed sites and services
4. Decent web interface/gui to view and manage kubernetes
5. Ability to scale pods up or down across nodes

### What's doing the work:
- Kubernetes = [K3S](https://k3s.io/)
- Load Balancer = Since this is not a cloud configuration, using [metallb](https://metallb.universe.tf/) makes the most sense
- NFS = Needed to scale website app servers across worker nodes
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) = [nginx](https://github.com/kubernetes/ingress-nginx) - Serves as reverse proxy for kubernetes services and can serve content based on domain name used
- TLS Website certificates = Both [cert-manager](https://github.com/cert-manager/cert-manager) and [lets encrypt](https://letsencrypt.org/how-it-works/)

Network accessible service IPs will be assigned via MetalLB and yamls (i.e. using 10.50.1.200-210). Network router dhcp reservation space must be updated to accomodate the range used or IP conflicts will occur.

#### Note: While I will be leaving the manual instructions up, I have begun converting these manual steps into ansible driven 'playbooks' [here](https://github.com/TheRyanMonty/ServerManagement) on my server management github page.


### Versions Installed
* [KS3](https://github.com/k3s-io/k3s/releases) = v1.32.6
* [Metallb](https://metallb.universe.tf/release-notes/) = v0.15.2
* [Longhorn](https://github.com/longhorn/longhorn/releases) = v1.8.2
* [Wordpress](https://hub.docker.com/_/wordpress) = 6.8.2-php8.4-apache
* [Mysql (Wordpress)](https://hub.docker.com/_/mysql) = 9.3.0
* [ingress-nginx](https://github.com/kubernetes/ingress-nginx) = 1.6.4
* [cert-manager](https://cert-manager.io/docs/installation/supported-releases/) = v1.19.3

## All servers:
Set timezone, install qemu-guest-agent, set vi as shell browser and update/upgrade packages:
* ```curl -sfL https://raw.githubusercontent.com/TheRyanMonty/HomeLab/main/post_vm_build.sh | sh -```

#### Note: Ansible playbook for post VM standup is [here](https://github.com/TheRyanMonty/ServerManagement/blob/main/Ansible%20Playbooks/build_server_post_creation.yaml)

## pm-k3s-s1:
Install K3S: 
* ```curl -sfL https://get.k3s.io | sh -s server --disable traefik --disable servicelb```

Shutdown K3S on Shutdown (otherwise reboots can take up to 20 minutes):
* ```sudo ln -s /usr/local/bin/k3s-killall.sh /etc/rc0.d/K01k3s-stop```
* ```sudo ln -s /usr/local/bin/k3s-killall.sh /etc/rc6.d/K01k3s-stop```

Install MetalLB:
* ```kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml```

Apply IP range for home network:
* ```kubectl apply -f https://raw.githubusercontent.com/TheRyanMonty/HomeLab/main/K3S/metallb-config.yaml```

Get node token for use on agents:
* ```cat /var/lib/rancher/k3s/server/node-token```

Install Longhorn for distributed clustered storage management:
* ```kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.8.2/deploy/longhorn.yaml```

Expose longhorn ui on port 80:
* ```kubectl apply -f https://raw.githubusercontent.com/TheRyanMonty/HomeLab/main/K3S/longhorn-expose-frontend.yaml```

Set longhorn as default storage provider
* ```kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'```
* ```kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'```

Ensure longhorn is default storage provider
* ```kubectl get storageclass```

Set default replicas to two if only two workload servers are used (otherwise all volumes will be in a degraded state) and disable the master/control plane server from scheduling via the web ui.

Set taint for server so workloads are scheduled on agents and not on this master server:
* ```kubectl taint nodes pm-k3s-s1 key1=value1:NoSchedule```

## pm-k3s-wl1 (repeat for any other worker nodes):

Insert the output from node token cat command above on the command below for K3S_TOKEN variable and run on pm-k3s2:
* ```curl -sfL https://get.k3s.io | K3S_URL=https://10.50.1.53:6443 K3S_TOKEN=<insert_from_above> sh -```

Shutdown K3S on Shutdown (otherwise reboots can take up to 20 minutes):
* ```sudo ln -s /usr/local/bin/k3s-killall.sh /etc/rc0.d/K01k3s-stop```
* ```sudo ln -s /usr/local/bin/k3s-killall.sh /etc/rc6.d/K01k3s-stop```

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

## Install Wordpress to Kubernetes:

* Deploy secrets file and run (example file: https://github.com/TheRyanMonty/HomeLab/blob/main/K3S/example-wordpress-secrets.yaml), ex:
* ```kubectl apply -f wordpress-secrets.yaml```
* Set context for the wordpress namespace:
* ```kubectl config set-context --current --namespace=wordpress```
* Deploy the non-secret info:
* ```kubectl apply -f https://raw.githubusercontent.com/TheRyanMonty/HomeLab/main/K3S/wordpress-prod.yaml```
* Remember to be sure to setup backups via wordpress plugin "UpdraftPlus - Backup/Restore" - associate it with google drive (for now) - it's free.

## Install nginx ingress controller
* ``` kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v3.5.0/deploy/crds.yaml ```
* ``` kubectl apply -f https://raw.githubusercontent.com/TheRyanMonty/HomeLab/main/K3S/ingress-nginx.yaml ```

## TLS Certificate authority with Lets Encrypt via Kubernetes
Install cert-manager:
* ``` kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.0/cert-manager.yaml ```

Verify install:
* ``` kubectl get pods --namespace cert-manager ```

Create lets encrypt issuer reference:
* ``` kubectl apply -f https://raw.githubusercontent.com/TheRyanMonty/HomeLab/main/K3S/letsencrypt.yaml ```

Create wordpress certificate:
* ``` kubectl apply -f https://raw.githubusercontent.com/TheRyanMonty/HomeLab/main/K3S/certificate.yaml ```

Apply the ingress and include certificate information:
* ``` kubectl apply -f https://raw.githubusercontent.com/TheRyanMonty/HomeLab/main/K3S/ingress.yaml ```

Port forward on router to the appropriate nginx ingress metallb cluster ip on port 80 and 443 - can be obtained by getting external-ip from the following command:
* ``` kubectl get svc -n ingress-nginx ```

# Kubernetes / K3S Cheat Cheat:
To execute a command on a pod:
* ```kubectl exec --stdin --tty <pod_name> -- /bin/bash```

To list services (all):
* ```kubectl get svc -A```

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

How to expose a service for loadbalancer testing:
* ```kubectl expose deployment wordpress -n wordpress --type=LoadBalancer --name=wordpress-mysqlext --port=8003```

How to look at all namespaces:
* ```kubectl get namespaces```

How to look at and follow pod logs:
* ```kubectl logs -f <pod_name>```

Enable a user to manage the k3s cluster:
* ``` mkdir ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown $USER ~/.kube/config && chmod 600 ~/.kube/config && export KUBECONFIG=~/.kube/config && echo "export KUBECONFIG=~/.kube/config">>~/.bashrc ```
Install Alloy via Helm and pull down the k3s values yaml file from this repo
