resource "aws_iot_policy" "policy" {
  name = local.workspace["policy_name"]

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iot:*",
        ]
        Effect   = "Allow"
        Resource = [
                "*"
            ]
      },
    ]
  })
}

resource "aws_iot_policy_attachment" "att" {
  policy = aws_iot_policy.policy.name
  target = aws_iot_certificate.cert.arn
}

resource "aws_iot_certificate" "cert" {
  active = true
}

resource "aws_iot_thing_principal_attachment" "att" {
  principal = aws_iot_certificate.cert.arn
  thing     = aws_iot_thing.esp.name
}

resource "aws_iot_thing" "esp" {
    name = local.workspace["thing_name"]
}

resource "aws_iam_role" "role" {
  name = local.workspace["iam_role_name"]
  assume_role_policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[{
      "Effect": "Allow",
      "Principal": {
        "Service": "iot.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
  }]
}
EOF
}

resource "aws_iot_role_alias" "alias" {
  alias    = "IOT-dynamodb-access-role-alias"
  role_arn = aws_iam_role.role.arn
}

resource "aws_iot_topic_rule" "rule" {
  name        = "publishValues"
  description = "publish the values."
  enabled     = true
  sql         = "SELECT * FROM 'topic/esp0001'"
  sql_version = "2016-03-23"

  # sns {
  #   message_format = "RAW"
  #   role_arn       = aws_iam_role.role.arn
  #   target_arn     = aws_sns_topic.mytopic.arn
  # }

  # error_action {
  #   sns {
  #     message_format = "RAW"
  #     role_arn       = aws_iam_role.role.arn
  #     target_arn     = aws_sns_topic.myerrortopic.arn
  #   }
  # }
}

# resource "aws_sns_topic" "mytopic" {
#   name = "mytopic"
#   tags = {
#       repository = "hamer/iot"
#       workspace  = terraform.workspace
#     }
# }

# resource "aws_sns_topic" "myerrortopic" {
#   name = "myerrortopic"
#   tags = {
#       repository = "hamer/iot"
#       workspace  = terraform.workspace
#     }
# }

# resource "aws_iam_role_policy" "iam_policy_for_lambda" {
#   name = "mypolicy"
#   role = aws_iam_role.role.id

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#         "Effect": "Allow",
#         "Action": [
#             "sns:Publish"
#         ],
#         "Resource": "${aws_sns_topic.mytopic.arn}"
#     }
#   ]
# }
# EOF
# }