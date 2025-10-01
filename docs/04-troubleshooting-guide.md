# Troubleshooting Guide - RunPod Serverless ComfyUI

This guide helps you diagnose and fix common issues with your RunPod serverless ComfyUI endpoint.

## 🔍 Quick Diagnostics

### Check Endpoint Health

```powershell
curl https://api.runpod.ai/v2/your-endpoint-id/health
```

**Expected**: `{"status": "healthy"}`

### Check Endpoint Status

1. Go to [RunPod Serverless Dashboard](https://runpod.io/console/serverless/user/endpoints)
2. Click on your endpoint
3. Check:
   - Status: Should be green "Ready"
   - Active Workers: Shows current running workers
   - Errors: Look for error messages

### Enable Debug Logging

Add to your template environment variables:

```
COMFY_LOG_LEVEL=DEBUG
```

View logs:

1. Go to endpoint dashboard
2. Click **Logs** tab
3. Set time range to recent
4. Look for error messages

## ⚠️ Common Issues and Solutions

### 1. "Workflow validation failed"

**Symptoms**:

- Request returns error about invalid workflow
- Status: `FAILED`

**Causes**:

- Workflow not exported in API format
- Invalid JSON structure
- Missing required nodes

**Solutions**:

✅ **Export in API format**:

1. In ComfyUI: **Workflow** → **Export (API)** (NOT regular Export)
2. Save as `workflow.json`
3. Use this file in your API request

✅ **Validate JSON**:

```powershell
# PowerShell - check if JSON is valid
Get-Content workflow.json | ConvertFrom-Json
```

✅ **Check workflow structure**:

```json
{
  "input": {
    "workflow": {
      "1": { "inputs": {...}, "class_type": "..." },
      "2": { "inputs": {...}, "class_type": "..." }
      // Node IDs must be strings!
    }
  }
}
```

### 2. "Model not found: ponyDiffusionV6XL.safetensors"

**Symptoms**:

- Error mentions missing checkpoint
- Workflow fails at checkpoint loading

**Causes**:

- Model wasn't downloaded during Docker build
- Incorrect filename in workflow
- Build failed silently

**Solutions**:

✅ **Verify model in Docker image**:

```powershell
# Run container locally
docker run -it --rm yourusername/comfyui-pony-v6:latest /bin/bash

# Inside container:
ls -lh /comfyui/models/checkpoints/
# Should show: ponyDiffusionV6XL.safetensors
```

✅ **Rebuild Docker image**:

```powershell
docker build --platform linux/amd64 -t yourusername/comfyui-pony-v6:latest . --no-cache
docker push yourusername/comfyui-pony-v6:latest
```

✅ **Check filename in workflow**:

- Must match exactly: `ponyDiffusionV6XL.safetensors`
- Case-sensitive!

✅ **Check build logs**:

```powershell
docker build --platform linux/amd64 -t yourusername/comfyui-pony-v6:latest . 2>&1 | Select-String "error"
```

### 3. "CUDA out of memory"

**Symptoms**:

- Error message: "RuntimeError: CUDA out of memory"
- Job fails during generation

**Causes**:

- Resolution too high for GPU VRAM
- Batch size too large
- Insufficient GPU VRAM

**Solutions**:

✅ **Reduce resolution**:

```json
{
  "inputs": {
    "width": 832, // Instead of 1024
    "height": 1216 // SDXL supports various resolutions
  }
}
```

SDXL supported resolutions:

- 1024×1024 (standard)
- 832×1216 (portrait)
- 1216×832 (landscape)
- 768×1344 (tall portrait)

✅ **Reduce batch size**:

```json
{
  "inputs": {
    "batch_size": 1 // Generate one image at a time
  }
}
```

✅ **Upgrade GPU**:

Minimum VRAM requirements:

- 1024×1024: 10GB (tight)
- 1024×1024 safely: 12GB+
- Multiple batches: 16GB+

Recommended GPUs:

- RTX 4090 (24GB)
- RTX A4500 (20GB)
- RTX 3090 (24GB)

✅ **Use VAE tiling** (advanced):
Add VAE Decode (Tiled) node instead of regular VAE Decode

### 4. Request Timeout

**Symptoms**:

- Request times out after 60 seconds
- No response received

**Causes**:

- Generation takes longer than timeout
- Worker cold start delay
- Network issues

**Solutions**:

✅ **Use async endpoint**:

```powershell
# Instead of /runsync, use /run
$response = Invoke-RestMethod `
    -Uri "https://api.runpod.ai/v2/$ENDPOINT_ID/run" `
    -Method POST `
    -Headers @{ "Authorization" = "Bearer $API_KEY" } `
    -Body $body

$jobId = $response.id

# Poll for status
do {
    Start-Sleep -Seconds 5
    $status = Invoke-RestMethod `
        -Uri "https://api.runpod.ai/v2/$ENDPOINT_ID/status/$jobId" `
        -Headers @{ "Authorization" = "Bearer $API_KEY" }
} while ($status.status -in @("IN_QUEUE", "IN_PROGRESS"))
```

✅ **Reduce generation steps**:

```json
{
  "inputs": {
    "steps": 20 // Instead of 25-30
  }
}
```

✅ **Enable Flash Boot**:

- In endpoint settings: Flash Boot → **Enabled**
- Reduces cold start from ~60s to ~20s

### 5. "Authentication failed" / "Invalid API key"

**Symptoms**:

- HTTP 401 Unauthorized
- Error: "Invalid API key"

**Causes**:

- Wrong API key
- API key not in header
- Key expired or deleted

**Solutions**:

✅ **Verify API key format**:

```powershell
# Correct format
$headers = @{
    "Authorization" = "Bearer your-api-key-here"
    "Content-Type" = "application/json"
}
```

✅ **Generate new API key**:

1. RunPod Dashboard → Settings → API Keys
2. Create API Key
3. Copy and use new key

✅ **Check endpoint ID**:

```powershell
# URL format:
https://api.runpod.ai/v2/{ENDPOINT_ID}/runsync
                          ^^^^^^^^^^^
                          Must match your endpoint!
```

### 6. "No workers available"

**Symptoms**:

- Request stays "IN_QUEUE" forever
- No workers starting
- Long delay times

**Causes**:

- Max workers reached
- Selected GPU unavailable
- Insufficient RunPod credits

**Solutions**:

✅ **Check endpoint settings**:

1. Go to endpoint dashboard
2. Verify:
   - Max Workers > 0
   - Active Workers < Max Workers
   - GPU type is available (green indicator)

✅ **Increase max workers**:

1. Endpoint → Settings → Max Workers
2. Increase from 1 to 3+

✅ **Try different GPU**:

1. Edit endpoint
2. Select different GPU type (RTX 4090, A4000, etc.)
3. Save

✅ **Check RunPod credits**:

- Dashboard → Billing
- Add credits if needed

### 7. S3 Upload Failed

**Symptoms**:

- Images returned as base64 despite S3 config
- Error: "Failed to upload to S3"
- `output.errors` contains S3 error

**Causes**:

- Wrong S3 credentials
- Incorrect bucket URL
- IAM permissions insufficient
- Bucket doesn't exist

**Solutions**:

✅ **Verify S3 environment variables**:

```
BUCKET_ENDPOINT_URL=https://bucket-name.s3.region.amazonaws.com
BUCKET_ACCESS_KEY_ID=AKIA...
BUCKET_SECRET_ACCESS_KEY=...
```

✅ **Test S3 access locally**:

```powershell
# Install AWS CLI
winget install Amazon.AWSCLI

# Configure credentials
aws configure set aws_access_key_id YOUR_KEY
aws configure set aws_secret_access_key YOUR_SECRET

# Test upload
echo "test" > test.txt
aws s3 cp test.txt s3://your-bucket-name/test.txt
```

✅ **Check IAM permissions**:
Required policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:PutObjectAcl"],
      "Resource": "arn:aws:s3:::your-bucket/*"
    }
  ]
}
```

✅ **Check bucket region**:

- Bucket region must match in endpoint URL
- Example: `us-east-1` in URL must match actual bucket region

### 8. Docker Build Fails

**Symptoms**:

- Build errors during `docker build`
- "No space left on device"
- Download failures

**Solutions**:

✅ **Free disk space**:

```powershell
# Remove unused Docker data
docker system prune -a --volumes

