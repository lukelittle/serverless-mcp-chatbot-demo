output "frontend_website_url" {
  description = "S3 website URL for the frontend"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "frontend_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = aws_s3_bucket.frontend.id
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "api_chat_url" {
  description = "Full chat endpoint URL"
  value       = "${aws_apigatewayv2_api.main.api_endpoint}/chat"
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.main.id
}

output "cognito_user_pool_endpoint" {
  description = "Cognito User Pool endpoint"
  value       = aws_cognito_user_pool.main.endpoint
}

output "data_bucket_name" {
  description = "S3 bucket name for data"
  value       = aws_s3_bucket.data.id
}

output "allowed_email_domain" {
  description = "Email domain restriction (CHANGE THIS FOR YOUR USE!)"
  value       = var.allowed_email_domain
}

output "deployment_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "next_steps" {
  description = "Next steps after terraform apply"
  value       = <<-EOT
    
    ✅ Infrastructure deployed successfully!
    
    Next steps:
    1. Build Lambda: cd lambda && ./build.sh
    2. Update frontend: Edit frontend/index.html with these values:
       - API URL: ${aws_apigatewayv2_api.main.api_endpoint}/chat
       - User Pool ID: ${aws_cognito_user_pool.main.id}
       - Client ID: ${aws_cognito_user_pool_client.main.id}
       - Region: ${var.aws_region}
    3. Upload frontend: aws s3 cp frontend/index.html s3://${aws_s3_bucket.frontend.id}/
    4. Visit: http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}
    
    ⚠️  IMPORTANT: This demo restricts signups to @${var.allowed_email_domain} emails!
        To change this, edit variables.tf and update lambda/cognito_trigger.py
  EOT
}
