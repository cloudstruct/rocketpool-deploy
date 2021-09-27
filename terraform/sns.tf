module "notify_slack" {
  count   = try(length(keys(local.aws_vars.sns)), 0) > 0 ? 1 : 0
  source  = "terraform-aws-modules/notify-slack/aws"
  version = "4.17.0"

  sns_topic_name = try(local.aws_vars.sns.slack.topic_name, null)

  slack_webhook_url = try(local.aws_vars.sns.slack.webhook, null)
  slack_channel     = try(local.aws_vars.sns.slack.channel, null)
  slack_username    = "CloudWatch"

}
