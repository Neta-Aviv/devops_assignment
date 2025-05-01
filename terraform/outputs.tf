output "sqs_queue_url" {
  value = aws_sqs_queue.messages.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.storage.bucket
}

output "ssm_parameter_name" {
  value = aws_ssm_parameter.api_token.name
}

output "alb_dns_name" {
  value = aws_lb.api_alb.dns_name
}
