# This example uses Terraform to create an AWS EKS (Kubernetes) cluster, and then uses HELM to install MariaDB chart.

***

#####  **Warning: Following this guide will create objects in your AWS account that will cost you money against your AWS bill.**  
***


This guide assumes you are running on a Ubuntu 16.04 LTS Xenial. Modify accordingly, if you use another OS/distro.
*Intentionally left non-automated, so you can play around and experiment on every step*

### Requirements:
* AWS account[link to AWS console]
* Terraform[link to install - https://learn.hashicorp.com/terraform/getting-started/install.html]
* kubectl
* helm
* aws-iam-authenticator

### Summary:
1. Setup a K8S cluster
2. Setup kubectl + aws_-iam-authenticator
3. Create service account for Tiller as AWS EKS uses RBAC
4. Install Helm (TODO: Helm itself is not needed, but it's configuration created during `init` is)

#### > Run as root (for the time being)
```
$ sudo su -
```

#### > Clone the repo:
```
cd ~
git clone https://github.com/qwerty1979bg/tf-aws-eks-helm-mariadb.git
```
#### > [Install terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
.
#### > Create an AWS EKS Cluster:
[This is basically the code from Terraform 'Getting Started with AWS EKS' guide](https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html)

###### The sample architecture introduced here includes the following resources:
> EKS Cluster: AWS managed Kubernetes cluster of master servers
AutoScaling Group containing 2 m4.large instances based on the latest EKS Amazon Linux 2 AMI: Operator managed Kubernetes worker nodes for running Kubernetes service deployments
Associated VPC, Internet Gateway, Security Groups, and Subnets: Operator managed networking resources for the EKS Cluster and worker node instances
Associated IAM Roles and Policies: Operator managed access resources for EKS and worker node instances


```
$ cd ~/tf-aws-eks-helm-mariadb/eks-getting-started
(optional) $ export TF_VAR_eks_worker_instance_type=t2.small  # depends on intended workload
(optional) $ export TF_VAR_eks_worker_desired_capacity=1      # depends on intended workload
(optional) $ export TF_VAR_aws_region=us-east-1
(optional) $ export TF_VAR_cluster_name=demo-cluster1
$ export AWS_ACCESS_KEY_ID="<YOUR AWS ACCESS KEY>"
$ export AWS_SECRET_ACCESS_KEY="<YOUR AWS SECRET KEY>"
$ terraform init
$ terraform plan
$ terraform apply
(optional) wait patiently / drink caffeinated beverage. It takes about 10 minutes...
```
#### > [Install aws-iam-authenticator](https://docs.aws.amazon.com/eks/latest/userguide/configure-kubectl.html)
**Download the Amazon EKS-vended aws-iam-authenticator binary from Amazon S3:**
```
$ curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/aws-iam-authenticator
```
**(Optional) Verify the downloaded binary with the SHA-256 checksum**
```
$ curl https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/aws-iam-authenticator.sha256 | sha256sum -c -
```
**Apply execute permissions to the binary**
```
$ chmod +x ./aws-iam-authenticator
```
**Move the binary to a folder in your PATH**
```
$ mv ./aws-iam-authenticator /usr/local/bin/
```
**Test that the aws-iam-authenticator binary works**
```
$ aws-iam-authenticator help
```

#### > [Install kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)
**Download the Amazon EKS-vended kubectl binary from Amazon S3:**
```
$ curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/kubectl
```
**(Optional) Verify the downloaded binary with the SHA-256 checksum**
```
$ curl https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/kubectl.sha256 | sha256sum -c -
```
**Apply execute permissions to the binary**
```
$ chmod +x ./kubectl
```
**Move the binary to a folder in your PATH**
```
$ mv ./kubectl /usr/local/bin/
```
**Verify installation**
```
$ kubectl version --short --client
```

#### > Setup kubectl
```
$ mkdir -p ~/.kube
$ cd ~/tf-aws-eks-helm-mariadb/eks-getting-started
$ terraform output kubeconfig > ~/.kube/config
```
**Verify**
```
$ kubectl version --short
```
#### > Enable the worker node(s) to join the cluster:
```
$ cd ~/tf-aws-eks-helm-mariadb/eks-getting-started
$ terraform output config_map_aws_auth > config_map_aws_auth.yaml
$ kubectl apply -f config_map_aws_auth.yaml
(optional) $ kubectl get nodes --watch # (watch the nodes join the cluster)
```

#### > Create a service account on the K8S cluster, for use with Tiller
**(Note: This gives admin privileges to the tiller account - use only in DEV environments.
See: https://docs.helm.sh/using_helm/#role-based-access-control)**
```
$ kubectl create serviceaccount --namespace kube-system tiller
$ kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
```

# Create a Storace Class with automatic AWS EBS storage provisioner (Note: Might already be created automatically)
```
$ cd ~/tf-aws-eks-helm-mariadb/storage
$ terraform init
$ terraform apply
```

#### > Set as default storage class (workaround for TF K8S provider's inability to do so) (Note: Might already be set automatically)
```
$ kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

#### > Install helm
```
$ curl -o helm-get.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get
$ chmod +x helm-get.sh
$ ./helm-get.sh -v latest
$ helm init --service-account tiller --wait
```

#### > Use the TF Helm provider
```
cd ~/tf-aws-eks-helm-mariadb/helm
terraform init
terraform plan
terraform apply
```

#### > Cleanup
```
cd ~/tf-aws-eks-helm-mariadb/eks-getting-started
terraform destroy
(optional) makes sure there are no resources left in AWS
```
