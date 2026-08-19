# CloudWatch monitoring. EC2 publishes CPUUtilization to the AWS/EC2 namespace
# automatically (basic, 5-minute), so no agent is needed for CPU. This alarm
# gives us something concrete to screenshot and fires if CPU stays high.
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "dream-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "CPU above 70% for 10 minutes on the Dream Vacation EC2 box"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.dream.id
  }

  tags = {
    Name = "dream-ec2-cpu-high"
  }
}
