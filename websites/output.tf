output "bucket_id" {
  description = "The name of the bucket"
  value       = module.aws-static-website.bucket_id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = module.aws-static-website.bucket_arn
}

output "user_details" {
  description = "User Name"
  value       = module.aws-static-website.user_details
}

output "user_acces_key" {
  description = "Access Key"
  value       = module.aws-static-website.user_acces_key
}

output "user_secret_access_key" {
  description = "Secret Access Key"
  sensitive   = true
  value       = module.aws-static-website.user_secret_access_key
}

output "cloudfront_distribution_id" {
  description = "distribution id for invalidation cloudfront on push from github actions"
  value       = module.aws-static-website.cloudfront_distribution_id
}

output "api_gateway_endpoint" {
  value = aws_api_gateway_deployment.deploy_api.invoke_url
}
