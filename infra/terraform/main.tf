# ============================================================================
# S3 BUCKETS
# ============================================================================

# Frontend hosting bucket
resource "aws_s3_bucket" "frontend" {
  bucket_prefix = "${var.project_name}-frontend-"
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

# Data bucket for discogs.csv
resource "aws_s3_bucket" "data" {
  bucket_prefix = "${var.project_name}-data-"
}

resource "aws_s3_object" "discogs_csv" {
  bucket = aws_s3_bucket.data.id
  key    = "discogs.csv"
  source = "${path.module}/../../data/discogs.csv"
  etag   = filemd5("${path.module}/../../data/discogs.csv")
}

# ============================================================================
# COGNITO USER POOL
# ============================================================================

resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-user-pool"

  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  lambda_config {
    pre_sign_up = aws_lambda_function.cognito_presignup.arn
  }

  tags = {
    Name = "${var.project_name}-user-pool"
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = false
  
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
}

# ============================================================================
# COGNITO PRE-SIGNUP LAMBDA TRIGGER
# ============================================================================

data "archive_file" "cognito_presignup_lambda" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/cognito_trigger.py"
  output_path = "${path.module}/../../lambda/cognito_trigger.zip"
}

resource "aws_lambda_function" "cognito_presignup" {
  filename         = data.archive_file.cognito_presignup_lambda.output_path
  function_name    = "${var.project_name}-cognito-presignup"
  role             = aws_iam_role.cognito_presignup_lambda.arn
  handler          = "cognito_trigger.lambda_handler"
  source_code_hash = data.archive_file.cognito_presignup_lambda.output_base64sha256
  runtime          = var.lambda_runtime
  architecture     = var.lambda_architecture
  timeout          = 10

  environment {
    variables = {
      ALLOWED_EMAIL_DOMAIN = var.allowed_email_domain
      PROJECT_TAG          = var.project_name
    }
  }

  tags = {
    Name = "${var.project_name}-cognito-presignup"
  }
}

resource "aws_cloudwatch_log_group" "cognito_presignup_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.cognito_presignup.function_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-cognito-presignup-logs"
  }
}

resource "aws_iam_role" "cognito_presignup_lambda" {
  name = "${var.project_name}-cognito-presignup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-cognito-presignup-role"
  }
}

resource "aws_iam_role_policy_attachment" "cognito_presignup_lambda_basic" {
  role       = aws_iam_role.cognito_presignup_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "cognito_presignup" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_presignup.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

# ============================================================================
# MAIN CHAT LAMBDA FUNCTION
# ============================================================================

resource "aws_lambda_function" "chat" {
  filename         = "${path.module}/../../lambda/lambda.zip"
  function_name    = "${var.project_name}-chat"
  role             = aws_iam_role.chat_lambda.arn
  handler          = "handler.lambda_handler"
  source_code_hash = fileexists("${path.module}/../../lambda/lambda.zip") ? filebase64sha256("${path.module}/../../lambda/lambda.zip") : null
  runtime          = var.lambda_runtime
  architecture     = var.lambda_architecture
  timeout          = 60
  memory_size      = 512

  environment {
    variables = {
      PROJECT_TAG       = var.project_name
      DATA_BUCKET       = aws_s3_bucket.data.id
      DATA_KEY          = "discogs.csv"
      BEDROCK_MODEL_ID  = var.bedrock_model_id
      FRONTEND_ORIGIN   = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
    }
  }

  tags = {
    Name = "${var.project_name}-chat-lambda"
  }
  
  lifecycle {
    ignore_changes = [
      source_code_hash
    ]
  }
}

resource "aws_cloudwatch_log_group" "chat_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.chat.function_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-chat-lambda-logs"
  }
}

resource "aws_iam_role" "chat_lambda" {
  name = "${var.project_name}-chat-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-chat-lambda-role"
  }
}

resource "aws_iam_role_policy_attachment" "chat_lambda_basic" {
  role       = aws_iam_role.chat_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "chat_lambda_policy" {
  name = "${var.project_name}-chat-lambda-policy"
  role = aws_iam_role.chat_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.data.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/*"
      }
    ]
  })
}

# ============================================================================
# API GATEWAY HTTP API
# ============================================================================

resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [
      "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
    ]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }

  tags = {
    Name = "${var.project_name}-api"
  }
}

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.main.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
  }
}

resource "aws_apigatewayv2_integration" "chat" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.chat.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "chat" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /chat"
  target             = "integrations/${aws_apigatewayv2_integration.chat.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Name = "${var.project_name}-api-stage"
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
