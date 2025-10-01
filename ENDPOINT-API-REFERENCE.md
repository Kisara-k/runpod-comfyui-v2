# RunPod Endpoint API Reference

Quick reference for using your deployed RunPod ComfyUI endpoint.

## 🔑 Authentication

All requests require your API key in the Authorization header:

```
Authorization: Bearer YOUR_API_KEY
```

## 🌐 Endpoint Types

### 1. Synchronous Endpoint (`/runsync`)

**URL**: `https://api.runpod.ai/v2/{ENDPOINT_ID}/runsync`

**Best for**: Quick jobs that complete in under 90 seconds

**Request**:

```json
POST /v2/{ENDPOINT_ID}/runsync
{
  "input": {
    "workflow": { ... }
  }
}
```

**Response** (immediate):

```json
{
  "id": "job-id",
  "status": "COMPLETED",
  "output": {
    "images": ["base64_encoded_image_data"]
  },
  "executionTime": 15000
}
```

**Timeout**: 90 seconds max

---

### 2. Async Endpoint (`/run` + polling)

**Submit URL**: `https://api.runpod.ai/v2/{ENDPOINT_ID}/run`  
**Status URL**: `https://api.runpod.ai/v2/{ENDPOINT_ID}/status/{JOB_ID}`

**Best for**: Longer jobs, guaranteed execution, better queue handling

#### Step 1: Submit Job

```json
POST /v2/{ENDPOINT_ID}/run
{
  "input": {
    "workflow": { ... }
  }
}
```

**Response** (immediate):

```json
{
  "id": "job-id-12345",
  "status": "IN_QUEUE"
}
```

#### Step 2: Poll for Results

```
GET /v2/{ENDPOINT_ID}/status/job-id-12345
```

**Response** (while processing):

```json
{
  "id": "job-id-12345",
  "status": "IN_PROGRESS"
}
```

**Response** (when complete):

```json
{
  "id": "job-id-12345",
  "status": "COMPLETED",
  "output": {
    "images": ["base64_encoded_image_data"]
  },
  "executionTime": 15000
}
```

**Status Values**:

- `IN_QUEUE` - Job queued, waiting for worker
- `IN_PROGRESS` - Worker is processing
- `COMPLETED` - Job finished successfully
- `FAILED` - Job failed (check error field)

**Polling Strategy**:

- Poll every 2-5 seconds
- Typical generation time: 10-30 seconds
- Set reasonable timeout (e.g., 300 seconds)

---

## 📊 Request Format

### ComfyUI Workflow Structure

The `workflow` object is a ComfyUI API format workflow:

```json
{
  "input": {
    "workflow": {
      "3": {
        "inputs": {
          "seed": 42,
          "steps": 25,
          "cfg": 7.0,
          "sampler_name": "euler_ancestral",
          "scheduler": "normal",
          "denoise": 1,
          "model": ["4", 0],
          "positive": ["6", 0],
          "negative": ["7", 0],
          "latent_image": ["5", 0]
        },
        "class_type": "KSampler"
      },
      "4": {
        "inputs": {
          "ckpt_name": "ponyDiffusionV6XL.safetensors",
          "stop_at_clip_layer": -2
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
          "text": "score_9, score_8_up, your prompt here",
          "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode"
      },
      "7": {
        "inputs": {
          "text": "score_1, score_2, score_3, negative tags",
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
          "filename_prefix": "PonyV6",
          "images": ["8", 0]
        },
        "class_type": "SaveImage"
      }
    }
  }
}
```

### Key Parameters for Pony Diffusion V6 XL

| Parameter         | Location | Value                           | Notes                               |
| ----------------- | -------- | ------------------------------- | ----------------------------------- |
| **Checkpoint**    | Node 4   | `ponyDiffusionV6XL.safetensors` | Must match your Network Volume      |
| **CLIP Skip**     | Node 4   | `-2`                            | Required for Pony V6                |
| **Resolution**    | Node 5   | 1024x1024 (or SDXL sizes)       | 1024x1024, 832x1216, 1216x832, etc. |
| **Sampler**       | Node 3   | `euler_ancestral`               | Recommended                         |
| **Steps**         | Node 3   | 25-30                           | Good quality/speed balance          |
| **CFG Scale**     | Node 3   | 7.0                             | Recommended                         |
| **Quality Tags**  | Node 6   | `score_9, score_8_up, ...`      | Required in positive prompt         |
| **Negative Tags** | Node 7   | `score_1, score_2, score_3`     | Required in negative prompt         |

---

## 📦 Response Format

### Success Response

```json
{
  "id": "unique-job-id",
  "status": "COMPLETED",
  "output": {
    "images": [
      "iVBORw0KGgoAAAANSUhEUgAAA..." // Base64 encoded PNG
    ]
  },
  "executionTime": 15432
}
```

### Error Response

