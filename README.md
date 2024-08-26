# eks-terraform-module
### code
eks 생성을 위한 terraform code

### folder
main.tf -> main code

### module
GitOps_vpc
GitOps_eks 

### version
AWS provider >= 5.26.0
kubernetes >= 2.24.0
eks Cluster 1.28
EKS module 19.21.0

### spec
t3.medium

### cluster addon
coredns
kube-proxy
vpc-cn

### command
```
terraform init
terraform plan
terraform apply
```
