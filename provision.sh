#!/bin/bash

yum -y install centos-release-openshift-origin docker vim bash-completion httpd-tools
yum -y install origin
echo "INSECURE_REGISTRY='--insecure-registry 172.30.0.0/16'" >> /etc/sysconfig/docker
systemctl start docker

# Create initial cluster config
iptables -I INPUT -i eth0 -m tcp -p tcp --dport 8443 -j DROP
PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
oc cluster up \
    --host-config-dir=/root/origin/config \
    --host-data-dir=/root/origin/data \
    --host-pv-dir=/root/origin/pv \
    --host-volumes-dir=/root/origin/volumes \
    --use-existing-config \
    --public-hostname=$PUBLIC_IP
# Apply modifications on working cluster
oc login -u system:admin
oc create user '<USERNAME>'
echo '{
  "kind": "ClusterRoleBinding",
  "apiVersion": "v1",
  "metadata": {
    "name": "cluster-admin"
  },
  "subjects": [
    {
      "kind": "User",
      "name": "<USERNAME>"
    }
  ],
  "roleRef": {
    "name": "cluster-admin"
  }
}' | oc create -f -
oc cluster down
iptables -D INPUT -i eth0 -m tcp -p tcp --dport 8443 -j DROP

# Apply config file modifications on stopped cluster
htpasswd -bn <USERNAME> <PASSWORD> > /root/origin/config/master/htpasswd
sed -i -e 's#AllowAllPasswordIdentityProvider#HTPasswdPasswordIdentityProvider\n      file: /var/lib/origin/openshift.local.config/master/htpasswd#' \
    /root/origin/config/master/master-config.yaml
sed -i -e "s#example.com#$PUBLIC_IP#g" \
    /root/origin/config/master/openshift-master.kubeconfig \
    /root/origin/config/master/admin.kubeconfig \
    /root/origin/config/master/master-config.yaml
    
# Start configured cluster
oc cluster up \
    --host-config-dir=/root/origin/config \
    --host-data-dir=/root/origin/data \
    --host-pv-dir=/root/origin/pv \
    --host-volumes-dir=/root/origin/volumes \
    --use-existing-config \
    --public-hostname=$PUBLIC_IP

# Pre-configure oc client
oc login -u <USERNAME> -p <PASSWORD> --insecure-skip-tls-verify https://$PUBLIC_IP:8443
