# `SQLScale` - Opensource RDS like Database as a service On-Premise powered by OpenEBS technology!

## Introduction

SQLScale Opensource RDS like Database as a service On-Premise powered by OpenEBS technology

This open source project focus on deployment of AWS EKS cluster using eksctl.io (tool), and then performing a deployment of a RDS like Database as a service using Terraform.

Deployment model:
<BR>
<img src="images/mysql-deployment-8c4333871987b924c2606fb5e60e8333.svg" alt="OpenEBS MySQL RDS" />

<BR>
MYSQL is most ubiquitous and commonly used database. RDS is a service that make deploying and making MYSQL easy. With OpenEBS CAS architecture each user is assigned an independent stack of storage that serves just one instance of MySQL database, making it easy to handle the provisioning and post deployment operations like capacity increase and upgrades.
<BR>
Use OpenEBS and MySQL containers to quickly launch an RDS like service, where database launch is instantaneous, availability is provided across zones and increase in requested capacity can happen on the fly.

More details: https://openebs.io/docs/stateful-applications/mysql

## Prerequisite

You will need to have AWS API credentials configured. What works for AWS CLI or any other tools (kops, Terraform, etc.) should be sufficient. You can use [`~/.aws/credentials` file][awsconfig]
or [environment variables][awsenv]. For more information read [AWS documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-environment.html).

- eksctl.io tool installed (https://eksctl.io/installation/).
- kubectl (latest prefferable) installed. (https://kubernetes.io/docs/tasks/tools/)
- aws cli tool installed. (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- terraform installed. (https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Getting started

Please clone this repo to your local computer or remote virtual machine/server and adjust **cluster.yaml** file 

Content of file described:
<BR>
```
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: sqlscale   <-- name your AWS EKS Cluster
  region: us-east-1 <-- AWS region of deployment

availabilityZones: ["us-east-1a", "us-east-1b"] <-- Fixed Availability Zones 

addons: <-- Some of the addons we find normal to have
  - name: vpc-cni
    version: latest
  - name: coredns
    version: latest
  - name: kube-proxy
    version: latest

nodeGroups:
  - name: sqlng-1 <-- name of the first node group
    instanceType: t2.medium <-- example/demo type of the EC2 instance used
    instanceName: sqlscale-worker-1 <-- instance name
    desiredCapacity: 4 <-- this is initial desired capacity, you can adjust later with more or less using eksctl tool
    volumeSize: 50 <-- this is Root volume for Ubuntu OS
    volumeType: gp3
    amiFamily: Ubuntu2204 <-- We selected default AWS Ubuntu 22.04 version from their repository
    ami: auto
    ssh:
      allow: true # will use ~/.ssh/id_rsa.pub as the default ssh key <-- adjust if different place by adding path
    privateNetworking: true <-- We will add private networking
    preBootstrapCommands:
      # allow docker registries to be deployed as cluster service
      - "sed '2i \"insecure-registries\": [\"172.20.0.0/16\",\"10.100.0.0/16\"],'  /etc/docker/daemon.json"
      - "systemctl restart docker"
    overrideBootstrapCommand: |
      #!/bin/bash
      /etc/eks/bootstrap.sh sqlscale
  - name: sqlng-2
    instanceType: t2.medium
    instanceName: sqlscale-worker-2
    desiredCapacity: 4
    volumeSize: 50
    volumeType: gp3
    amiFamily: Ubuntu2204
    ami: auto
    ssh:
      allow: true # will use ~/.ssh/id_rsa.pub as the default ssh key
    privateNetworking: true
    preBootstrapCommands:
      # allow docker registries to be deployed as cluster service
      - "sed '2i \"insecure-registries\": [\"172.20.0.0/16\",\"10.100.0.0/16\"],'  /etc/docker/daemon.json"
      - "systemctl restart docker"
    overrideBootstrapCommand: |
      #!/bin/bash
      /etc/eks/bootstrap.sh sqlscale
```
<BR>
Basically first and 2nd group are the same just they will deploy half in us-east1a and half in us-east1b to achieve redundancy. You can explore and add Multi-AZ in different Area zones and test. More details what else you can add within cluster.yaml file you can read here:
<BR>
https://eksctl.io/usage/creating-and-managing-clusters/
<BR>
<BR>
Once your cluster.yaml file is ready please execute following to create a cluster:

```
eksctl create cluster -f cluster.yaml
```

** Before executing make sure you are good with ~/.aws/credentials and ~/.aws/config so you are using correct API keys. <BR>
<BR>
Wait for cluster to be deployed.
<BR>

Next is Terraform part. It starts by adjusting **variables.tf** file with desired values what is the size of the Additional volumes you will attach to each Worker node, and how much initial you wish to have replicas of Storage Class and MariaDB Stateful set deployments. You can adjust default namespaces for OpenEBS and MariaDB itself.
<BR>

Once you are done with adjusting variables, execute following commands:
<BR>

```
terraform init
terraform plan
terraform deploy
```
<BR>

Execute one by one and wait for Automation deployment to complete. In this demo we have a MariaDB deployment so you may explore MariaDB Helm chart to update anything else you wish to have in your Helm deployment what we have excluded in our demo, like tunning up MySQL Configuration, and a lot more.

That's it for now. We will update SQLScale project Readme files how time goes.