```json
{
  "id": "unique-job-id",
  "status": "FAILED",
  "error": "Error message describing what went wrong"
}
```

---

## 💡 Code Examples

### Python (Synchronous)

```python
import requests
import base64
from PIL import Image
from io import BytesIO

API_KEY = "your_api_key"
ENDPOINT_ID = "your_endpoint_id"
url = f"https://api.runpod.ai/v2/{ENDPOINT_ID}/runsync"

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

payload = {
    "input": {
        "workflow": { ... }  # Your workflow here
    }
}

response = requests.post(url, json=payload, headers=headers, timeout=120)
result = response.json()

# Decode and display image
if result['status'] == 'COMPLETED':
    img_data = base64.b64decode(result['output']['images'][0])
    img = Image.open(BytesIO(img_data))
    img.save('output.png')
```

### Python (Async with Polling)

```python
import requests
import time

API_KEY = "your_api_key"
ENDPOINT_ID = "your_endpoint_id"
run_url = f"https://api.runpod.ai/v2/{ENDPOINT_ID}/run"
status_url = f"https://api.runpod.ai/v2/{ENDPOINT_ID}/status"

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

# Submit job
payload = {"input": {"workflow": {...}}}
response = requests.post(run_url, json=payload, headers=headers)
job_id = response.json()['id']

# Poll for results
while True:
    status_response = requests.get(f"{status_url}/{job_id}", headers=headers)
    result = status_response.json()

    if result['status'] == 'COMPLETED':
        # Process result
        break
    elif result['status'] == 'FAILED':
        print(f"Error: {result['error']}")
        break

    time.sleep(2)  # Wait 2 seconds before next check
```

### PowerShell

```powershell
$apiKey = "your_api_key"
$endpointId = "your_endpoint_id"
$url = "https://api.runpod.ai/v2/$endpointId/runsync"

$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
}

$body = @{
    input = @{
        workflow = @{ ... }
    }
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
$response.output.images[0] | Out-File -FilePath "image.b64"
```

### cURL

```bash
curl -X POST "https://api.runpod.ai/v2/YOUR_ENDPOINT_ID/runsync" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "workflow": { ... }
    }
  }'
```

---

## 🎯 Best Practices

### 1. Choose the Right Endpoint Type

- **Use `/runsync`** for:
  - Fast testing
  - Simple integrations
  - Jobs under 60 seconds
- **Use `/run`** for:
  - Production environments
  - Batch processing
  - High-resolution images
  - Reliable execution

### 2. Error Handling

Always check the response status:

```python
if result['status'] == 'COMPLETED':
    # Success
elif result['status'] == 'FAILED':
    # Handle error
elif result['status'] in ['IN_QUEUE', 'IN_PROGRESS']:
    # Still processing (async only)
```

### 3. Timeouts

Set appropriate timeouts:

- `/runsync`: 90-120 seconds
- `/run` submit: 30 seconds
- `/run` polling: 300+ seconds total

### 4. Rate Limiting

- Don't poll faster than once per second
- Recommended polling interval: 2-5 seconds
- Use exponential backoff for long jobs

### 5. Image Handling

Images are returned as base64-encoded PNG data:

```python
import base64
from PIL import Image
from io import BytesIO

# Decode base64 to image
img_bytes = base64.b64decode(image_base64_string)
img = Image.open(BytesIO(img_bytes))
img.save('output.png')
```

---

## 📊 Cost Estimation

Based on RunPod pricing (example with RTX 4090):

| Resolution | Steps | Avg Time | Cost per Image |
| ---------- | ----- | -------- | -------------- |
| 1024x1024  | 25    | ~15s     | ~$0.0018       |
| 1024x1024  | 30    | ~18s     | ~$0.0022       |
| 832x1216   | 25    | ~15s     | ~$0.0018       |
| 1216x832   | 25    | ~15s     | ~$0.0018       |

**Note**: Actual costs depend on GPU type and execution time.

---

## 🔧 Troubleshooting

### Job Stuck in IN_QUEUE

- No workers available
- Check your endpoint has workers configured
- Try again during off-peak hours

### FAILED Status

Common causes:

- Model file not found (check Network Volume)
- Invalid workflow structure
- Out of memory (reduce resolution/batch size)
- Invalid parameters

### Timeout

- Increase timeout value
- Use async endpoint instead of sync
- Reduce image resolution or steps

### Empty Response

- Check API key is valid
- Verify endpoint ID is correct
- Ensure Network Volume is attached

---

## 📚 Additional Resources

- [RunPod API Documentation](https://docs.runpod.io/serverless/endpoints/job-operations)
- [ComfyUI API Documentation](https://github.com/comfyanonymous/ComfyUI)
- [Pony Diffusion V6 XL Model Card](https://civitai.com/models/257749/pony-diffusion-v6-xl)
- [Worker-ComfyUI GitHub](https://github.com/runpod-workers/worker-comfyui)
