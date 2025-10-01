# Configuration Guide - RunPod Serverless ComfyUI

This guide covers all configuration options for your RunPod serverless ComfyUI endpoint.

## 📋 Environment Variables Overview

Environment variables are set in your RunPod template configuration. You can add or modify them when creating a template or endpoint.

## 🔧 General Configuration

### REFRESH_WORKER

**Description**: Controls whether the worker pod stops after each job to ensure a clean state.

**Values**: `true` or `false`  
**Default**: `false`

**When to use**:

- Set to `true` if you experience memory leaks or state issues between jobs
- Set to `false` for better performance (workers stay warm)

**How to set**:

```
REFRESH_WORKER=false
```

**Impact**:

- `true`: Slower startup for each job (~15-30s cold start)
- `false`: Faster subsequent jobs (~2-5s)

### SERVE_API_LOCALLY

**Description**: Enables local HTTP server for development/testing without RunPod.

**Values**: `true` or `false`  
**Default**: `false`

**When to use**:

- Local development and testing
- Not needed for production RunPod deployment

```
SERVE_API_LOCALLY=true
```

## 📝 Logging Configuration

### COMFY_LOG_LEVEL

**Description**: Controls ComfyUI's internal logging verbosity.

**Values**: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`  
**Default**: `DEBUG`

**Recommendations**:

- **Production**: `INFO` - reduces log volume
- **Troubleshooting**: `DEBUG` - shows detailed execution steps
- **Performance**: `WARNING` - minimal logging

**Example**:

```
COMFY_LOG_LEVEL=INFO
```

**What you'll see**:

- `DEBUG`: Every node execution, tensor shapes, memory usage
- `INFO`: Job start/end, major steps
- `WARNING`: Only warnings and errors
- `ERROR`: Only errors and critical issues

## 🐛 Debugging Configuration

### WEBSOCKET_RECONNECT_ATTEMPTS

**Description**: Number of websocket reconnection attempts during job execution.

**Default**: `5`

```
WEBSOCKET_RECONNECT_ATTEMPTS=10
```

**When to increase**: If you experience network instability

### WEBSOCKET_RECONNECT_DELAY_S

**Description**: Delay in seconds between websocket reconnection attempts.

**Default**: `3`

```
WEBSOCKET_RECONNECT_DELAY_S=5
```

### WEBSOCKET_TRACE

**Description**: Enable low-level websocket frame tracing for protocol debugging.

**Values**: `true` or `false`  
**Default**: `false`

**When to use**: Only for diagnosing connection issues (very verbose!)

```
WEBSOCKET_TRACE=true
```

## ☁️ AWS S3 Upload Configuration

By default, images are returned as base64 strings. Configure S3 to upload images to your bucket instead.

### Why Use S3?

**Advantages**:

- ✅ Bypass RunPod's response size limits (20MB)
- ✅ Reduce network transfer costs
- ✅ Permanent storage of generated images
- ✅ Direct CDN integration

**Disadvantages**:

- ❌ Requires AWS account and S3 setup
- ❌ Additional S3 storage costs
- ❌ Slightly more complex setup

### Prerequisites

1. **AWS Account** - [Sign up here](https://aws.amazon.com/)
2. **S3 Bucket** - Create a bucket in your desired region
3. **IAM User** - With programmatic access and S3 permissions

### Step-by-Step S3 Setup

#### 1. Create S3 Bucket

```bash
# Using AWS CLI
aws s3 mb s3://my-comfyui-outputs --region us-east-1
```

Or via AWS Console:

1. Go to [S3 Console](https://console.aws.amazon.com/s3/)
2. Click **Create bucket**
3. Name: `my-comfyui-outputs`
4. Region: Choose closest to your RunPod workers
5. Block all public access: **Uncheck** (if you want public URLs)
6. Click **Create bucket**

#### 2. Create IAM User

1. Go to [IAM Console](https://console.aws.amazon.com/iam/)
2. Click **Users** → **Add users**
3. Username: `comfyui-uploader`
4. Access type: **Programmatic access**
5. Click **Next: Permissions**

#### 3. Attach IAM Policy

Create a custom policy with these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:PutObjectAcl"],
      "Resource": "arn:aws:s3:::my-comfyui-outputs/*"
    }
  ]
}
```

**Steps**:

