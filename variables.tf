variable "region" {
  description = "AWS region to deploy the cluster into"
  default = "ca-central-1"
}

variable "key_name" {
  description = "The name of the key to user for ssh access"
}

variable "private_key_data" {
  description = "contents of the private key"
}

variable "node_size" {
  description = "The size of the cluster nodes, e.g: t2.large. Note that OpenShift will not run on anything smaller than t2.large"
  default = "t2.large"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  default = "10.0.1.0/24"
}

variable "subnetaz" {
  type        = "list"
  description = "Lists the subnets to be created in their respective AZ."

  default = [
    {
      name = "subnet1"
      az   = "ca-central-1a"
      cidr = "10.0.0.0/24"
    },
    {
      name = "subnet1"
      az   = "ca-central-1b"
      cidr = "10.0.1.0/24"
    },
  ]
}

variable "name_tag_prefix" {
  description = "prefixed to Name tag added to EC2 instances and other AWS resources"
  default     = "OpenShift"
}

variable "owner" {
  description = "value set on EC2 owner tag"
  default = "Nobody"
}

variable "ttl" {
  description = "value set on EC2 TTL tag. -1 means forever. Measured in hours."
  default = "-1"
}

variable "vault_k8s_auth_path" {
  description = "The path of the Vault k8s auth backend"
  default = "openshift"
}

variable "vault_user" {
  description = "Vault userid: determines location of secrets and affects path of k8s auth backend"
}

variable "vault_addr" {
  description = "Address of Vault server including port"
}
