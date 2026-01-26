# 🎵 Serverless MCP Chatbot Demo

A serverless chatbot demonstrating **agentic AI** behavior with tool use, built for AWS User Groups and university presentations. Ask about Luke's vinyl record collection and watch the bot intelligently decide when to query the data!

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?logo=amazon-aws&logoColor=white)
![Python](https://img.shields.io/badge/python-3.12+-blue.svg)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?logo=terraform&logoColor=white)

## 🎯 Purpose

This project demonstrates modern serverless AI patterns for:
- **AWS User Groups** - Show real-world serverless + AI architecture
- **University Students** - Learn cloud development with a fun, practical example
- **Technical Talks** - Live demo of agentic AI in under 5 minutes

### What Makes This "Agentic"?

Traditional chatbots always respond the same way. **Agentic AI** can:
1. **Decide** whether to use tools based on the question
2. **Execute** tools (like querying a database) automatically
3. **Synthesize** results into natural language responses

Try asking: *"What Grimes albums do I own?"* vs *"What is vinyl?"* - the bot only uses the tool when needed!

## ⚠️ IMPORTANT: Email Restriction

**This demo restricts authentication to `@lukelittle.com` email addresses!**

If you're using this code for your own demo, you **MUST** update:
1. `infra/terraform/variables.tf` - Change `allowed_email_domain` default value
2. `lambda/cognito_trigger.py` - Update the validation logic
3. `frontend/index.html` - Update the warning banner text

This restriction is intentional to demonstrate Cognito pre-signup triggers, but you need to customize it!

## 🏗️ Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   Browser   │─────▶│  Cognito     │      │   Lambda    │
│  (S3 HTML)  │      │  User Pool   │      │  (Python)   │
└─────────────┘      └──────────────┘      └─────────────┘
       │                     │                      │
       │                     ▼                      │
       │              [JWT Token]                   │
       │                     │                      │
       └────────────────────────────────────────────┘
                             │
                             ▼
                    ┌──────────────┐
                    │ API Gateway  │
                    │  (HTTP API)  │
                    └──────────────┘
                             │
                             ▼
                    ┌──────────────┐
                    │   Lambda     │
                    │   Handler    │
                    └──────────────┘
                             │
                    ┌────────┴────────┐
                    ▼                 ▼
            ┌──────────────┐   ┌──────────┐
            │   Bedrock    │   │    S3    │
            │   Claude     │   │  (CSV)   │
            │  (Tool Use)  │   │          │
            └──────────────┘   └──────────┘
```

### Flow Explanation (College Student Friendly!)

1. **Frontend (S3 Website)** - A simple HTML page with authentication
2. **Cognito** - AWS's user authentication service (like Firebase Auth)
3. **API Gateway** - The "front door" for your API (validates JWT tokens)
4. **Lambda** - Serverless functions that run your Python code (no servers!)
5. **Bedrock** - Amazon's AI service (uses Claude model with tool support)
6. **S3 CSV** - Your vinyl collection stored as a simple spreadsheet

### Why This Architecture?

- ✅ **No servers to manage** - Lambda scales automatically
- ✅ **Pay per use** - Only charged when someone uses it (~$0.05/month!)
- ✅ **Built-in auth** - Cognito handles signups/logins securely
- ✅ **AI-powered** - Bedrock provides state-of-the-art language models
- ✅ **Simple data** - CSV file instead of complex database

## 📁 Project Structure

```
serverless-mcp-chatbot-demo/
├── infra/terraform/          # Infrastructure as Code
│   ├── versions.tf           # Provider versions
│   ├── variables.tf          # Configurable values
│   ├── main.tf               # Main resources
│   └── outputs.tf            # Deployment info
├── lambda/                   # Python Lambda functions
│   ├── handler.py            # Main chat handler
│   ├── cognito_trigger.py    # Email validation
│   ├── requirements.txt      # Python dependencies
│   ├── build.sh              # Build script
│   └── README.md             # Lambda docs
├── frontend/                 # Web interface
│   └── index.html            # Single-page app
├── data/                     # Data files
│   └── discogs.csv           # Vinyl collection
├── .gitignore               # Git ignore rules
├── LICENSE                  # MIT License
└── README.md                # This file!
```

## 🚀 Quick Start

### Prerequisites

- **AWS Account** with CLI configured (`aws configure`)
- **Terraform** >= 1.0 ([Download](https://www.terraform.io/downloads))
- **Python 3.12+** ([Download](https://www.python.org/downloads/))
- **Bedrock Access** - Enable Claude 3.5 Sonnet in AWS Console

### Option A: Automated Deployment (Recommended)

Run the included deployment script that handles everything:

```bash
./deploy.sh
```

This script will:
1. Build the Lambda package
2. Deploy infrastructure with Terraform
3. Automatically configure the frontend with correct values
4. Upload the frontend to S3
5. Display your website URL

### Option B: Manual Deployment

If you prefer to run each step manually:

#### Step 1: Build Lambda Package

```bash
cd lambda
./build.sh
```

This creates `lambda.zip` with all dependencies for ARM64 architecture (cheaper Lambda!).

### Step 2: Deploy Infrastructure

```bash
cd infra/terraform
terraform init
terraform plan    # Review what will be created
terraform apply   # Type 'yes' to confirm
```

Terraform will create:
- 2 S3 buckets (frontend + data)
- Cognito User Pool + Client
- API Gateway HTTP API
- 2 Lambda functions
- IAM roles and policies
- CloudWatch log groups

**Important**: Save the output values! You'll need them for the frontend.

### Step 3: Configure Frontend

Edit `frontend/index.html` and update the `CONFIG` object (around line 370):

```javascript
const CONFIG = {
    API_URL: 'https://your-api-id.execute-api.us-east-1.amazonaws.com/chat',
    USER_POOL_ID: 'us-east-1_xxxxxxxxx',
    CLIENT_ID: 'xxxxxxxxxxxxxxxxxxxxxxxxxx',
    REGION: 'us-east-1'
};
```

Copy these values from `terraform output`.

### Step 4: Upload Frontend

```bash
# Get bucket name from terraform output
BUCKET_NAME=$(cd infra/terraform && terraform output -raw frontend_bucket_name)

# Upload HTML file
aws s3 cp frontend/index.html s3://$BUCKET_NAME/
```

### Step 5: Test It!

```bash
# Get website URL
cd infra/terraform
terraform output frontend_website_url
```

Visit the URL, sign up, and start chatting!

## 🎤 Demo Script (30 seconds)

> "This is a serverless chatbot that demonstrates agentic AI. When I ask about my vinyl collection, it doesn't just respond - it decides whether to query the data. Watch: [type "What Grimes records do I have?"] - see the green 'Tool Used' badge? The AI decided to call our tool, query the CSV from S3, and synthesize an answer. But if I ask [type "What is vinyl?"], it just answers from knowledge - no tool needed. All serverless, costs under a dollar a month, and shows real-world AI + AWS patterns."

## 💡 Understanding the Components

### 1. Cognito (Authentication)

**What it is**: AWS's managed authentication service  
**Why we use it**: Handles user signups, logins, and JWT tokens automatically  
**Student analogy**: Like the bouncer at a club - checks IDs before letting people in

**Key concept**: Pre-signup triggers let you validate emails before accounts are created!

### 2. API Gateway (HTTP API)

**What it is**: Managed API hosting service  
**Why we use it**: Routes HTTP requests to Lambda, validates JWT tokens  
**Student analogy**: Like a receptionist - directs visitors to the right office

**Why HTTP API instead of REST API?**: Simpler and 70% cheaper!

### 3. Lambda (Compute)

**What it is**: Serverless functions - code runs without managing servers  
**Why we use it**: Auto-scales, pay-per-request, no maintenance  
**Student analogy**: Like calling an Uber - you don't own the car, just use it when needed

**Cost example**: 1 million requests with 512MB RAM = ~$8.35/month

### 4. Bedrock (AI)

**What it is**: AWS's fully managed AI service with foundation models  
**Why we use it**: Access to Claude without managing ML infrastructure  
**Student analogy**: Like Netflix for AI models - stream instead of download

**Tool use**: Bedrock's Converse API lets models decide when to call functions!

### 5. S3 (Storage)

**What it is**: Object storage service  
**Why we use it**: Host website + store CSV data, dirt cheap  
**Student analogy**: Like Dropbox, but for applications

**Cost**: ~$0.023 per GB/month (80 records = fractions of a penny!)

## 🛠️ Tool Use Explained

### What is MCP (Model Context Protocol)?

MCP is a standard for connecting AI models to tools (APIs, databases, etc.). Our implementation demonstrates MCP concepts by:

1. **Tool Definition**: Describe what the tool does (like an API spec)
2. **Tool Execution**: Run the actual query when the model decides to use it
3. **Result Synthesis**: Model uses tool results to answer the user

### How Our Tool Works

```python
# 1. Define the tool in Bedrock format
TOOL_DEFINITION = {
    "name": "query_vinyl_collection",
    "description": "Query Luke's vinyl records...",
    "parameters": {
        "query_type": ["artist", "label", "year", ...],
        "search_term": "string",
        "limit": "integer"
    }
}

# 2. Bedrock decides when to use it
if user_asks_about_collection:
    call_tool("query_vinyl_collection", {"query_type": "artist", ...})

# 3. Lambda executes the tool
def query_vinyl_collection(query_type, search_term):
    csv_data = s3.get_object(Bucket, Key)
    results = filter_records(csv_data, query_type, search_term)
    return format_results(results)

# 4. Bedrock synthesizes the answer
final_answer = synthesize(tool_results) + tool_context
```

### Demo Prompts

| Prompt | Tool Used? | Why? |
|--------|-----------|------|
| "What Grimes albums do I own?" | ✅ Yes | Specific collection query |
| "Show me 4AD label records" | ✅ Yes | Filtered collection query |
| "What vinyl did I add in 2024?" | ✅ Yes | Time-based collection query |
| "What is vinyl?" | ❌ No | General knowledge question |
| "How does MCP work?" | ❌ No | Technical question (not collection-specific) |

## 💰 Cost Breakdown

Estimated monthly costs (assuming 1000 queries/month):

| Service | Usage | Cost |
|---------|-------|------|
| S3 Storage | 2 buckets, <1MB total | $0.01 |
| S3 Requests | 1000 GET requests | $0.01 |
| Lambda Invocations | 2000 invocations (512MB, 2s avg) | $0.17 |
| API Gateway | 1000 requests | $0.01 |
| Bedrock | 1000 requests (~2000 tokens each) | $15.00 |
| Cognito | <50 MAU (Monthly Active Users) | $0.00 |
| **TOTAL** | | **~$15.20/month** |

**Note**: Bedrock is the main cost. Use AWS Free Tier strategically for demos!

## 🔧 Customization Ideas

### Change the Data Source

Replace `discogs.csv` with your own data:
1. Update CSV structure in `data/discogs.csv`
2. Modify `query_vinyl_collection()` in `lambda/handler.py`
3. Update tool description and demo prompts

**Ideas**: Book collection, recipes, movie watchlist, Pokemon cards, plant database

### Add More Tools

```python
TOOL_DEFINITION_2 = {
    "name": "get_record_stats",
    "description": "Get statistics about the collection",
    ...
}
```

Then implement and register the new tool!

### Use DynamoDB Instead

For better performance with large datasets:
1. Replace S3 CSV with DynamoDB table in Terraform
2. Use `boto3.client('dynamodb')` in Lambda
3. Update IAM permissions

### Remove Cognito (Public Demo)

For simpler public demos:
1. Remove Cognito resources from `main.tf`
2. Remove JWT authorizer from API Gateway
3. Remove auth UI from `frontend/index.html`

## 🐛 Troubleshooting

### "User does not exist" after signup

The pre-signup trigger auto-confirms users. If you see this:
- Check CloudWatch logs: `/aws/lambda/serverless-mcp-chatbot-demo-cognito-presignup`
- Verify email domain matches `allowed_email_domain` variable
- Try a different email with the correct domain

### CORS Errors

Check:
- Frontend origin matches API Gateway CORS config
- Using `http://` not `https://` for S3 website URLs
- Browser console for specific CORS issues

### "Tool not triggering"

The AI decides when to use tools. Try:
- More specific prompts: "What **records** do I have by Grimes?"
- Check CloudWatch logs: `/aws/lambda/serverless-mcp-chatbot-demo-chat`
- Adjust the tool description if needed (make it more obvious when to use)

### Lambda timeout

If queries are slow:
- Increase Lambda timeout in `main.tf` (currently 60s)
- Increase memory (faster CPU with higher memory)
- Optimize CSV parsing (consider caching)

### Bedrock access denied

- Enable Claude models in AWS Bedrock console
- Check your region supports Bedrock (not all regions do!)
- Verify IAM policy includes `bedrock:InvokeModel`

## 📚 Learning Resources

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Amazon Bedrock User Guide](https://docs.aws.amazon.com/bedrock/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Cognito Developer Guide](https://docs.aws.amazon.com/cognito/)
- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)

## 🤝 Contributing

This is a demo project, but improvements are welcome! Ideas:
- Additional tool implementations
- Better error handling
- Multi-turn conversation support
- Streaming responses
- Deployment automation scripts

## 📄 License

MIT License - Feel free to steal this code! See [LICENSE](LICENSE) for details.

## 🎓 Educational Use

This project is specifically designed for:
- **AWS User Groups** presentations
- **University coursework** (cloud computing, AI/ML, web dev)
- **Technical workshops** and bootcamps
- **Portfolio projects** for job hunting

You have full permission to:
- Present this at meetups
- Use in classroom settings
- Modify for your own demos
- Include in your resume/portfolio

Just remember to update the email domain restriction! 😄

## 🙋 Questions?

This is a demo project by Luke Little. If you're using this for a talk or class:
- Tag me on Twitter/LinkedIn (I'd love to see it!)
- Open an issue if something doesn't work
- Star the repo if you found it helpful

Happy demoing! 🚀