1. Click **Create policy**
2. JSON tab → paste above
3. Name: `ComfyUIUploadPolicy`
4. Create policy
5. Attach to your IAM user

#### 4. Get Access Keys

1. Go to user's **Security credentials** tab
2. Click **Create access key**
3. Use case: **Application running outside AWS**
4. **Save the Access Key ID and Secret Access Key** - you won't see the secret again!

### S3 Environment Variables

Add these to your RunPod template:

#### BUCKET_ENDPOINT_URL

**Description**: Full endpoint URL of your S3 bucket.

**Format**: `https://<bucket-name>.s3.<region>.amazonaws.com`

**Example**:

```
BUCKET_ENDPOINT_URL=https://my-comfyui-outputs.s3.us-east-1.amazonaws.com
```

**For custom S3-compatible services** (DigitalOcean Spaces, Wasabi, etc.):

```
BUCKET_ENDPOINT_URL=https://my-space.nyc3.digitaloceanspaces.com
```

#### BUCKET_ACCESS_KEY_ID

**Description**: Your AWS access key ID.

**Example**:

```
BUCKET_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
```

#### BUCKET_SECRET_ACCESS_KEY

**Description**: Your AWS secret access key.

**Example**:

```
BUCKET_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

⚠️ **Security Warning**: Keep this secret! Never commit to git or share publicly.

### Complete S3 Configuration Example

In RunPod Template → Environment Variables:

```
BUCKET_ENDPOINT_URL=https://my-comfyui-outputs.s3.us-east-1.amazonaws.com
BUCKET_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
BUCKET_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
COMFY_LOG_LEVEL=INFO
```

### S3 Response Format

With S3 configured, responses will look like:

```json
{
  "id": "sync-abc123-def456",
  "status": "COMPLETED",
  "output": {
    "images": [
      {
        "filename": "ComfyUI_00001_.png",
        "type": "s3_url",
        "data": "https://my-comfyui-outputs.s3.us-east-1.amazonaws.com/sync-abc123-def456/ComfyUI_00001_.png"
      }
    ]
  },
  "delayTime": 1234,
  "executionTime": 8765
}
```

**URL Structure**: `https://<bucket>.<region>.amazonaws.com/<job-id>/<filename>`

### Testing S3 Upload

PowerShell script to verify S3 is working:

```powershell
# test-s3.ps1
$API_KEY = "your-api-key"
$ENDPOINT_ID = "your-endpoint-id"

$body = @{
    input = @{
        workflow = (Get-Content "basic-workflow.json" | ConvertFrom-Json)
    }
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod `
    -Uri "https://api.runpod.ai/v2/$ENDPOINT_ID/runsync" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $API_KEY"
        "Content-Type" = "application/json"
    } `
    -Body $body

# Check if S3 URL is returned
if ($response.output.images[0].type -eq "s3_url") {
    Write-Host "✅ S3 upload working!"
    Write-Host "URL: $($response.output.images[0].data)"
} else {
    Write-Host "❌ Still using base64 - check S3 config"
}
```

## 🗂️ S3-Compatible Services

You can use other S3-compatible services:

### DigitalOcean Spaces

```
BUCKET_ENDPOINT_URL=https://my-space.nyc3.digitaloceanspaces.com
BUCKET_ACCESS_KEY_ID=your-do-spaces-key
BUCKET_SECRET_ACCESS_KEY=your-do-spaces-secret
```

### Wasabi

```
BUCKET_ENDPOINT_URL=https://s3.wasabisys.com/my-bucket
BUCKET_ACCESS_KEY_ID=your-wasabi-key
BUCKET_SECRET_ACCESS_KEY=your-wasabi-secret
```

### Backblaze B2

```
BUCKET_ENDPOINT_URL=https://s3.us-west-004.backblazeb2.com/my-bucket
BUCKET_ACCESS_KEY_ID=your-b2-key-id
BUCKET_SECRET_ACCESS_KEY=your-b2-application-key
```

### Cloudflare R2

```
BUCKET_ENDPOINT_URL=https://<account-id>.r2.cloudflarestorage.com/my-bucket
BUCKET_ACCESS_KEY_ID=your-r2-access-key
BUCKET_SECRET_ACCESS_KEY=your-r2-secret-key
```

