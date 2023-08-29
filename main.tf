

data "aws_caller_identity" "this" {}

data "aws_route53_zone" "this" {
  name = var.zone_name
}

resource "aws_ses_domain_identity" "this" {
  domain = var.ses_domain_identity
}

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

resource "aws_route53_record" "this" {
  count   = 3
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${aws_ses_domain_dkim.this.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.this.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_ses_email_identity" "this" {
  for_each = toset(var.ses_email_identities)
  email    = each.value
}

# IAM ポリシーで全許可するなら承認ポリシーで宛先を元に拒否を設定する
resource "aws_ses_identity_policy" "example" {
  identity = aws_ses_domain_identity.this.arn
  name     = "example"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Deny",
        "Action" : ["ses:SendEmail", "ses:SendRawEmail"],
        "Resource" : aws_ses_domain_identity.this.arn,
        "Principal" : "*",
        "Condition" : {
          "ForAnyValue:StringNotLike" : {
            "ses:Recipients" : var.allow_recipients
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
        "Resource" : [aws_ses_domain_identity.this.arn],
        "Condition" : {
          "ForAllValues:StringLike" : {
            "ses:Recipients" : var.allow_recipients
          }
        }
      }
    ]
  })
}

output "iam_role" {
  value = aws_iam_role.ses.arn
}
