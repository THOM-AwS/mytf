locals {
  env = {
    prod = {
      aws_profile      = "hamer"
      aws_region       = "ap-southeast-2"
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
      network_acls = {
        default_inbound = [
          {
            rule_number = 900
            rule_action = "allow"
            from_port   = 1024
            to_port     = 65535
            protocol    = "tcp"
            cidr_block  = "0.0.0.0/0"
          },
          {
            rule_number = 901
            rule_action = "allow"
            from_port   = 1024
            to_port     = 65535
            protocol    = "udp"
            cidr_block  = "0.0.0.0/0"
          },
          {
            rule_number = 99 # allow ICMP in
            rule_action = "allow"
            icmp_type   = "-1"
            icmp_code   = "-1"
            protocol    = "1"
            cidr_block  = "10.10.0.0/16"
          },
        ]
        default_outbound = [
          {
            rule_number = 900
            rule_action = "allow"
            from_port   = 1024
            to_port     = 65535
            protocol    = "tcp"
            cidr_block  = "0.0.0.0/0"
          },
          {
            rule_number = 900
            rule_action = "allow"
            from_port   = 1024
            to_port     = 65535
            protocol    = "udp"
            cidr_block  = "0.0.0.0/0"
          },
          {
            rule_number = 99 # allow ICMP out
            rule_action = "allow"
            icmp_type   = "-1"
            icmp_code   = "-1"
            protocol    = "1"
            cidr_block  = "10.10.0.0/16"
          },
        ]
        public_inbound = [
          {
            rule_number = 100
            rule_action = "allow"
            protocol    = "-1"
            cidr_block  = "0.0.0.0/0"
          },
          {
            rule_number = 101
            rule_action = "allow"
            protocol    = "-1"
            cidr_block  = "10.10.0.0/21"
          },
        ]
        public_outbound = [
          {
            rule_number = 100
            rule_action = "allow"
            protocol    = "-1"
            cidr_block  = "0.0.0.0/0"
          },
          {
            rule_number = 101
            rule_action = "allow"
            protocol    = "-1"
            cidr_block  = "10.10.0.0/21"
          },
        ]
        private_inbound = [
          {
            rule_number = 100
            rule_action = "allow"
            protocol    = "-1"
            cidr_block  = "10.10.0.0/20"
          },
        ]
        private_outbound = [
          {
            rule_number = 100
            rule_action = "allow"
            protocol    = "-1"
            cidr_block  = "10.10.0.0/20"
          },
        ]
        intra_inbound = [
          #isolated
        ]
        intra_outbound = [
          #isolated
        ]
        db_inbound = [
          {
            rule_number = 100 # SQL
            rule_action = "allow"
            from_port   = 1433
            to_port     = 1434
            protocol    = "tcp"
            cidr_block  = "10.10.4.0/22"
          },
          {
            rule_number = 101 # mySQL
            rule_action = "allow"
            from_port   = 3306
            to_port     = 3306
            protocol    = "tcp"
            cidr_block  = "10.10.4.0/22"
          },
          {
            rule_number = 102 #postgresql
            rule_action = "allow"
            from_port   = 5432
            to_port     = 5432
            protocol    = "tcp"
            cidr_block  = "10.10.4.0/22"
          },
          {
            rule_number = 103 # Oracle
            rule_action = "allow"
            from_port   = 1521
            to_port     = 1521
            protocol    = "tcp"
            cidr_block  = "10.10.4.0/22"
          },
          {
            rule_number = 104 # Oracle
            rule_action = "allow"
            from_port   = 1830
            to_port     = 1830
            protocol    = "tcp"
            cidr_block  = "10.10.4.0/22"
          }
        ]
        db_outbound = [
          {
            rule_number = 100 # SQL
            rule_action = "allow"
            from_port   = 1433
            to_port     = 1434
            protocol    = "tcp"
            cidr_block  = "10.10.4.0/22"
          },
          {
            rule_number = 101 # mySQL
            rule_action = "allow"
            from_port   = 3306
            to_port     = 3306
            protocol    = "tcp"
            cidr_block  = "10.10.4.0/22"
          },
          {
            rule_number = 102 #postgresql
            rule_action = "allow"
            from_port   = 5432
            to_port     = 5432
            protocol    = "tcp"
            cidr_block  = "10.10.4.0/22"
          },
          {
            rule_number = 103 # Oracle
            rule_action = "allow"
            from_port   = 1521
            to_port     = 1521
            protocol    = "tcp"
            cidr_block  = "10.10.4.0/22"
          },
          {
            rule_number = 104 # Oracle
            rule_action = "allow"
            from_port   = 1830
            to_port     = 1830
            protocol    = "tcp"
            cidr_block  = "10.10.4.0/22"
          }
        ]
      }
    }
  }
  workspace = local.env[terraform.workspace]
}
