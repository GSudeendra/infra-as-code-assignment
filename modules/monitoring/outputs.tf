output "log_group_names" {
  description = "Names of the CloudWatch log groups"
  value       = [for log_group in aws_cloudwatch_log_group.lambda_logs : log_group.name]
}

output "lambda_error_alarm_names" {
  description = "Names of Lambda error alarms"
  value       = [for alarm in aws_cloudwatch_metric_alarm.lambda_errors : alarm.alarm_name]
}

output "lambda_duration_alarm_names" {
  description = "Names of Lambda duration alarms"
  value       = [for alarm in aws_cloudwatch_metric_alarm.lambda_duration : alarm.alarm_name]
}

output "api_gateway_5xx_alarm_name" {
  description = "Name of API Gateway 5XX error alarm"
  value       = var.create_api_gateway_alarms ? aws_cloudwatch_metric_alarm.api_gateway_5xx_errors[0].alarm_name : null
}

output "api_gateway_4xx_alarm_name" {
  description = "Name of API Gateway 4XX error alarm"
  value       = var.create_api_gateway_alarms ? aws_cloudwatch_metric_alarm.api_gateway_4xx_errors[0].alarm_name : null
} 