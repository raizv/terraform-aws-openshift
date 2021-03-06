#!/usr/bin/env bash
set -x
exec > /home/centos/install-openshift.log 2>&1

# Install Docker
sudo yum install -y docker
sudo service docker start

# Set up bastion to SSH to other servers
echo "${private_key}" > /home/centos/.ssh/private-key.pem
chmod 400 /home/centos/.ssh/private-key.pem
eval $(ssh-agent)
ssh-add /home/centos/.ssh/private-key.pem
ssh-keyscan -t rsa -H master.openshift.local >> /home/centos/.ssh/known_hosts
ssh-keyscan -t rsa -H node1.openshift.local >> /home/centos/.ssh/known_hosts

# Create inventory.cfg file
cat > /home/centos/inventory.cfg << EOF
# Waited: ${wait} seconds before generating from template
# Create an OSEv3 group that contains the masters and nodes groups
[OSEv3:children]
masters
nodes
etcd

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
# OpenShift repository configuration
openshift_additional_repos=[{'id': 'cbs-centos', 'name': 'CBS-Centos', 'baseurl': 'http://cbs.centos.org/repos/paas7-openshift-origin311-release/x86_64/os', 'enabled': 1, 'gpgcheck': 0} ]


ansible_ssh_user=centos
ansible_become=true

openshift_release=v3.11
openshift_deployment_type=origin
openshift_disable_check=disk_availability,docker_storage,memory_availability

openshift_metrics_install_metrics=false
openshift_logging_install_logging=false

os_sdn_network_plugin_name='redhat/openshift-ovs-multitenant'

openshift_public_hostname=${master_ip}.xip.io
openshift_master_default_subdomain=${master_ip}.xip.io

# openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]

openshift_master_identity_providers=[{'name': 'google', 'challenge': 'false', 'login': 'true', 'kind': 'GoogleIdentityProvider', 'mapping_method': 'claim', 'clientID': '239568883196-k90c35878su0mtc9t76trfr5519nfnor.apps.googleusercontent.com', 'clientSecret': 'krkv4V0z-b6skmrktAxXJ9iZ', 'hostedDomain': 'raizv.ca'}]

# Create the masters host group. Be explicit with the openshift_hostname,
# otherwise it will resolve to something like ip-10-0-1-98.ec2.internal and use
# that as the node name.
[masters]
master.openshift.local openshift_hostname=master.openshift.local

# host group for etcd
[etcd]
master.openshift.local openshift_hostname=master.openshift.local

# host group for nodes, includes region info
[nodes]
master.openshift.local openshift_hostname=master.openshift.local openshift_schedulable=true  openshift_node_group_name='node-config-all-in-one'
node1.openshift.local openshift_hostname=node1.openshift.local openshift_node_group_name='node-config-compute'
EOF


# ANSIBLE_HOST_KEY_CHECKING=False /usr/local/bin/ansible-playbook -i ~/inventory.cfg ~/openshift-ansible/playbooks/prerequisites.yml
# ANSIBLE_HOST_KEY_CHECKING=False /usr/local/bin/ansible-playbook -i ~/inventory.cfg ~/openshift-ansible/playbooks/deploy_cluster.yml

sudo docker run --rm -t -u `id -u` \
    -v $HOME/.ssh/private-key.pem:/opt/app-root/src/.ssh/id_rsa:Z \
    -v $HOME/inventory.cfg:/tmp/inventory:Z \
    -e ANSIBLE_HOST_KEY_CHECKING=False \
    -e INVENTORY_FILE=/tmp/inventory \
    -e PLAYBOOK_FILE=playbooks/prerequisites.yml \
    -e OPTS="-v" \
    openshift/origin-ansible:v3.11

sudo docker run --rm -t -u `id -u` \
    -v $HOME/.ssh/private-key.pem:/opt/app-root/src/.ssh/id_rsa:Z \
    -v $HOME/inventory.cfg:/tmp/inventory:Z \
    -e ANSIBLE_HOST_KEY_CHECKING=False \
    -e INVENTORY_FILE=/tmp/inventory \
    -e PLAYBOOK_FILE=playbooks/deploy_cluster.yml \
    -e OPTS="-v" \
    openshift/origin-ansible:v3.11