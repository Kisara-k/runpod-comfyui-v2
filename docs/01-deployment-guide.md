# Deployment Guide - Pony Diffusion V6 XL on RunPod Serverless

## Using Pre-Built Worker (No Docker Build Required!)

This guide shows you how to deploy Pony Diffusion V6 XL using the **official pre-built worker-comfyui image** and a **Network Volume** for model storage.

**✨ No Docker building, no Docker knowledge needed!**

## 📋 Prerequisites

- ✅ RunPod account ([sign up](https://runpod.io))
- ✅ RunPod credits (~$5 to start)
- ✅ Network Volume with Pony V6 XL (see [Network Volume Setup](../NETWORK-VOLUME-SETUP.md))

**Don't have your Network Volume set up yet?** Follow the [Network Volume Setup Guide](../NETWORK-VOLUME-SETUP.md) first (takes ~30 minutes).

## 🎯 Overview

We'll use these pre-built components:

- **Worker**: `runpod/worker-comfyui:5.4.1-sdxl` (official image)
- **Models**: On your Network Volume
- **No custom code**: Just configuration!

Total deployment time: **~10 minutes**

## 🐳 Step 1: Create RunPod Template (3 minutes)

### 1.1 Navigate to Templates

1. Go to: https://runpod.io/console/serverless/user/templates
2. Click **New Template**

### 1.2 Configure Template Settings

| Field                              | Value                              | Notes                    |
| ---------------------------------- | ---------------------------------- | ------------------------ |
| **Template Name**                  | `Pony Diffusion V6 XL - ComfyUI`   | Your choice              |
| **Template Type**                  | **Serverless**                     | ⚠️ Switch from "Pods"    |
| **Container Image**                | `runpod/worker-comfyui:5.4.1-sdxl` | Official pre-built image |
| **Container Registry Credentials** | (Leave empty)                      | Public image             |
| **Container Disk**                 | `10 GB`                            | Just for worker code     |

**Image Tag Options**:

- `5.4.1-sdxl` - Includes SDXL base model (good for SDXL-based models like Pony V6)
- `5.4.1-base` - Clean install, no models
- Latest version: Check [releases](https://github.com/runpod-workers/worker-comfyui/releases)

**We recommend**: `5.4.1-sdxl` or newer

### 1.3 Environment Variables (Optional)

You can configure these now or add later:

**Basic Configuration**:

```
COMFY_LOG_LEVEL=INFO
```

**For S3 Upload** (optional, see [Configuration Guide](./03-configuration-guide.md)):

```
BUCKET_ENDPOINT_URL=https://your-bucket.s3.region.amazonaws.com
BUCKET_ACCESS_KEY_ID=your-access-key-id
BUCKET_SECRET_ACCESS_KEY=your-secret-access-key
```

Leave environment variables empty for now if unsure.

### 1.4 Save Template

Click **Save Template** at the bottom.

## 🌐 Step 2: Create Serverless Endpoint (5 minutes)

### 2.1 Navigate to Endpoints

1. Go to: https://www.runpod.io/console/serverless/user/endpoints
2. Click **New Endpoint**

### 2.2 Basic Configuration

| Field               | Value                            | Explanation          |
| ------------------- | -------------------------------- | -------------------- |
| **Endpoint Name**   | `pony-v6-xl`                     | Your choice          |
| **Select Template** | `Pony Diffusion V6 XL - ComfyUI` | Template from Step 1 |

### 2.3 Worker Configuration

| Field              | Value          | Why                               |
| ------------------ | -------------- | --------------------------------- |
| **Active Workers** | `0`            | Auto-scale from 0 (save money!)   |
| **Max Workers**    | `3`            | Max concurrent workers            |
| **Idle Timeout**   | `5` seconds    | How long before worker shuts down |
| **Flash Boot**     | ✅ **Enabled** | 3x faster cold starts!            |
| **GPUs/Worker**    | `1`            | One GPU per worker                |

### 2.4 Select GPU

**Recommended GPUs for Pony Diffusion V6 XL:**

| GPU           | VRAM | Cost/hr\*  | Speed     | Notes                 |
| ------------- | ---- | ---------- | --------- | --------------------- |
| **RTX 4090**  | 24GB | $0.69-0.79 | ⚡ Fast   | ⭐ Best choice        |
| **RTX A5000** | 24GB | $0.79-0.89 | ⚡ Fast   | Great alternative     |
| **RTX 3090**  | 24GB | $0.59-0.69 | 🔵 Medium | Budget option         |
| **A40**       | 48GB | $0.99-1.19 | ⚡ Fast   | Overkill but reliable |

\*Prices vary by region and availability

**Minimum Requirements**:

- **VRAM**: 10GB (tight, may have issues)
- **Recommended**: 16GB+ for safety
- **Optimal**: 24GB for batch generation

**Choose**: RTX 4090 for best price/performance ratio.

### 2.5 Advanced Settings - ATTACH NETWORK VOLUME

**🔥 This is the critical step!**

1. Scroll down to **Advanced** section
2. Find **Select Network Volume**
3. Choose your `comfyui-pony-models` volume (or whatever you named it)
4. ⚠️ **Verify the region matches** your endpoint region

If you don't see your Network Volume:

- Check they're in the same region
- Refresh the page
- Verify Network Volume status is "Active"

### 2.6 Deploy Endpoint

Click **Deploy** button.

Your endpoint will:

- ✅ Start in "Initializing" status
- ✅ Mount your Network Volume at `/workspace`
- ✅ Load the worker-comfyui handler
- ✅ Change to "Ready" status when complete (~1 minute)

## 🔑 Step 3: Get API Credentials (2 minutes)

### 3.1 Create API Key

1. Go to: https://www.runpod.io/console/serverless/user/settings
2. Click **API Keys** section
3. Click **Create API Key**
4. **Name**: `ComfyUI Pony V6`
5. Click **Create**
6. **⚠️ COPY THE KEY NOW** - you can't see it again!

Save it somewhere secure (password manager recommended).

### 3.2 Get Endpoint ID

1. Go back to: https://www.runpod.io/console/serverless/user/endpoints
2. Click on your `pony-v6-xl` endpoint
3. Find **Endpoint ID** near the top (format: `abc123xyz789`)
4. Copy and save it

**You now have**:

- ✅ API Key: `sk-xxxxx...`
- ✅ Endpoint ID: `abc123xyz789`

## ✅ Step 4: Test Your Endpoint (2 minutes)

### 4.1 Check Health

Test that your endpoint is alive:

**PowerShell**:

```powershell
curl https://api.runpod.ai/v2/YOUR-ENDPOINT-ID/health
```

**Expected Response**:

```json
{ "status": "healthy" }
```

### 4.2 Test with Workflow

**Quick Test (PowerShell)**:

```powershell
# Set your credentials
$env:RUNPOD_API_KEY = "your-api-key-here"
$env:RUNPOD_ENDPOINT_ID = "your-endpoint-id-here"

# Run test script (from project root)
.\examples\test-endpoint.ps1
```

This will:

1. Send a test workflow to your endpoint
2. Wait for generation to complete
3. Save the generated image to `output/` folder

**First request** may take 20-30 seconds (cold start).  
**Subsequent requests** take 8-12 seconds (warm worker).

### 4.3 Verify Output

Check the `output/` folder for your generated image!

If it worked, you should see:

- ✅ Status: COMPLETED
- ✅ Execution Time: ~8-12 seconds
- ✅ Image file saved

## 🎉 Deployment Complete!

Your serverless endpoint is now live and ready to use!

### What You Can Do Now

1. **Generate images** - See [Usage Guide](./02-usage-guide.md)
2. **Try different workflows** - See [Workflow Examples](./05-workflow-examples.md)
3. **Configure S3 upload** - See [Configuration Guide](./03-configuration-guide.md)
4. **Integrate into your app** - Use the API from any language

## 💰 Cost Breakdown

### Fixed Monthly Costs

- **Network Volume** (20GB): ~$2.00/month
- **RunPod Account**: $0 (free tier available)

### Variable Usage Costs (RTX 4090 @ $0.79/hour)

- **Per Image** (1024×1024, 25 steps, ~8s): $0.0018 (0.18 cents)
- **100 Images**: $0.18
- **1,000 Images**: $1.80
- **10,000 Images**: $18.00

### Idle Costs

- **Workers at 0**: $0.00 (true serverless!)
- **Workers scale up**: Only when you send requests
- **Workers scale down**: After 5 seconds idle (configurable)

**Total Monthly**: ~$2 + usage  
**Example**: $2 + $1.80 for 1,000 images = **$3.80/month** 🎯

## 🔄 Updating Your Setup

### Change Models

1. Create temporary pod with Network Volume attached
2. Upload/download new models to `/workspace/models/`
3. Terminate pod
4. Models available immediately (no endpoint restart needed!)

### Update Worker Version

1. Edit your template
2. Change image tag (e.g., `5.5.0-sdxl`)
3. Save
4. Existing endpoints use old version until you create new endpoint

### Add LoRAs

```bash
# In temporary pod with Network Volume
cd /workspace/models/loras
wget -O my_lora.safetensors "https://civitai.com/api/download/models/VERSION_ID"
```

Use immediately in your workflows!

## 📊 GPU Recommendations by Use Case

### Personal Projects / Testing

- **GPU**: RTX 3090 (24GB)
- **Cost**: ~$0.69/hr
- **Good for**: Learning, testing, low volume

### Production / High Volume

- **GPU**: RTX 4090 (24GB)
- **Cost**: ~$0.79/hr
- **Good for**: Best price/performance, reliability

### Batch Processing / Multiple Images

- **GPU**: A40 (48GB)
- **Cost**: ~$1.09/hr
- **Good for**: Generating multiple images simultaneously

### Budget / Occasional Use

- **GPU**: RTX 3060 Ti (12GB) - if available
- **Cost**: ~$0.39/hr
- **Good for**: Small images, low CFG, basic workflows
- **⚠️ Warning**: May run out of VRAM with large batches

## 🆘 Troubleshooting

### "Model not found: ponyDiffusionV6XL.safetensors"

**Cause**: Network Volume not attached or wrong path

**Solution**:

1. Verify Network Volume is attached in endpoint Advanced settings
2. Check file exists: `/workspace/models/checkpoints/ponyDiffusionV6XL.safetensors`
3. Verify filename matches exactly (case-sensitive!)
4. Check file size is ~6.5GB (full download)

### Workers Not Starting

**Possible causes**:

- Selected GPU not available
- Insufficient RunPod credits
- Region mismatch

**Solutions**:

1. Try different GPU type
2. Check credit balance
3. Try different region
4. Check RunPod status: https://status.runpod.io

### First Request Very Slow (30-60s)

**This is normal!** Cold start includes:

- Worker initialization
- Model loading from Network Volume
- First-time caching

**Solutions**:

- ✅ Enable Flash Boot (reduces to ~20s)
- Keep Active Workers at 1+ (instant responses)
- Accept cold starts as normal for serverless

### Subsequent Requests Still Slow

**Check**:

1. Is `REFRESH_WORKER=true`? (Change to `false`)
2. Are workers scaling down too quickly? (Increase idle timeout)
3. Is Network Volume in same region as endpoint?

## ✨ Advantages of This Approach

✅ **No Docker knowledge required**  
✅ **No image building** - uses official worker  
✅ **Easy model updates** - just upload to Network Volume  
✅ **Cost effective** - $2/month + usage  
✅ **Officially supported** - standard RunPod workflow  
✅ **Fast deployment** - 10 minutes total  
✅ **Flexible** - change models without rebuilding  
✅ **Scalable** - 0 to N workers automatically

## 📈 Performance Benchmarks

**Expected Generation Times** (1024×1024, 25 steps):

| GPU       | Time   | Cost/Image     |
| --------- | ------ | -------------- |
| RTX 4090  | 6-8s   | $0.0013-0.0018 |
| RTX A5000 | 8-10s  | $0.0018-0.0022 |
| RTX 3090  | 10-14s | $0.0019-0.0027 |
| A40       | 12-16s | $0.0037-0.0053 |

_Times include model loading overhead for first image. Subsequent images faster._

## 🎓 Next Steps

Now that your endpoint is deployed:

1. **Learn the API**: [Usage Guide](./02-usage-guide.md)

   - Send requests
   - Handle responses
   - Use async/sync modes

2. **Try Different Workflows**: [Workflow Examples](./05-workflow-examples.md)

   - Text-to-image
   - Image-to-image
   - LoRAs
   - Batch generation

3. **Configure S3**: [Configuration Guide](./03-configuration-guide.md)

   - Upload images to S3
   - Reduce costs
   - No size limits

4. **Optimize**: [Troubleshooting Guide](./04-troubleshooting-guide.md)
   - Performance tips
   - Cost optimization
   - Common issues

---

**Congratulations! You're running Pony Diffusion V6 XL serverlessly! 🎉**

Need help? Check the [Troubleshooting Guide](./04-troubleshooting-guide.md) or RunPod Discord.
