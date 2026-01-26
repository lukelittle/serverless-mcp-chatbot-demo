# Lambda Functions

This directory contains the Lambda functions for the Serverless MCP Chatbot Demo.

## Files

- **handler.py** - Main chat Lambda function that uses Bedrock with tool use
- **cognito_trigger.py** - Pre-signup trigger that restricts email domains
- **requirements.txt** - Python dependencies
- **build.sh** - Build script to create deployment package

## Building the Lambda Package

```bash
cd lambda
./build.sh
```

This will create `lambda.zip` with all dependencies bundled for ARM64 architecture.

## How It Works

### Main Handler (handler.py)

1. Receives chat message from API Gateway
2. Invokes Bedrock Converse API with tool definition
3. If Bedrock decides to use the tool, executes `query_vinyl_collection`
4. Returns response with `tool_used` flag

### Tool: query_vinyl_collection

- Reads `discogs.csv` from S3
- Parses CSV and filters by query type (artist, label, year, title, all)
- Returns formatted results
- Demonstrates MCP-like tool behavior without a separate server

### Cognito Trigger (cognito_trigger.py)

- Validates email domain during signup
- Auto-confirms users (for demo purposes)
- **⚠️ IMPORTANT**: Restricts to `@lukelittle.com` - change this for your use!

## Environment Variables

Set in Terraform:

- `PROJECT_TAG` - Project identifier
- `DATA_BUCKET` - S3 bucket containing discogs.csv
- `DATA_KEY` - S3 key for CSV file
- `BEDROCK_MODEL_ID` - Bedrock model to use
- `FRONTEND_ORIGIN` - CORS origin
- `ALLOWED_EMAIL_DOMAIN` - Email domain restriction (cognito_trigger only)

## Testing Locally

You can test the handler locally:

```python
import handler
import json

event = {
    'body': json.dumps({'message': 'What Grimes records do I have?'})
}

result = handler.lambda_handler(event, None)
print(result)
```

Make sure AWS credentials are configured and environment variables are set.
