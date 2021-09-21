locals {
  aws_profile = "hamer"
  aws_region  = "ap-southeast-2"
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
        cidr_block  = "0.0.0.0/0"
      },
    ]
    default_outbound = [
      {
        rule_number = 900
        rule_action = "allow"
        from_port   = 32768
        to_port     = 65535
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 99 # allow ICMP out
        rule_action = "allow"
        icmp_type   = "-1"
        icmp_code   = "-1"
        protocol    = "1"
        cidr_block  = "0.0.0.0/0"
      },
    ]
    public_inbound = [
      {
        rule_number = 100
        rule_action = "allow"
        protocol    = "-1"
        cidr_block  = "0.0.0.0/0"
      },
    ]
    public_outbound = [
      {
        rule_number = 100
        rule_action = "allow"
        protocol    = "-1"
        cidr_block  = "0.0.0.0/0"
      },
    ]
    private_inbound = [
      {
        rule_number = 100
        rule_action = "allow"
        protocol    = "-1"
        cidr_block  = "0.0.0.0/0"
      },
    ]
    private_outbound = [
      {
        rule_number = 100
        rule_action = "allow"
        protocol    = "-1"
        cidr_block  = "0.0.0.0/0"
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