## 💰 Cost Comparison: Base64 vs S3

### Base64 Response

**Pros**:

- Simple setup
- No additional services needed

**Cons**:

- Higher network egress costs (~$0.10/GB from RunPod)
- Response size limits (20MB for `/runsync`)

**Cost for 1000 images** (avg 2MB each):

- Network: ~$200 (2GB × $0.10/GB × 1000)

### S3 Upload

**Pros**:

- Lower total costs for high volume
- No response size limits
- Permanent storage

**Cons**:

- AWS S3 costs
- More complex setup

**Cost for 1000 images**:

- S3 PUT requests: $0.005 (1000 × $0.000005)
- S3 storage: $0.046/month (2GB × $0.023/GB)
- Data transfer to S3: Free (from RunPod)
- **Total**: ~$0.051 + storage

**Savings**: ~$199.95 for 1000 images! 💰

## 📊 Recommended Configurations

### Development/Testing

```
COMFY_LOG_LEVEL=DEBUG
REFRESH_WORKER=false
# No S3 needed - use base64
```

### Production (Low Volume)

```
COMFY_LOG_LEVEL=INFO
REFRESH_WORKER=false
# No S3 needed - use base64
```

### Production (High Volume)

```
COMFY_LOG_LEVEL=INFO
REFRESH_WORKER=false
BUCKET_ENDPOINT_URL=https://your-bucket.s3.region.amazonaws.com
BUCKET_ACCESS_KEY_ID=your-key
BUCKET_SECRET_ACCESS_KEY=your-secret
```

### Debugging Issues

```
COMFY_LOG_LEVEL=DEBUG
REFRESH_WORKER=true
WEBSOCKET_RECONNECT_ATTEMPTS=10
WEBSOCKET_RECONNECT_DELAY_S=5
```

## 🔄 Updating Configuration

### Method 1: Update Template

1. Go to **Serverless** → **Templates**
2. Click on your template
3. Click **Edit**
4. Modify environment variables
5. Save
6. **Note**: Existing endpoints won't update automatically

### Method 2: Create New Endpoint

1. Create new endpoint with updated template
2. Test thoroughly
3. Update your API calls to use new endpoint ID
4. Delete old endpoint

### Method 3: Rebuild Docker Image

For permanent changes, update `Dockerfile`:

```dockerfile
# Add to Dockerfile
ENV COMFY_LOG_LEVEL=INFO
ENV REFRESH_WORKER=false
```

Then rebuild and redeploy.

## 🔐 Security Best Practices

1. **Use AWS Secrets Manager** for production S3 credentials
2. **Rotate access keys** every 90 days
3. **Use bucket policies** to restrict access
4. **Enable S3 bucket logging** to track uploads
5. **Set S3 lifecycle policies** to auto-delete old images
6. **Never log** secret keys in your application

### Example S3 Bucket Policy

Restrict uploads to your RunPod workers:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::YOUR-ACCOUNT-ID:user/comfyui-uploader"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::my-comfyui-outputs/*"
    }
  ]
}
```

## 📝 Environment Variable Reference Table

| Variable                       | Type    | Default | Description                   |
| ------------------------------ | ------- | ------- | ----------------------------- |
| `REFRESH_WORKER`               | boolean | `false` | Restart worker after each job |
| `SERVE_API_LOCALLY`            | boolean | `false` | Enable local dev server       |
| `COMFY_LOG_LEVEL`              | string  | `DEBUG` | Log verbosity level           |
| `WEBSOCKET_RECONNECT_ATTEMPTS` | integer | `5`     | WS reconnection attempts      |
| `WEBSOCKET_RECONNECT_DELAY_S`  | integer | `3`     | Delay between WS reconnects   |
| `WEBSOCKET_TRACE`              | boolean | `false` | Enable WS frame tracing       |
| `BUCKET_ENDPOINT_URL`          | string  | -       | S3 bucket endpoint URL        |
| `BUCKET_ACCESS_KEY_ID`         | string  | -       | S3 access key ID              |
| `BUCKET_SECRET_ACCESS_KEY`     | string  | -       | S3 secret access key          |

---

**Next Steps**:

- [Troubleshooting Guide](./04-troubleshooting-guide.md) - Solve common issues
- [Workflow Examples](./05-workflow-examples.md) - Ready-to-use workflows
