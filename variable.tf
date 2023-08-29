
variable "region" {
  type = string
}

variable "allowed_account_ids" {
  type = list(string)
}

variable "default_tags" {
  type = map(string)
}

variable "zone_name" {
  type = string
}

variable "ses_domain_identity" {
  type = string
}

variable "ses_email_identities" {
  type = list(string)
}

variable "allow_recipients" {
  type = list(string)
}
