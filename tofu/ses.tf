variable "aws_access_key_id" {
  description = "AWS API key for tofu itself. Set via TF_VAR_aws_access_key_id from tofu_env.age."
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS API secret for tofu itself. Set via TF_VAR_aws_secret_access_key from tofu_env.age."
  type        = string
  sensitive   = true
}

locals {
  ses_domain = "estrogenuinely.ca"
}

# Outbound relay for Stalwart on bergamot (docs/Stalwart.md). Recreating the
# identity issues new DKIM tokens and breaks signing until the CNAMEs in
# dns.tf are updated, so it is protected from destroy.
resource "aws_sesv2_configuration_set" "mail" {
  configuration_set_name = "my-first-configuration-set"
}

resource "aws_sesv2_email_identity" "mail" {
  email_identity         = local.ses_domain
  configuration_set_name = aws_sesv2_configuration_set.mail.configuration_set_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_sesv2_email_identity_mail_from_attributes" "mail" {
  email_identity         = aws_sesv2_email_identity.mail.email_identity
  mail_from_domain       = "bounce.${local.ses_domain}"
  behavior_on_mx_failure = "REJECT_MESSAGE"
}

import {
  to = aws_sesv2_configuration_set.mail
  id = "my-first-configuration-set"
}

import {
  to = aws_sesv2_email_identity.mail
  id = local.ses_domain
}

import {
  to = aws_sesv2_email_identity_mail_from_attributes.mail
  id = local.ses_domain
}

# The DKIM CNAMEs are plain records in dns.tf. Fail the plan if they no
# longer match what SES expects.
check "ses_dkim_records" {
  assert {
    condition = alltrue([
      for t in aws_sesv2_email_identity.mail.dkim_signing_attributes[0].tokens :
      contains(keys(local.dns_records), "${local.ses_domain}/${t}._domainkey/CNAME")
    ])
    error_message = "dns.tf is missing a DKIM CNAME for one of the SES identity's tokens."
  }
}

# SMTP credentials for Stalwart and the satsuma-watcher on bergamot. The SMTP
# username is the access key ID and the password is derived from the secret
# for the provider's region, so the key must be created by tofu (an imported
# key has no secret). Rotate with
#   tofu apply -replace=aws_iam_access_key.mail
resource "aws_iam_user" "mail" {
  name = "mail.${local.ses_domain}"
}

resource "aws_iam_user_policy" "mail" {
  name = "ses-send"
  user = aws_iam_user.mail.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "ses:SendRawEmail"
      # SES also authorizes the identity's default configuration set.
      Resource = [
        aws_sesv2_email_identity.mail.arn,
        aws_sesv2_configuration_set.mail.arn,
      ]
    }]
  })
}

resource "aws_iam_access_key" "mail" {
  user = aws_iam_user.mail.name
}
