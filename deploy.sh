#!/bin/bash
set -e

echo "🚀 Serverless MCP Chatbot Demo - Deployment Script"
echo "=================================================="
echo ""

# Check prerequisites
echo "✓ Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install it first."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install it first."
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install it first."
    exit 1
fi

echo "✓ Prerequisites OK"
echo ""

# Step 1: Build Lambda
echo "📦 Step 1: Building Lambda package..."
cd lambda
./build.sh
cd ..
echo "✓ Lambda package built"
echo ""

# Step 2: Terraform Apply
echo "🏗️  Step 2: Deploying infrastructure with Terraform..."
cd infra/terraform
terraform init
terraform apply

# Get outputs
API_URL=$(terraform output -raw api_chat_url)
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)
CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id)
REGION=$(terraform output -raw deployment_region)
BUCKET_NAME=$(terraform output -raw frontend_bucket_name)
WEBSITE_URL=$(terraform output -raw frontend_website_url)

cd ../..

echo "✓ Infrastructure deployed"
echo ""

# Step 3: Update Frontend
echo "🌐 Step 3: Updating frontend configuration..."

# Create a temporary updated index.html
sed "s|API_URL: 'YOUR_API_URL_HERE/chat'|API_URL: '$API_URL'|g" frontend/index.html | \
sed "s|USER_POOL_ID: 'YOUR_USER_POOL_ID'|USER_POOL_ID: '$USER_POOL_ID'|g" | \
sed "s|CLIENT_ID: 'YOUR_CLIENT_ID'|CLIENT_ID: '$CLIENT_ID'|g" | \
sed "s|REGION: 'us-east-1'|REGION: '$REGION'|g" > frontend/index.html.tmp

mv frontend/index.html.tmp frontend/index.html

echo "✓ Frontend configuration updated"
echo ""

# Step 4: Upload Frontend
echo "📤 Step 4: Uploading frontend to S3..."
aws s3 cp frontend/index.html s3://$BUCKET_NAME/

echo "✓ Frontend uploaded"
echo ""

# Done!
echo "=================================================="
echo "✅ Deployment Complete!"
echo "=================================================="
echo ""
echo "🌐 Website URL: $WEBSITE_URL"
echo ""
echo "⚠️  IMPORTANT: This demo restricts signups to @lukelittle.com"
echo "   To change this, update variables.tf and lambda/cognito_trigger.py"
echo ""
echo "🎵 Try these prompts:"
echo "   - What Grimes albums do I own?"
echo "   - Show me vinyl from 4AD label"
echo "   - What records did I add in 2024?"
echo ""
echo "Happy demoing! 🚀"
