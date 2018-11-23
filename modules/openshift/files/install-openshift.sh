#!/usr/bin/env bash
set -x
exec > /home/centos/install-openshift.log 2>&1

# Install Docker
sudo yum install -y docker
sudo service docker start

# Set up bastion to SSH to other servers
echo "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAi/ysbAC+9sT2eK0bnCKYrzA0c21rpa5t4QP1EWE87k+1kWmhniEs0gI3+iui
6Y9u4kYGI9zU72Pm1pRmcOhFt0nVmiuv0urRyChz74RPd+GlmPzx+W8yTn1Xx2Nw6g5oTa7m9OWU
GFL8gczehasTXA3aahCbY57rcC4HWOJ+5z35C2PXeCntR4SjFao+c5gSy6z7j1ujYvr31mizgeZG
U5GAAk6dpnzRxCIptAg4rnRJbjSM1RJd3Beeuo2afc9s/R2rmI3I00ZJAifH04fHuFsitF9Q/ziP
hsR4d0/HYLo5V7cojRtJTFWMDEaIOs4bwv/d1l48XaEAlSj3KB21gwIDAQABAoIBABOaISbKf/Mc
J4tEaj5V1d2KOX4ET3OW1koQ/MsfO6H/RWSETx5OdPE/YElGvPxJmnRS698vuB2BdryLcUDUNZbx
3thEz80QFqoZiAp9E4es8DxZByUvffLhuF3yPch4lgBywmJ+l1tEm5ktb+d1yjM0uWXqx2eOxFck
CuFWbgDBRpp9AdAMSuN7I6ub6kgkA0d3n1BjReoLndiK84dVmJFqgz4aHV53IJUdOCDl5xCkIhay
Q5u1itt9K87Fc1LRkll0IpEjTXJeCplrFs/tFiogPv5Flcu4bcOju8t46Mf6sIMh7oB9AfOrFtUp
4YlgRwdVxmrf8l+DfPlqr36B1PECgYEAzrcgwd9TrR8mYfsvelXIHTT3zwYH5ZP8XTTsabZmGkRt
Ur99np3R61j+dR7vJi4PS89sQEHX4/8UmpxyvWARq+IGS9Y4tOifPhRduI1/oTaBajqMK45j7eji
otnY8NmkRYdZDQT70UGjwdU0sdfD47tffJfc8OrUvoe4LQkkb3sCgYEArVzH+MBOe7/eoG403LgR
a0uy1jn5mgJkSY+jSN3L/uU9UgnX2HAQRa0QFn5VhgfoKhdIVRyqva1daw4HnOudh6ronr2Cj0DW
RXEFG9OFtP5BIIpvP9l9TcmxT7y+YjurkmgbyA5Cfmk7eEAIP+jcg6Nm+iak2uA8sUabzrDGr5kC
gYEAxePUDSURgtMmOHhxnCiQuT0i2mJInwQLfOMUS6McnZrSGXxN8tHcyvPYLSEfCirf49A/Lkia
N57TB6wrv5U/dY+cPW9nu/BRuelfSzTScO+v9pTz6SKYEYJ3rDTmlLOVqiYHHwqdU1cGQKItnu8S
jWmr4Ke1EEGOxpNAwoRVCA8CgYEAjRcapIcWGL7R1+15Vjzz6EfmV1U9n6rcpcWh1Va1hFBbNJ5Q
LZUemSY9FqFgx0E+IKtsMeCv0Mj8Y3k6lupm/ZgJ089WJ3JUMJXH25qtkdzvciVYXzWJNjq09Lke
lOINQ405NvrsAOdx/+7VB/ZjKTtePq4esweWPYzCl1fli9kCgYBB4pLfqDgxaO/SiEJsNyrEgdIm
Cunjr+NAKYQJ6pu6s9ENuQgvEMU7gnx4aXmxyoEcpV5sqNs7y42tvBkk5t/znFO7bI7AaXUar+ed
RNKYDUYMCabffOl2KLBMEGzWRl1iTrGn964o8nS0ZyVTY6mBKsZikNkn8CiN8EKYJMth3g==
-----END RSA PRIVATE KEY-----
" > /home/centos/.ssh/private-key.pem
chmod 400 /home/centos/.ssh/private-key.pem
eval $(ssh-agent)
ssh-add /home/centos/.ssh/private-key.pem
ssh-keyscan -t rsa -H master.openshift.local >> /home/centos/.ssh/known_hosts
ssh-keyscan -t rsa -H node1.openshift.local >> /home/centos/.ssh/known_hosts

# Create inventory.cfg file
cat > /home/centos/inventory.cfg << EOF
# Waited: 60 seconds before generating from template
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

openshift_public_hostname=35.182.243.116.xip.io
openshift_master_default_subdomain=35.182.243.116.xip.io

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