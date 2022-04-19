module "cloudwatch_metric_alarms" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "3.1.0"

  for_each = try(local.aws_vars.cloudwatch, {})

  alarm_name          = "rocketpool-${local.pool}-${each.value.node_name}-${each.value.alarm_name}"
  alarm_description   = try(each.value.alarm_description, null)
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = try(each.value.metric_name, null)
  namespace           = try(each.value.namespace, null)
  period              = try(each.value.period, null)
  statistic           = try(each.value.statistic, null)
  threshold           = each.value.threshold
  unit                = try(each.value.unit, null)

  alarm_actions = try([module.notify_slack.this_slack_topic_arn], [])
  ok_actions    = try([module.notify_slack.this_slack_topic_arn], [])

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.node.name
  }
}
