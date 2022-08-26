module "notify_slack" {
  count   = try(length(keys(local.aws_vars.sns)), 0) > 0 ? 1 : 0
  source  = "terraform-aws-modules/notify-slack/aws"
  version = "5.3.0"

  lambda_function_name = "cloudstruct_rocketpool_${local.pool}_notify_slack"
  sns_topic_name       = try(local.aws_vars.sns.slack.topic_name, null)

  slack_webhook_url = try(local.aws_vars.sns.slack.webhook, null)
  slack_channel     = try(local.aws_vars.sns.slack.channel, null)
  slack_username    = "CloudWatch-${local.pool}"

}
