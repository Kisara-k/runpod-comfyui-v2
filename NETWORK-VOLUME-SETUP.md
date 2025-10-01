# Network Volume Setup Guide

## Setting Up Pony Diffusion V6 XL with RunPod Network Volumes

This guide shows you how to set up a Network Volume with Pony Diffusion V6 XL for use with the pre-built `worker-comfyui` serverless endpoint.

**No Docker building required!** You'll use the official pre-built worker image.

## 📋 What You'll Need

- RunPod account with credits
- Pony Diffusion V6 XL model file (download from [CivitAI](https://civitai.com/models/257749/pony-diffusion-v6-xl))
- About 30 minutes for setup

## 🗂️ Step 1: Create Network Volume

1. **Go to Network Volumes**:

   - Navigate to: https://www.runpod.io/console/user/storage
   - Click **+ Network Volume**

2. **Configure Volume**:

   - **Name**: `comfyui-pony-models`
   - **Region**: Choose closest to you (must match your endpoint region later)
   - **Size**: `20 GB` minimum (for Pony V6 XL + VAE)
   - **Size**: `50 GB` recommended (if you want to add LoRAs later)

3. **Create**: Click **Create** button

**Monthly Cost**: ~$2/month for 20GB (very affordable!)

## 📤 Step 2: Upload Models to Network Volume

### Option A: Download Directly on RunPod (Recommended)

#### 2.1 Create Temporary Pod

1. Go to: https://www.runpod.io/console/pods
2. Click **+ Deploy**
3. Select Template: **RunPod Pytorch** (or any Linux template)
4. Select GPU: **Any cheap option** (RTX 3060 Ti is fine - we just need it for file transfer)
5. **Important**: Under **Select Network Volume**, choose your `comfyui-pony-models` volume
6. Click **Deploy On-Demand**

#### 2.2 Connect to Pod

1. Wait for pod to start (green "Running" status)
2. Click **Connect** button
3. Click **Start Web Terminal** (or use SSH if you prefer)

#### 2.3 Create Directory Structure

In the terminal, run:

```bash
# Navigate to workspace (this is your Network Volume mount point)
cd /workspace

# Create ComfyUI model directories
mkdir -p models/checkpoints
mkdir -p models/vae
mkdir -p models/loras
mkdir -p models/embeddings
```

#### 2.4 Download Pony Diffusion V6 XL

```bash
# Download main checkpoint
cd /workspace/models/checkpoints

# Pony Diffusion V6 XL (6.46 GB)
wget -O ponyDiffusionV6XL.safetensors \
  "https://civitai.com/api/download/models/290640"
```

**This will take 5-15 minutes depending on speed.**

#### 2.5 Download SDXL VAE (Recommended)

```bash
cd /workspace/models/vae

# Download SDXL VAE
wget -O sdxl_vae.safetensors \
  "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors"
```

#### 2.6 Verify Files

```bash
# Check checkpoint
ls -lh /workspace/models/checkpoints/
# Should show: ponyDiffusionV6XL.safetensors (6.5 GB)

# Check VAE
ls -lh /workspace/models/vae/
# Should show: sdxl_vae.safetensors (319 MB)
```

#### 2.7 Terminate Temporary Pod

**Important**: Your files are saved on the Network Volume, so terminating the pod is safe!

1. Go back to Pods dashboard
2. Click **Terminate** on your temporary pod
3. Confirm termination

Your models remain on the Network Volume and will be available to any pod/endpoint that mounts it.

### Option B: Upload from Your Computer

If you already have the models downloaded locally:

#### 2.1 Create Temporary Pod (same as Option A)

#### 2.2 Use File Browser or SFTP

**Using Web File Browser**:

1. In pod, click **Connect** → **HTTP Service [Port 8888]**
2. Navigate to `/workspace/models/checkpoints/`
3. Upload `ponyDiffusionV6XL.safetensors`
4. Navigate to `/workspace/models/vae/`
5. Upload `sdxl_vae.safetensors`

**Using SFTP** (for large files):

1. Get pod SSH connection details
2. Use FileZilla, WinSCP, or command-line SFTP
3. Upload to `/workspace/models/checkpoints/` and `/workspace/models/vae/`

#### 2.3 Terminate Pod

Same as Option A, step 2.7

## ✅ Step 3: Verify Directory Structure

Your Network Volume should now contain:

```
/workspace/
└── models/
    ├── checkpoints/
    │   └── ponyDiffusionV6XL.safetensors  (6.46 GB)
    ├── vae/
    │   └── sdxl_vae.safetensors           (319 MB)
    ├── loras/
    │   └── (add LoRAs here later)
    └── embeddings/
        └── (add embeddings here later)
```

## 🎯 Step 4: Ready for Deployment!

Your Network Volume is now ready. Next steps:

1. **Create RunPod Template** with pre-built image: `runpod/worker-comfyui:5.4.1-sdxl`
2. **Create Endpoint** and attach your Network Volume
3. **Start generating** images!

See the [Deployment Guide](./docs/01-deployment-guide.md) for complete endpoint setup.

## 🔄 Adding More Models Later

### Adding LoRAs

1. Create temporary pod with Network Volume
2. Download LoRA:
   ```bash
   cd /workspace/models/loras
   wget -O my_lora.safetensors "https://civitai.com/api/download/models/VERSION_ID"
   ```
3. Terminate pod
4. Use in workflows immediately!

### Adding More Checkpoints

```bash
cd /workspace/models/checkpoints
wget -O another_model.safetensors "URL_HERE"
```

### Adding Embeddings

```bash
cd /workspace/models/embeddings
wget -O embedding.pt "URL_HERE"
```

## 💡 Tips & Best Practices

### Cost Optimization

- **Terminate temporary pods** immediately after uploading
- **Share Network Volume** across multiple endpoints (same region)
- **Start with 20GB**, expand if needed (can resize later)

### File Management

- **Use clear filenames** (e.g., `ponyDiffusionV6XL.safetensors`, not `model.safetensors`)
- **Organize by type** (checkpoints, loras, vae, etc.)
- **Check file sizes** to ensure complete downloads

### Region Selection

- **Match endpoint region** to Network Volume region (critical!)
- **Choose closest** to you for lowest latency
- **US-East** usually has most GPU availability

## 🆘 Troubleshooting

### "wget: command not found"

**Solution**: Try with `curl`:

```bash
curl -L -o ponyDiffusionV6XL.safetensors \
  "https://civitai.com/api/download/models/290640"
```

### Download Interrupted

**Solution**: Resume with wget `-c` flag:

```bash
wget -c -O ponyDiffusionV6XL.safetensors \
  "https://civitai.com/api/download/models/290640"
```

### File Size Wrong

**Check expected size**:

- Pony Diffusion V6 XL: ~6.5 GB
- SDXL VAE: ~319 MB

**Re-download if size doesn't match**:

```bash
rm ponyDiffusionV6XL.safetensors
wget -O ponyDiffusionV6XL.safetensors "URL"
```

### Network Volume Not Showing in Endpoint

**Solutions**:

- Ensure Network Volume and Endpoint are in **same region**
- Refresh the endpoint creation page
- Check Network Volume status is "Active"

## 📊 Cost Comparison

### Network Volume Approach (What we're doing)

- **Setup cost**: $0 (just temporary pod time: ~$0.10)
- **Storage cost**: $2/month for 20GB
- **Flexibility**: ✅ Easy to update models
- **Sharing**: ✅ One volume for multiple endpoints

### Docker Build Approach (Alternative - Not Recommended)

- **Setup cost**: Time + local resources
- **Storage cost**: $0 (models in container)
- **Flexibility**: ❌ Must rebuild for model changes
- **Sharing**: ❌ Separate image for each model set

**Winner**: Network Volume (much more flexible!) 🏆

## ✨ Advantages of Network Volume Approach

✅ **No Docker knowledge needed**  
✅ **Easy model updates** - just upload new files  
✅ **Share across endpoints** - one volume, many uses  
✅ **Faster deployment** - no image building  
✅ **Lower storage costs** - $2/month vs rebuilding images  
✅ **Officially supported** - standard RunPod workflow

---

**Next**: [Deployment Guide](./docs/01-deployment-guide.md) - Create your serverless endpoint!