# Check free space
Get-PSDrive C
```

✅ **Increase Docker disk**:

1. Docker Desktop → Settings → Resources
2. Increase "Virtual disk limit" to 100GB+
3. Apply & Restart

✅ **Build with verbose output**:

```powershell
docker build --platform linux/amd64 -t yourusername/comfyui-pony-v6:latest . --progress=plain
```

✅ **Download models manually first**:

```powershell
# Download locally first
mkdir models
cd models
curl -L -o ponyDiffusionV6XL.safetensors "https://civitai.com/api/download/models/290640"

# Then in Dockerfile, use COPY instead of download
# COPY models/ponyDiffusionV6XL.safetensors /comfyui/models/checkpoints/
```

### 9. Image Quality Issues

**Symptoms**:

- Blurry outputs
- Low quality results
- Not matching expected Pony V6 XL quality

**Causes**:

- CLIP Skip not set to 2
- Missing quality tags
- Wrong sampler/settings

**Solutions**:

✅ **Set CLIP Skip to 2**:
In ComfyUI workflow:

1. Load Checkpoint node → Advanced → `stop_at_clip_layer: -2`

Or in API workflow:

```json
{
  "4": {
    "inputs": {
      "ckpt_name": "ponyDiffusionV6XL.safetensors",
      "stop_at_clip_layer": -2
    },
    "class_type": "CheckpointLoaderSimple"
  }
}
```

✅ **Use quality tags**:

```
score_9, score_8_up, score_7_up, score_6_up, score_5_up, score_4_up, [your prompt]
```

✅ **Correct sampler settings**:

```json
{
  "sampler_name": "euler_ancestral",
  "scheduler": "normal",
  "steps": 25,
  "cfg": 7.0
}
```

✅ **Use proper VAE**:

- Ensure SDXL VAE is loaded
- Check VAE file exists in image

### 10. Slow Performance

**Symptoms**:

- Long execution times (>30s for single image)
- High delay times
- Workers slow to start

**Causes**:

- Cold start delays
- Slow GPU
- Inefficient workflow
- Network latency

**Solutions**:

✅ **Enable Flash Boot**:

- Endpoint settings → Flash Boot: **Enabled**
- Reduces cold start significantly

✅ **Keep workers warm**:

```
REFRESH_WORKER=false
```

✅ **Optimize workflow**:

- Remove unnecessary nodes
- Use efficient samplers (Euler a is fast)
- Reduce steps (20-25 is enough)

✅ **Upgrade GPU**:
Performance comparison for 1024×1024, 25 steps:

- RTX 4090: ~6-8s ⚡
- RTX A5000: ~8-10s
- RTX 3090: ~10-12s

✅ **Pre-generate workers**:
Set Active Workers to 1+ to keep at least one warm

## 🔧 Advanced Debugging

### View Container Logs

```powershell
# If running locally
docker logs container-id

