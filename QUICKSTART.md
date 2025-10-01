# Quick Start - Pony Diffusion V6 XL on RunPod Serverless

## Get Your First Image in 30 Minutes!

This guide gets you from zero to generating images with Pony Diffusion V6 XL on RunPod serverless in about 30 minutes.

**No Docker knowledge required!** ✨

## ⚡ What You'll Need (5 minutes to gather)

1. **RunPod Account** - [Sign up here](https://runpod.io) (free, credit card required)
2. **RunPod Credits** - Add ~$5 to start
3. **Pony Diffusion V6 XL** - Download from [CivitAI](https://civitai.com/models/257749/pony-diffusion-v6-xl)
   - Click "Download" button
   - Select "V6" version
   - File size: ~6.5GB

**Optional but recommended**:

- SDXL VAE (auto-downloaded in step 2)

## 📁 Step 1: Create Network Volume & Upload Model (15 minutes)

### 1.1 Create Network Volume

1. Go to [RunPod Network Volumes](https://www.runpod.io/console/user/storage)
2. Click **+ Network Volume**
3. Configure:
   - Name: `comfyui-models`
   - Region: `US-East` (or closest to you)
   - Size: `20 GB`
4. Click **Create**

### 1.2 Upload Pony V6 XL Model

1. Go to [Pods](https://www.runpod.io/console/pods)
2. Click **+ Deploy**
3. Select **RunPod Pytorch** template
4. Select any cheap GPU (RTX 3060 Ti is fine)
5. **Attach Network Volume**: Select `comfyui-models`
6. Click **Deploy On-Demand**
7. Wait for pod to start (~1 min)
8. Click **Connect** → **Start Web Terminal**

### 1.3 Download Models in Terminal

Copy and paste these commands:

```bash
# Create directories
cd /workspace
mkdir -p models/checkpoints models/vae

# Download Pony Diffusion V6 XL
cd /workspace/models/checkpoints
wget -O ponyDiffusionV6XL.safetensors \
  "https://civitai.com/api/download/models/290640"

# Download SDXL VAE
cd /workspace/models/vae
wget -O sdxl_vae.safetensors \
  "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors"

# Verify (should show 6.5GB and 319MB)
ls -lh /workspace/models/checkpoints/
ls -lh /workspace/models/vae/
```

### 1.4 Terminate Pod

Go back to Pods dashboard and **Terminate** your temporary pod.  
✅ Your models stay on the Network Volume!

## 🌐 Step 2: Create Serverless Endpoint (5 minutes)

### 2.1 Create Template

1. Go to [Templates](https://runpod.io/console/serverless/user/templates)
2. Click **New Template**
3. Fill in:
   - **Name**: `Pony V6 XL`
   - **Type**: **Serverless**
   - **Image**: `runpod/worker-comfyui:5.4.1-sdxl`
   - **Container Disk**: `10 GB`
4. Click **Save Template**

### 2.2 Create Endpoint

1. Go to [Endpoints](https://www.runpod.io/console/serverless/user/endpoints)
2. Click **New Endpoint**
3. Fill in:
   - **Name**: `pony-v6`
   - **Template**: `Pony V6 XL`
   - **GPU**: Select **RTX 4090** (best price/performance)
   - **Max Workers**: `3`
   - **Flash Boot**: ✅ **Enabled**
4. **Important**: Under **Advanced** → **Select Network Volume** → Choose `comfyui-models`
5. Click **Deploy**

Wait for status to show "Ready" (~1 minute)

## 🔑 Step 3: Get API Credentials (2 minutes)

### 3.1 Create API Key

1. Go to [Settings](https://www.runpod.io/console/serverless/user/settings)
2. Find **API Keys** section
3. Click **Create API Key**
4. Name: `ComfyUI Test`
5. Click **Create**
6. **COPY THE KEY** (you won't see it again!)

### 3.2 Get Endpoint ID

1. Go to your [Endpoints](https://www.runpod.io/console/serverless/user/endpoints)
2. Click on `pony-v6`
3. Copy the **Endpoint ID** (near the top)

## 🎨 Step 4: Generate Your First Image! (2 minutes)

### Option A: Using PowerShell (Windows)

```powershell
# Set your credentials
$env:RUNPOD_API_KEY = "your-api-key-here"
$env:RUNPOD_ENDPOINT_ID = "your-endpoint-id-here"

# Clone or download this repository if you haven't
# Then run from project root:
cd "d:\Core\_Code D\runpod-comfyui-v2"
.\examples\test-endpoint.ps1
```

### Option B: Using cURL (Any Platform)

Save this as `test.json`:

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
          "text": "score_9, score_8_up, score_7_up, a magical pony with rainbow mane flying through clouds",
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
          "filename_prefix": "Pony",
          "images": ["8", 0]
        },
        "class_type": "SaveImage"
      }
    }
  }
}
```

Then run:

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR-API-KEY" \
  -H "Content-Type: application/json" \
  -d @test.json \
  https://api.runpod.ai/v2/YOUR-ENDPOINT-ID/runsync
```

## ✅ Success!

If everything worked, you should see:

- ✅ Status: `COMPLETED`
- ✅ Execution Time: ~8-12 seconds
- ✅ Base64 image data in response

**First request may take 20-30 seconds** (cold start - loading models).  
**Subsequent requests**: ~8 seconds (worker stays warm)

## 💰 Cost Breakdown

What you just spent:

- Network Volume (20GB): **$2/month**
- Temporary pod (~10 min): **~$0.10**
- Test generation (~10 sec): **~$0.002**

**Total setup cost**: ~$0.12  
**Monthly cost**: $2 + usage

**Per image cost** (RTX 4090):

- 1024×1024, 25 steps: ~$0.0018 (0.18 cents)
- 100 images: $0.18
- 1000 images: $1.80

**Idle cost when not generating**: $0 (serverless!)

## 🎯 What You Can Do Now

### Try Different Prompts

Edit the workflow JSON, find the positive prompt (node `6`):

```json
"text": "score_9, score_8_up, score_7_up, YOUR PROMPT HERE"
```

**Example Prompts**:

- `source_pony, twilight_sparkle, library background, reading book`
- `source_anime, 1girl, long blue hair, cherry blossoms`
- `anthro wolf, forest background, moonlight, detailed fur`

### Change Resolution

Edit node `5`:

```json
"inputs": {
  "width": 832,   // Portrait
  "height": 1216,
  "batch_size": 1
}
```

### Add LoRAs

1. Download LoRA to your Network Volume (create temp pod)
2. Add LoraLoader node to workflow
3. Generate with enhanced features!

See [Workflow Examples](./docs/05-workflow-examples.md) for more ideas.

## 📚 Learn More

Now that you're up and running:

1. **[Deployment Guide](./docs/01-deployment-guide.md)** - Detailed deployment info
2. **[Usage Guide](./docs/02-usage-guide.md)** - API reference and examples
3. **[Workflow Examples](./docs/05-workflow-examples.md)** - Ready-to-use workflows
4. **[Configuration Guide](./docs/03-configuration-guide.md)** - S3 upload, env vars
5. **[Troubleshooting](./docs/04-troubleshooting-guide.md)** - Common issues

## 🆘 Something Not Working?

### "Model not found"

**Check**:

1. Network Volume is attached to endpoint
2. File path is `/workspace/models/checkpoints/ponyDiffusionV6XL.safetensors`
3. File downloaded completely (check size ~6.5GB)

### Workers Not Starting

**Try**:

1. Different GPU type (RTX 3090, A5000)
2. Check RunPod credits
3. Verify region has GPU availability

### Slow First Request

**This is normal!**

- First request: 20-30s (cold start)
- Subsequent: 6-8s (warm worker)
- Solution: Enable Flash Boot (already did in step 2!)

### Invalid API Key

**Check**:

1. API key copied correctly (no extra spaces)
2. Using `Bearer` prefix in authorization header
3. API key not expired/deleted

## ✨ Tips for Best Results

### Prompt Engineering

Always use quality tags for Pony V6 XL:

```
score_9, score_8_up, score_7_up, score_6_up, score_5_up, score_4_up, [your description]
```

### Recommended Settings

- **Sampler**: Euler a (`euler_ancestral`)
- **Steps**: 25
- **CFG Scale**: 7.0
- **CLIP Skip**: 2 (or -2) - **Critical!**

### Source Tags

Control the style:

- `source_pony` - MLP style
- `source_anime` - Anime style
- `source_furry` - Furry art style

## 🎉 You're All Set!

You now have:

- ✅ Serverless ComfyUI endpoint
- ✅ Pony Diffusion V6 XL loaded
- ✅ API credentials ready
- ✅ First image generated

**Start creating!** 🎨✨

---

**Questions?** Check the [full documentation](./docs/) or RunPod Discord (#serverless-help).

**Enjoying this setup?** Star the [worker-comfyui repo](https://github.com/runpod-workers/worker-comfyui)!
