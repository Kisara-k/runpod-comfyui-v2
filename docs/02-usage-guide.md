# Usage Guide - RunPod Serverless ComfyUI API

This guide explains how to use your deployed Pony Diffusion V6 XL endpoint to generate images via the API.

## 📋 Prerequisites

Before using the API, you need:

- ✅ Deployed RunPod endpoint (see [Deployment Guide](./01-deployment-guide.md))
- ✅ RunPod API Key
- ✅ Endpoint ID
- ✅ ComfyUI installed locally (to create workflows)

## 🎨 Step 1: Create a ComfyUI Workflow

### 1.1 Install ComfyUI Locally (Optional)

If you don't have ComfyUI installed:

**Windows (PowerShell):**

```powershell
# Clone ComfyUI
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI

# Create virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install -r requirements.txt

# Run ComfyUI
python main.py
```

Open your browser to: `http://127.0.0.1:8188`

### 1.2 Create Your Workflow

1. **Open ComfyUI** in your browser
2. **Create a basic text-to-image workflow**:
   - Add nodes: Load Checkpoint → CLIP Text Encode (Positive) → CLIP Text Encode (Negative) → KSampler → VAE Decode → Save Image
3. **Configure for Pony Diffusion V6 XL**:
   - Load Checkpoint: Select `ponyDiffusionV6XL.safetensors`
   - CLIP Skip: Set to **2** (Important!)
   - Resolution: 1024x1024 (or any SDXL resolution)
   - Sampler: `euler_ancestral` (Euler a)
   - Steps: 25
   - CFG: 7.0

### 1.3 Export Workflow (API Format)

**Critical**: You must export in API format!

1. In ComfyUI menu, click **Workflow** → **Export (API)**
2. Save the `workflow.json` file
3. This JSON contains the node structure needed for the API

## 🚀 Step 2: Make Your First API Request

### 2.1 Using PowerShell (Windows)

Create a file `test-endpoint.ps1`:

```powershell
# test-endpoint.ps1
# Test RunPod Serverless ComfyUI Endpoint

$API_KEY = "your-runpod-api-key-here"
$ENDPOINT_ID = "your-endpoint-id-here"

# Read workflow JSON
$workflowJson = Get-Content -Path ".\basic-workflow.json" -Raw | ConvertFrom-Json

# Create request body
$body = @{
    input = @{
        workflow = $workflowJson
    }
} | ConvertTo-Json -Depth 10

# Send request to /runsync endpoint
$response = Invoke-RestMethod `
    -Uri "https://api.runpod.ai/v2/$ENDPOINT_ID/runsync" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $API_KEY"
        "Content-Type" = "application/json"
    } `
    -Body $body

# Display result
Write-Host "Status: $($response.status)"
Write-Host "Execution Time: $($response.executionTime)ms"

# Save image (if base64)
if ($response.output.images) {
    foreach ($img in $response.output.images) {
        if ($img.type -eq "base64") {
            $imageBytes = [Convert]::FromBase64String($img.data)
            [IO.File]::WriteAllBytes(".\output_$($img.filename)", $imageBytes)
            Write-Host "Saved: output_$($img.filename)"
        } else {
            Write-Host "S3 URL: $($img.data)"
        }
    }
}
```

Run the script:

```powershell
.\test-endpoint.ps1
```

### 2.2 Using cURL (Cross-Platform)

