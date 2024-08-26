# eks-terraform-module
## eks 생성을 위한 terraform code

### Module
GitOps_vpc
GitOps_eks 

### Version
AWS provider >= 5.26.0 <br/>
kubernetes >= 2.24.0  <br/>
eks Cluster 1.28  <br/>
EKS module 19.21.0  <br/>

### Spec
t3.medium

### Cluster Addon
coredns
kube-proxy
vpc-cn

### Command
main.tf
```
terraform init
terraform plan
terraform apply
```

### Reference
https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
