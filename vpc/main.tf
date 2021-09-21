
module "thomas-vpc" {
  #region  = "ap=southeast-2"
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.66.0"

  name             = "Thomas-vpc"
  cidr             = "10.10.0.0/16"
  azs              = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  public_subnets   = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
  private_subnets  = ["10.10.4.0/24", "10.10.5.0/24", "10.10.6.0/24"]
  database_subnets = ["10.10.8.0/24", "10.10.9.0/24", "10.10.10.0/24"]
  #intra_subnets         = ["10.10.12.0/24", "10.10.13.0/24", "10.10.14.0/24"]
  enable_nat_gateway                     = false
  reuse_nat_ips                          = false 
  single_nat_gateway                     = false 
  one_nat_gateway_per_az                 = false
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = false
  enable_dns_hostnames                   = true
  enable_dns_support                     = true
  enable_ssm_endpoint                    = false
  public_dedicated_network_acl           = true
  private_dedicated_network_acl          = true
  database_dedicated_network_acl         = true
  intra_dedicated_network_acl            = false
  manage_default_network_acl             = true

  public_inbound_acl_rules = concat(
    local.network_acls["default_inbound"],
    local.network_acls["public_inbound"],
  )
  public_outbound_acl_rules = concat(
    local.network_acls["default_outbound"],
    local.network_acls["public_outbound"],
  )
  private_inbound_acl_rules = concat(
    local.network_acls["default_inbound"],
    local.network_acls["private_inbound"],
  )
  private_outbound_acl_rules = concat(
    local.network_acls["default_outbound"],
    local.network_acls["private_outbound"],
  )
  intra_inbound_acl_rules = concat(
    local.network_acls["intra_inbound"],
  )
  intra_outbound_acl_rules = concat(
    local.network_acls["intra_outbound"],
  )
  database_inbound_acl_rules = concat(
    local.network_acls["db_inbound"],
  )
  database_outbound_acl_rules = concat(
    local.network_acls["db_outbound"],
  )

  tags = {
    Environment = "prod"
    managed-by   = "Terraform"
  }
}

