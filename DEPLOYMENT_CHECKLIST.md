# 🚀 Deployment Checklist

Use this checklist to ensure smooth deployment.

## ✅ Pre-Deployment

- [ ] AWS CLI configured with valid credentials (`aws sts get-caller-identity`)
- [ ] Terraform installed (`terraform --version`)
- [ ] Python 3.12+ installed (`python3 --version`)
- [ ] Bedrock model access enabled in AWS Console (Claude 3.5 Sonnet in your region)
- [ ] Reviewed and updated `allowed_email_domain` in `infra/terraform/variables.tf` if needed

## 🔧 File Verification

All these files should exist:

- [ ] `data/discogs.csv` - Your vinyl collection data
- [ ] `lambda/handler.py` - Main Lambda function
- [ ] `lambda/cognito_trigger.py` - Pre-signup validation
- [ ] `lambda/requirements.txt` - Python dependencies
- [ ] `lambda/build.sh` - Build script (executable)
- [ ] `lambda/lambda.zip` - Placeholder zip file
- [ ] `infra/terraform/versions.tf` - Terraform config
- [ ] `infra/terraform/variables.tf` - Variables
- [ ] `infra/terraform/main.tf` - Main infrastructure
- [ ] `infra/terraform/outputs.tf` - Output values
- [ ] `frontend/index.html` - Web UI
- [ ] `deploy.sh` - Automated deployment script (executable)

## 🚀 Deployment Options

### Option 1: Automated (Recommended)

```bash
./deploy.sh
```

### Option 2: Manual Steps

1. **Build Lambda:**
   ```bash
   cd lambda && ./build.sh && cd ..
   ```

2. **Deploy Infrastructure:**
   ```bash
   cd infra/terraform
   terraform init
   terraform apply
   ```

3. **Save Terraform Outputs:**
   ```bash
   terraform output
   ```

4. **Update Frontend Config:**
   Edit `frontend/index.html` and replace:
   - `YOUR_API_URL_HERE` → API Gateway URL
   - `YOUR_USER_POOL_ID` → Cognito User Pool ID
   - `YOUR_CLIENT_ID` → Cognito Client ID
   - Region if not us-east-1

5. **Upload Frontend:**
   ```bash
   aws s3 cp ../../frontend/index.html s3://YOUR_BUCKET_NAME/
   ```

## ✅ Post-Deployment Verification

- [ ] Visit the website URL from Terraform output
- [ ] Sign up with a `@lukelittle.com` email (or your configured domain)
- [ ] Log in successfully
- [ ] Send test message: "What Grimes albums do I own?"
- [ ] Verify "🔧 Tool Used" badge appears
- [ ] Check general knowledge: "What is vinyl?" (should NOT use tool)
- [ ] Review CloudWatch logs for any errors

## 🧹 Cleanup

When you're done with the demo:

```bash
cd infra/terraform
terraform destroy
```

This will delete all AWS resources and stop billing.

## 📊 Cost Monitoring

Monitor your costs in AWS Console:
- **Bedrock** will be the main cost (~$15/month for 1000 queries)
- **Lambda** should be minimal (~$0.17/month)
- **Other services** should be < $0.05/month combined

Set up a billing alarm in AWS Console if this is a demo/learning project!

## ⚠️ Common Issues & Quick Fixes

| Issue | Solution |
|-------|----------|
| Terraform fails on lambda.zip | Run `cd lambda && ./build.sh` first |
| Bedrock access denied | Enable Claude in Bedrock console for your region |
| Signup fails | Check email domain matches `allowed_email_domain` |
| API returns 401 | Check Cognito config in frontend matches Terraform outputs |
| Tool not triggering | Ask more specific questions about records, try "What **records** do I have..." |
| CORS errors | Ensure using `http://` not `https://` for S3 website URL |

## 🎯 Demo Success Criteria

Your demo is ready when:
- ✅ Website loads without errors
- ✅ Authentication works (signup + login)
- ✅ Chat responds to messages
- ✅ Tool badge appears for collection queries
- ✅ Tool badge does NOT appear for general questions
- ✅ Responses are relevant and accurate

Happy demoing! 🎵
