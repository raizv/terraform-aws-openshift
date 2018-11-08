#!/bin/sh

USERNAME='username'
PASSWORD='password'
ACCESS_KEY='access_key'
SECRET_KEY='secret_key'

vault auth enable userpass
vault write auth/userpass/users/${USERNAME} \
    password=${PASSWORD} \
    policies=admins

vault write sys/policy/${USERNAME} policy=@${USERNAME}-policy.hcl
vault write auth/userpass/users/${USERNAME} policies="${USERNAME}"
vault token create -display-name=${USERNAME}-token -policy=${USERNAME} -ttl=720h

vault secrets enable -path=aws-tf aws

vault write aws-tf/config/root access_key=${ACCESS_KEY} secret_key=${SECRET_KEY} region=${REGION}

vault write aws-tf/roles/deploy policy=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOF