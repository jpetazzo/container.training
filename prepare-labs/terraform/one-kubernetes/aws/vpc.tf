# OK, we have two options here.
# 1. Create our own VPC
#    - Pros: provides good isolation from other stuff deployed in the
#            AWS account; makes sure that we don't interact with
#            existing security groups, subnets, etc.
#    - Cons: by default, there is a quota of 5 VPC per region, so
#            we can only deploy 5 clusters
# 2. Use the default VPC
#    - Pros/cons: the opposite :)

variable "use_default_vpc" {
  type    = bool
  default = true
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_availability_zones" "available" {}

module "vpc" {
  count   = var.use_default_vpc ? 0 : 1
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = var.cluster_name

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  public_subnets  = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  enable_nat_gateway      = true
  single_nat_gateway      = true
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }
}

locals {
  vpc_id     = var.use_default_vpc ? data.aws_vpc.default.id : module.vpc[0].vpc_id
  subnet_ids = var.use_default_vpc ? data.aws_subnets.default.ids : module.vpc[0].public_subnets
}
