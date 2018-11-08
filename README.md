# Openshift Cluster in AWS
This guide provisions an OpenShift Origin 3.10 cluster in AWS with 1 master node, 1 client node, and 1 bastion host. It uses ansible-playbook to deploy OpenShift to the master and client nodes from the bastion host after using Terraform to provision the AWS infrastructure. It is based on a [k8s-cluster-openshift-aws](https://github.com/hashicorp/terraform-guides/tree/openshift/infrastructure-as-code/k8s-cluster-openshift-aws) repository.

While the original repository required the user to manually run ansible-playbook after provisioning the AWS infrastructure with Terraform, this guide uses a Terraform [remote-exec provisioner](https://www.terraform.io/docs/provisioners/remote-exec.html) to do that. It also uses several additional remote-exec and local-exec provisioners to automate the rest of the deployment, retrieve the OpenShift cluster keys, and write them to outputs. This is important since it allows workspaces that deploy pods and services to the cluster do that via workspace state sharing without any manual copying of the cluster keys.

## Reference Material
* [openshift-ansible](https://github.com/openshift/openshift-ansible/tree/release-3.10): Ansible roles and playbooks for installing and managing OpenShift 3.10 clusters with Ansible.

## Challenge
The [advanced installation method](https://docs.openshift.com/container-platform/3.10/install_config/install/advanced_install.html) for OpenShift uses ansible-playbook to deploy OpenShift. Before doing that, the deployer must first provision some infrastructure and then configure an Ansible inventory file with suitable settings. Typically, ansible-playbook would be manually run on a bastion host even if a tool like Terraform had been used to provision the infrastructure.

## Solution
This guide combines and completely automates the two steps mentioned above:
1. Provisioning the AWS infrastructure.
1. Deploying OpenShift with Ansible
Additionally, it retrieves dynamically generated AWS keys from a [Vault](https://www.vaultproject.io/) server using Vault's [AWS Secrets Engine](https://www.vaultproject.io/docs/secrets/aws/index.html) and provisions and configures an instance of Vault's [Kubernetes Auth Method](https://www.vaultproject.io/docs/auth/kubernetes.html) so that pods provisioned by other workspaces can authenticate themselves against it. A vault-reviewer service account is provisioned for use by the Kubernetes auth method using a remote-exec provisioner.

Note that this guide is intended for demo and development usage. You would probably want to make modifications to the Terraform code for production usage including provisioning additional nodes.

## Prerequisites
1. Sign up for a free [AWS](https://aws.amazon.com/free/) account.
1. Create AWS access keys for your account. See the [Managing Access Keys for Your AWS Account](https://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html).
1. Create an AWS key pair for your AWS account. See [Amazon EC2 Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html).


## Step 1: Set Up and Configure a Vault Server
1. Set up a Vault server if you do not already have access to one and determine your username, password, and associated Vault token. See the Vault [Getting Started Guide](https://www.vaultproject.io/intro/getting-started/install.html) for details.
1. We assume that the [Userpass auth method](https://www.vaultproject.io/docs/auth/userpass.html) is enabled on your Vault server.  If not, that is ok.  You can login to the Vault UI with your Vault token instead of your username. Wherever the Terraform-specific instructions below ask you to specify your Vault username, just make one up for yourself.
1. Your Vault username and token will need to have a Vault policy like [sample-policy.hcl](./sample-policy.hcl) associated with them. You could use this one after changing "roger" to your username and renaming the file to \<username\>-policy.hcl.  
1. Provide USERNAME, PASSWORD, ACCESS_KEY, SECRET_KEY and run `install.sh` to set up the Vault AWS Secrets:
```
./install.sh
```

## Step 2: Set Up and Configure Terraform

Create a copy of the included openshift.tfvars.example file, calling it openshift.auto.tfvars, set values for the variables in it, run `terraform init`, and then run `terraform apply`.

```
cp openshift.tfvars.example openshift.tfvars
terraform init
terraform apply
```

## Cleanup
```
terraform destroy
```