# On RunPod
# Use the Logs tab in endpoint dashboard
```

### Test Workflow Locally

```powershell
# Pull your image
docker pull yourusername/comfyui-pony-v6:latest

# Run with local API
docker run -it --rm `
    -p 8000:8000 `
    -e SERVE_API_LOCALLY=true `
    yourusername/comfyui-pony-v6:latest

# Test locally
curl -X POST http://localhost:8000/runsync `
    -H "Content-Type: application/json" `
    -d '{"input": {"workflow": {...}}}'
```

### Inspect Docker Image

```powershell
# Run bash in container
docker run -it --rm yourusername/comfyui-pony-v6:latest /bin/bash

# Check models
ls -lh /comfyui/models/checkpoints/
ls -lh /comfyui/models/vae/

# Check ComfyUI version
cd /comfyui
python -c "import comfy; print(comfy.__version__)"

# Test model loading
python -c "import safetensors; print('OK')"
```

### Check RunPod Service Status

- [RunPod Status Page](https://status.runpod.io/)
- Check for ongoing incidents

## 📊 Performance Benchmarks

Expected generation times for Pony Diffusion V6 XL:

| GPU       | Resolution | Steps | Time | Cost/Image |
| --------- | ---------- | ----- | ---- | ---------- |
| RTX 4090  | 1024×1024  | 25    | ~8s  | $0.0018    |
| RTX A5000 | 1024×1024  | 25    | ~10s | $0.0025    |
| RTX 3090  | 1024×1024  | 25    | ~12s | $0.0023    |
| A40       | 1024×1024  | 25    | ~15s | $0.0045    |

If your times are significantly higher:

1. Check GPU utilization in logs
2. Verify no memory swapping
3. Check for network bottlenecks
4. Ensure REFRESH_WORKER=false for subsequent requests

## 🆘 Getting Help

If you're still stuck:

1. **Check RunPod Discord**:

   - [Join here](https://discord.gg/runpod)
   - #serverless-help channel

2. **Check worker-comfyui Issues**:

   - [GitHub Issues](https://github.com/runpod-workers/worker-comfyui/issues)
   - Search for similar problems

3. **Gather debugging info**:

   ```
   - Endpoint ID
   - Error message (full text)
   - Request payload (sanitized)
   - Log excerpts
   - Docker image tag
   - GPU type
   ```

4. **Contact RunPod Support**:
   - support@runpod.io
   - Include all debugging info

## ✅ Checklist Before Asking for Help

Before posting issues, verify:

- [ ] Using latest worker-comfyui version (5.4.1+)
- [ ] Workflow exported in API format
- [ ] Docker image built with `--platform linux/amd64`
- [ ] Environment variables set correctly
- [ ] API key and endpoint ID are correct
- [ ] Sufficient credits in RunPod account
- [ ] Checked endpoint logs for errors
- [ ] Tested with simple workflow
- [ ] Read this troubleshooting guide!

---

**Related Docs**:

- [Deployment Guide](./01-deployment-guide.md)
- [Configuration Guide](./03-configuration-guide.md)
- [Workflow Examples](./05-workflow-examples.md)
