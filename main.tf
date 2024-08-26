terraform {
  required_version = ">= 1.0" # Terraform 최소 버전 요구사항
  required_providers {
    aws = {
      source  = "hashicorp/aws" # AWS provider 설정
      version = ">=5.26.0" # AWS provider 최소 버전 요구사항
    }
    kubernetes = {
      source  = "hashicorp/kubernetes" # Kubernetes provider 설정
      version = ">= 2.24.0" # Kubernetes provider 최소 버전 요구사항
    }
  }
}
 
provider "aws" {} # AWS provider 초기화
provider "kubernetes" {
  host                   = module.GitOps_eks.cluster_endpoint # EKS 클러스터 엔드포인트
  cluster_ca_certificate = base64decode(module.GitOps_eks.cluster_certificate_authority_data) # EKS 클러스터 인증서 데이터
 
  exec {
    api_version = "client.authentication.k8s.io/v1beta1" # Kubernetes API 버전
    command     = "aws" # AWS CLI 사용
    args        = ["eks", "get-token", "--cluster-name", module.GitOps_eks.cluster_name] # EKS 토큰 가져오기 위한 명령어
  }
}
 
module "GitOps_vpc" {
  source = "terraform-aws-modules/vpc/aws" # VPC 모듈 소스
  name   = "GitOps-vpc" # VPC 이름
  cidr   = "10.0.0.0/16" # VPC CIDR 블록
 
  azs             = ["ap-northeast-2a", "ap-northeast-2c"] # 가용 영역
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"] # 퍼블릭 서브넷
  private_subnets = ["10.0.201.0/24", "10.0.202.0/24"] # 프라이빗 서브넷
 
  enable_nat_gateway = true # NAT 게이트웨이 활성화
  single_nat_gateway = true # 단일 NAT 게이트웨이 사용
 
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1 # 퍼블릭 서브넷 태그 (ELB 역할)
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1 # 프라이빗 서브넷 태그 (Internal ELB 역할)
  }
}
 
locals {
  cluster_name    = "GitOps-cluster" # 클러스터 이름
  cluster_version = "1.28" # 클러스터 버전
}
 
data "aws_ami" "GitOps_eks_ami" {
  most_recent = true # 최신 AMI 사용
  owners      = ["amazon"] # AMI 소유자
 
  filter {
    name   = "name" # AMI 이름 필터
    values = ["amazon-eks-node-${local.cluster_version}-v*"] # EKS AMI 버전 필터
  }
}
 
module "GitOps_eks" {
  source = "terraform-aws-modules/eks/aws" # EKS 모듈 소스
  version = "19.21.0" # EKS 모듈 버전
 
  cluster_name    = local.cluster_name # 클러스터 이름
  cluster_version = local.cluster_version # 클러스터 버전
 
  cluster_endpoint_private_access = true # 프라이빗 액세스 활성화
  cluster_endpoint_public_access  = true # 퍼블릭 액세스 활성화
 
  cluster_encryption_config = {} # 클러스터 암호화 설정
 
  cluster_addons = {
    coredns = {
      most_recent = true # CoreDNS 최신 버전 사용
    }
    kube-proxy = {
      most_recent = true # kube-proxy 최신 버전 사용
    }
    vpc-cni = {
      most_recent = true # VPC CNI 최신 버전 사용
    }
  }
 
  vpc_id     = module.GitOps_vpc.vpc_id # VPC ID
  subnet_ids = module.GitOps_vpc.private_subnets # 서브넷 ID
 
  manage_aws_auth_configmap = true # AWS Auth ConfigMap 관리
 
  eks_managed_node_groups = {
    GitOps = {
      name            = "GitOps-ng" # 노드 그룹 이름
      use_name_prefix = true # 이름 접두사 사용
 
      subnet_ids = module.GitOps_vpc.private_subnets # 노드 그룹 서브넷 ID
 
      min_size     = 1 # 최소 노드 수
      max_size     = 2 # 최대 노드 수
      desired_size = 1 # 원하는 노드 수
 
      ami_id                     = data.aws_ami.GitOps_eks_ami.id # AMI ID
      enable_bootstrap_user_data = true # 부트스트랩 사용자 데이터 활성화
 
      capacity_type  = "ON_DEMAND" # 용량 유형 (온디맨드)
      instance_types = ["t3.medium"] # 인스턴스 타입
 
      create_iam_role          = true # IAM 역할 생성
      iam_role_name            = "GitOps-ng-role" # IAM 역할 이름
      iam_role_use_name_prefix = true # IAM 역할 이름 접두사 사용
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" # 추가 IAM 정책
      }
    }
  }
}