```bash
curl -X POST \
  -H "Authorization: Bearer your-runpod-api-key-here" \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "workflow": {
        "3": {
          "inputs": {
            "seed": 42,
            "steps": 25,
            "cfg": 7.0,
            "sampler_name": "euler_ancestral",
            "scheduler": "normal",
            "denoise": 1.0,
            "model": ["4", 0],
            "positive": ["6", 0],
            "negative": ["7", 0],
            "latent_image": ["5", 0]
          },
          "class_type": "KSampler"
        },
        "4": {
          "inputs": {
            "ckpt_name": "ponyDiffusionV6XL.safetensors"
          },
          "class_type": "CheckpointLoaderSimple"
        },
        "5": {
          "inputs": {
            "width": 1024,
            "height": 1024,
            "batch_size": 1
          },
          "class_type": "EmptyLatentImage"
        },
        "6": {
          "inputs": {
            "text": "score_9, score_8_up, score_7_up, a beautiful sunset over mountains",
            "clip": ["4", 1]
          },
          "class_type": "CLIPTextEncode"
        },
        "7": {
          "inputs": {
            "text": "score_1, score_2, score_3, blurry, low quality",
            "clip": ["4", 1]
          },
          "class_type": "CLIPTextEncode"
        },
        "8": {
          "inputs": {
            "samples": ["3", 0],
            "vae": ["4", 2]
          },
          "class_type": "VAEDecode"
        },
        "9": {
          "inputs": {
            "filename_prefix": "ComfyUI",
            "images": ["8", 0]
          },
          "class_type": "SaveImage"
        }
      }
    }
  }' \
  https://api.runpod.ai/v2/your-endpoint-id-here/runsync
```

### 2.3 Using Python

Create `test_endpoint.py`:

```python
import requests
import json
import base64
from pathlib import Path

API_KEY = "your-runpod-api-key-here"
ENDPOINT_ID = "your-endpoint-id-here"

# Load workflow
with open("basic-workflow.json", "r") as f:
    workflow = json.load(f)

# Create request
url = f"https://api.runpod.ai/v2/{ENDPOINT_ID}/runsync"
headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}
payload = {
    "input": {
        "workflow": workflow
    }
}

# Send request
print("Sending request to RunPod...")
response = requests.post(url, json=payload, headers=headers)
result = response.json()

print(f"Status: {result['status']}")
print(f"Execution Time: {result.get('executionTime', 0)}ms")

# Save images
if "output" in result and "images" in result["output"]:
    for idx, img in enumerate(result["output"]["images"]):
        if img["type"] == "base64":
            # Decode and save base64 image
            image_data = base64.b64decode(img["data"])
            filename = f"output_{idx}_{img['filename']}"
            Path(filename).write_bytes(image_data)
            print(f"Saved: {filename}")
        else:
            # S3 URL
            print(f"S3 URL: {img['data']}")
```

Run:

```bash
python test_endpoint.py
```

## 📊 Understanding the Response

### Successful Response

```json
{
  "id": "sync-abc123-def456",
  "status": "COMPLETED",
  "output": {
    "images": [
      {
        "filename": "ComfyUI_00001_.png",
        "type": "base64",
        "data": "iVBORw0KGgoAAAANSUhEUg..."
      }
    ]
  },
  "delayTime": 1234,
  "executionTime": 8765
}
```

**Fields**:

- `id`: Unique job ID
- `status`: `COMPLETED`, `FAILED`, or `IN_PROGRESS`
- `output.images`: Array of generated images
  - `filename`: Original ComfyUI filename
  - `type`: `base64` or `s3_url`
  - `data`: Image data or URL
- `delayTime`: Time waiting in queue (ms)
- `executionTime`: Time to process (ms)

### Error Response

```json
{
  "id": "sync-abc123-def456",
  "status": "FAILED",
  "error": "Error message describing what went wrong"
}
```

## 🎯 Pony Diffusion V6 XL Best Practices

### Prompt Template

Always use quality tags for best results:

```
score_9, score_8_up, score_7_up, score_6_up, score_5_up, score_4_up, [your description]
```

**Example Prompts**:

```json
// Positive Prompt
"score_9, score_8_up, score_7_up, source_pony, anthro pony, rainbow mane, flying through clouds, detailed background, high quality"

// Negative Prompt
"score_1, score_2, score_3, blurry, low quality, watermark, signature"
```

### Source Tags

Add source tags to influence style:

- `source_pony` - MLP style
- `source_anime` - Anime style
- `source_furry` - Furry art style
- `source_cartoon` - Cartoon style

### Rating Tags

Control content rating:

- `rating_safe` - SFW content
- `rating_questionable` - Suggestive
- `rating_explicit` - NSFW (respect license restrictions!)

