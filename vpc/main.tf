
module "thomas-vpc" {
  #region  = "ap=southeast-2"
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.66.0"

  name             = local.workspace["name"]
  cidr             = local.workspace["cidr"]
  azs              = local.workspace["azs"]
  public_subnets   = local.workspace["public_subnets"]
  private_subnets  = local.workspace["private_subnets"]
  database_subnets = local.workspace["database_subnets"]
  #intra_subnets         = local.workspace["intra_subnets"]
  enable_nat_gateway                     = local.workspace["enable_nat_gateway"]
  reuse_nat_ips                          = local.workspace["reuse_nat_ips"]
  single_nat_gateway                     = local.workspace["single_nat_gateway"]
  one_nat_gateway_per_az                 = local.workspace["one_nat_gateway_per_az"]
  create_database_subnet_group           = local.workspace["create_database_subnet_group"]
  create_database_subnet_route_table     = local.workspace["create_database_subnet_route_table"]
  create_database_internet_gateway_route = local.workspace["create_database_internet_gateway_route"]
  enable_dns_hostnames                   = local.workspace["enable_dns_hostnames"]
  enable_dns_support                     = local.workspace["enable_dns_support"]
  enable_ssm_endpoint                    = local.workspace["enable_ssm_endpoint"]
  public_dedicated_network_acl           = local.workspace["public_dedicated_network_acl"]
  private_dedicated_network_acl          = local.workspace["private_dedicated_network_acl"]
  database_dedicated_network_acl         = local.workspace["database_dedicated_network_acl"]
  intra_dedicated_network_acl            = local.workspace["intra_dedicated_network_acl"]
  manage_default_network_acl             = local.workspace["manage_default_network_acl"]

  public_inbound_acl_rules = concat(
    local.workspace.network_acls["default_inbound"],
    local.workspace.network_acls["public_inbound"],
  )
  public_outbound_acl_rules = concat(
    local.workspace.network_acls["default_outbound"],
    local.workspace.network_acls["public_outbound"],
  )
  private_inbound_acl_rules = concat(
    local.workspace.network_acls["default_inbound"],
    local.workspace.network_acls["private_inbound"],
  )
  private_outbound_acl_rules = concat(
    local.workspace.network_acls["default_outbound"],
    local.workspace.network_acls["private_outbound"],
  )
  intra_inbound_acl_rules = concat(
    local.workspace.network_acls["intra_inbound"],
  )
  intra_outbound_acl_rules = concat(
    local.workspace.network_acls["intra_outbound"],
  )
  database_inbound_acl_rules = concat(
    local.workspace.network_acls["db_inbound"],
  )
  database_outbound_acl_rules = concat(
    local.workspace.network_acls["db_outbound"],
  )

  tags = {
    Environment = "prod"
    managed-by  = "Terraform"
  }
}

