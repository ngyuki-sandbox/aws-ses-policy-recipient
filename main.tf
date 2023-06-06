
provider "aws" {
  region = "ap-northeast-1"
}

variable "domain" {
  type = string
}

variable "recipients" {
  type = list(string)
}

variable "ses_identities" {
  type = list(string)
}

data "aws_caller_identity" "this" {}

data "aws_ses_domain_identity" "this" {
  domain = var.domain
}

# IAM ポリシーで全許可するなら承認ポリシーで宛先を元に拒否を設定する
resource "aws_ses_identity_policy" "example" {
  identity = data.aws_ses_domain_identity.this.arn
  name     = "example"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Deny",
        "Action" : ["ses:SendEmail", "ses:SendRawEmail"],
        "Resource" : data.aws_ses_domain_identity.this.arn,
        "Principal" : "*",
        "Condition" : {
          "ForAnyValue:StringNotLike" : {
            "ses:Recipients" : var.recipients
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "ses" {
  name = "ses"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "AWS" : data.aws_caller_identity.this.arn,
        },
      }
    ]
  })
}

# 承認ポリシーで制限しないならIAM ポリシーで宛先を元に許可する
resource "aws_iam_role_policy" "ses" {
  role = aws_iam_role.ses.name
  policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : ["ses:SendEmail", "ses:SendRawEmail"],
        "Resource" : var.ses_identities,
        "Condition" : {
          "ForAnyValue:StringLike" : {
            "ses:Recipients" : var.recipients
          }
        }
      }
    ]
  })
}

output "iam_role" {
  value = aws_iam_role.ses.arn
}

output "ses_identity" {
  value = data.aws_ses_domain_identity.this.arn
}