### Recommended Settings

```json
{
  "sampler_name": "euler_ancestral",
  "steps": 25,
  "cfg": 7.0,
  "width": 1024,
  "height": 1024
}
```

## 🔄 Async vs Sync Endpoints

### Synchronous (`/runsync`)

**Use when**: You want to wait for the result immediately

```bash
POST https://api.runpod.ai/v2/{ENDPOINT_ID}/runsync
```

- Blocks until job completes
- Returns result directly
- Timeout: 60 seconds default
- Good for: Interactive applications, testing

### Asynchronous (`/run`)

**Use when**: You have long-running jobs or want to batch requests

```bash
# Submit job
POST https://api.runpod.ai/v2/{ENDPOINT_ID}/run

# Response
{
  "id": "job-abc123",
  "status": "IN_QUEUE"
}

# Check status
GET https://api.runpod.ai/v2/{ENDPOINT_ID}/status/job-abc123

# Cancel job (if needed)
POST https://api.runpod.ai/v2/{ENDPOINT_ID}/cancel/job-abc123
```

**PowerShell Example**:

```powershell
# Submit async job
$jobResponse = Invoke-RestMethod `
    -Uri "https://api.runpod.ai/v2/$ENDPOINT_ID/run" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $API_KEY"
        "Content-Type" = "application/json"
    } `
    -Body $body

$jobId = $jobResponse.id
Write-Host "Job ID: $jobId"

# Poll for completion
do {
    Start-Sleep -Seconds 2
    $status = Invoke-RestMethod `
        -Uri "https://api.runpod.ai/v2/$ENDPOINT_ID/status/$jobId" `
        -Headers @{ "Authorization" = "Bearer $API_KEY" }

    Write-Host "Status: $($status.status)"
} while ($status.status -eq "IN_PROGRESS" -or $status.status -eq "IN_QUEUE")

# Get result
Write-Host "Final status: $($status.status)"
```

## 📤 Including Input Images

You can send input images to use in workflows:

```json
{
  "input": {
    "workflow": {
      /* your workflow */
    },
    "images": [
      {
        "name": "input_image.png",
        "image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUg..."
      }
    ]
  }
}
```

Reference in workflow using "Load Image" node with filename `input_image.png`.

**Note**: RunPod has request size limits:

- `/runsync`: 20MB
- `/run`: 10MB

For large images, consider hosting externally and downloading in workflow.

## 🔍 Monitoring and Debugging

### Check Logs

View logs in RunPod dashboard:

1. Go to your endpoint
2. Click **Logs** tab
3. Filter by time range

Set `COMFY_LOG_LEVEL=DEBUG` for detailed logs.

### Common Issues

**Issue**: "Workflow validation failed"

- **Solution**: Export workflow using API format, not regular format

**Issue**: "Model not found: ponyDiffusionV6XL.safetensors"

- **Solution**: Verify model was downloaded in Docker image, rebuild if needed

**Issue**: "CUDA out of memory"

- **Solution**: Use smaller resolution or upgrade to GPU with more VRAM

**Issue**: "Request timeout"

- **Solution**: Use `/run` async endpoint for long generations

## 📊 Performance Tips

1. **Batch Generation**: Generate multiple images in one workflow
2. **Reuse Workers**: Keep `REFRESH_WORKER=false` for faster subsequent requests
3. **Optimize Workflow**: Remove unnecessary nodes
4. **Use S3**: Reduce network transfer by uploading to S3 (see [Configuration Guide](./03-configuration-guide.md))

## 🔐 Security Best Practices

1. **Never commit API keys** to version control
2. **Use environment variables** for sensitive data
3. **Rotate keys** regularly
4. **Monitor usage** in RunPod dashboard to detect unusual activity
5. **Set budget limits** in RunPod account settings

---

**Next Steps**:

- [Configuration Guide](./03-configuration-guide.md) - Set up S3 and other options
- [Workflow Examples](./05-workflow-examples.md) - Ready-to-use workflows
