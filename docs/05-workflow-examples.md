# Workflow Examples - Pony Diffusion V6 XL

This document provides ready-to-use ComfyUI workflow examples for Pony Diffusion V6 XL.

## 📋 Table of Contents

- [Basic Text-to-Image](#basic-text-to-image)
- [Advanced with Quality Tags](#advanced-with-quality-tags)
- [Using LoRAs](#using-loras)
- [Image-to-Image](#image-to-image)
- [Batch Generation](#batch-generation)
- [Custom Resolution](#custom-resolution)
- [How to Use These Workflows](#how-to-use-these-workflows)

## 🎨 Basic Text-to-Image

The simplest workflow for generating images.

### Features

- Single prompt input
- Default SDXL resolution (1024×1024)
- 25 steps with Euler a sampler
- CLIP Skip: 2 (required for Pony V6 XL)

### Workflow JSON

```json
{
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
    "class_type": "KSampler",
    "_meta": {
      "title": "KSampler"
    }
  },
  "4": {
    "inputs": {
      "ckpt_name": "ponyDiffusionV6XL.safetensors",
      "stop_at_clip_layer": -2
    },
    "class_type": "CheckpointLoaderSimple",
    "_meta": {
      "title": "Load Checkpoint - CLIP Skip 2"
    }
  },
  "5": {
    "inputs": {
      "width": 1024,
      "height": 1024,
      "batch_size": 1
    },
    "class_type": "EmptyLatentImage",
    "_meta": {
      "title": "Empty Latent Image"
    }
  },
  "6": {
    "inputs": {
      "text": "score_9, score_8_up, score_7_up, score_6_up, a majestic dragon flying over mountains, detailed scales, epic lighting, fantasy art",
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode",
    "_meta": {
      "title": "CLIP Text Encode (Positive Prompt)"
    }
  },
  "7": {
    "inputs": {
      "text": "score_1, score_2, score_3, blurry, low quality, watermark, signature, text",
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode",
    "_meta": {
      "title": "CLIP Text Encode (Negative Prompt)"
    }
  },
  "8": {
    "inputs": {
      "samples": ["3", 0],
      "vae": ["4", 2]
    },
    "class_type": "VAEDecode",
    "_meta": {
      "title": "VAE Decode"
    }
  },
  "9": {
    "inputs": {
      "filename_prefix": "PonyV6",
      "images": ["8", 0]
    },
    "class_type": "SaveImage",
    "_meta": {
      "title": "Save Image"
    }
  }
}
```

### API Request

```powershell
$body = @{
    input = @{
        workflow = $workflowJson  # The JSON above
    }
} | ConvertTo-Json -Depth 10

Invoke-RestMethod `
    -Uri "https://api.runpod.ai/v2/$ENDPOINT_ID/runsync" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $API_KEY"
        "Content-Type" = "application/json"
    } `
    -Body $body
```

## ⭐ Advanced with Quality Tags

Uses all recommended quality tags and source modifiers.

### Features

- Full quality tag string
- Source tag for style control
- Rating tag for content control
- Better prompt organization

### Example Prompts

**For Pony Style:**

```
Positive: score_9, score_8_up, score_7_up, score_6_up, score_5_up, score_4_up, source_pony, anthro pony, rainbow mane, blue coat, flying through clouds, detailed background, vibrant colors
Negative: score_1, score_2, score_3, blurry, low quality, bad anatomy, watermark
```

**For Anime Style:**

```
Positive: score_9, score_8_up, score_7_up, score_6_up, score_5_up, score_4_up, source_anime, 1girl, long hair, detailed eyes, cherry blossoms, spring scenery, soft lighting
Negative: score_1, score_2, score_3, blurry, low quality, bad hands, extra fingers
```

**For Furry Style:**

```
Positive: score_9, score_8_up, score_7_up, score_6_up, score_5_up, score_4_up, source_furry, anthropomorphic wolf, detailed fur, forest background, moonlight, atmospheric
Negative: score_1, score_2, score_3, blurry, low quality, deformed, bad anatomy
```

### Workflow Modification

Just update node `6` (positive prompt) and `7` (negative prompt):

```json
"6": {
  "inputs": {
    "text": "score_9, score_8_up, score_7_up, score_6_up, score_5_up, score_4_up, source_pony, YOUR_PROMPT_HERE",
    "clip": ["4", 1]
  },
  "class_type": "CLIPTextEncode"
}
```

## 🎭 Using LoRAs

Add LoRA models to enhance specific features.

### Prerequisites

Add LoRA download to your Dockerfile:

```dockerfile
# Download a popular LoRA (example)
RUN comfy model download \
    --url "https://civitai.com/api/download/models/YOUR_LORA_VERSION_ID" \
    --relative-path models/loras \
    --filename your_lora.safetensors
```

### Extended Workflow with LoRA

Add these nodes after checkpoint loading:

```json
{
  "10": {
    "inputs": {
      "lora_name": "your_lora.safetensors",
      "strength_model": 0.8,
      "strength_clip": 0.8,
      "model": ["4", 0],
      "clip": ["4", 1]
    },
    "class_type": "LoraLoader",
    "_meta": {
      "title": "Load LoRA"
    }
  }
}
```

Then update references:

- KSampler model: `["10", 0]` instead of `["4", 0]`
- CLIP encoders: `["10", 1]` instead of `["4", 1]`

### Full LoRA Workflow

```json
{
  "3": {
    "inputs": {
      "seed": 42,
      "steps": 25,
      "cfg": 7.0,
      "sampler_name": "euler_ancestral",
      "scheduler": "normal",
      "denoise": 1,
      "model": ["10", 0],
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
      "text": "score_9, score_8_up, score_7_up, score_6_up, source_pony, detailed character, vibrant colors",
      "clip": ["10", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "7": {
    "inputs": {
      "text": "score_1, score_2, score_3, blurry, low quality",
      "clip": ["10", 1]
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
      "filename_prefix": "PonyV6_LoRA",
      "images": ["8", 0]
    },
    "class_type": "SaveImage"
  },
  "10": {
    "inputs": {
      "lora_name": "your_lora.safetensors",
      "strength_model": 0.8,
      "strength_clip": 0.8,
      "model": ["4", 0],
      "clip": ["4", 1]
    },
    "class_type": "LoraLoader"
  }
}
```

## 🖼️ Image-to-Image

Start from an existing image and modify it.

### Features

- Load input image
- Adjustable denoising strength
- Maintains composition while changing details

### Workflow with Image Input

```json
{
  "3": {
    "inputs": {
      "seed": 42,
      "steps": 25,
      "cfg": 7.0,
      "sampler_name": "euler_ancestral",
      "scheduler": "normal",
      "denoise": 0.7,
      "model": ["4", 0],
      "positive": ["6", 0],
      "negative": ["7", 0],
      "latent_image": ["11", 0]
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
  "6": {
    "inputs": {
      "text": "score_9, score_8_up, score_7_up, watercolor painting, soft colors",
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "7": {
    "inputs": {
      "text": "score_1, score_2, score_3, photograph, realistic",
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
      "filename_prefix": "img2img",
      "images": ["8", 0]
    },
    "class_type": "SaveImage"
  },
  "10": {
    "inputs": {
      "image": "input_image.png",
      "upload": "image"
    },
    "class_type": "LoadImage"
  },
  "11": {
    "inputs": {
      "pixels": ["10", 0],
      "vae": ["4", 2]
    },
    "class_type": "VAEEncode"
  }
}
```

### API Request with Image

```powershell
# Read and encode image
$imageBytes = [System.IO.File]::ReadAllBytes("input.png")
$imageBase64 = [Convert]::ToBase64String($imageBytes)

$body = @{
    input = @{
        workflow = $workflowJson
        images = @(
            @{
                name = "input_image.png"
                image = "data:image/png;base64,$imageBase64"
            }
        )
    }
} | ConvertTo-Json -Depth 10
```

**Denoising strength guide**:

- 0.3-0.5: Minor changes, keeps most details
- 0.5-0.7: Moderate changes
- 0.7-0.9: Major changes, new interpretation
- 0.9-1.0: Almost like text-to-image

## 🎲 Batch Generation

Generate multiple images at once.

### Method 1: Batch Size

Generate multiple variations with same prompt:

```json
"5": {
  "inputs": {
    "width": 1024,
    "height": 1024,
    "batch_size": 4
  },
  "class_type": "EmptyLatentImage"
}
```

**Note**: Requires more VRAM! 4 images needs ~16GB VRAM.

### Method 2: Multiple Seeds

Generate with different seeds (recommended):

```json
{
  "3a": {
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
  "3b": {
    "inputs": {
      "seed": 123,
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
  }
}
```

Then add separate VAE Decode and Save Image nodes for each.

## 📐 Custom Resolutions

SDXL supports various aspect ratios.

### Common SDXL Resolutions

```json
// Square (1:1)
{"width": 1024, "height": 1024}

// Portrait (2:3)
{"width": 832, "height": 1216}

// Landscape (3:2)
{"width": 1216, "height": 832}

// Wide (16:9)
{"width": 1360, "height": 768}

// Tall (9:16)
{"width": 768, "height": 1360}

// Ultra-wide (21:9)
{"width": 1536, "height": 640}
```

### Resolution Guidelines

**Total pixels should be around 1,048,576 (1024×1024)**

Calculate: `width × height ≈ 1,048,576`

**Examples**:

- 512×2048 ✅ Valid (tall)
- 2048×512 ✅ Valid (wide)
- 1536×1536 ⚠️ Too large (needs more VRAM)
- 512×512 ⚠️ Too small (poor quality)

### Dynamic Resolution Workflow

```json
"5": {
  "inputs": {
    "width": 1216,
    "height": 832,
    "batch_size": 1
  },
  "class_type": "EmptyLatentImage"
}
```

Just change `width` and `height` values!

## 🔧 How to Use These Workflows

### Method 1: Direct API Call

1. Copy the workflow JSON
2. Modify the prompts
3. Send to API:

```powershell
$workflow = @{
  "3" = @{ ... }
  "4" = @{ ... }
  # ... rest of workflow
}

$body = @{
    input = @{
        workflow = $workflow
    }
} | ConvertTo-Json -Depth 10

Invoke-RestMethod `
    -Uri "https://api.runpod.ai/v2/$ENDPOINT_ID/runsync" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $API_KEY"
        "Content-Type" = "application/json"
    } `
    -Body $body
```

### Method 2: Save as Files

1. Save workflow to file:

   ```powershell
   $workflow | ConvertTo-Json -Depth 10 | Out-File "workflow.json"
   ```

2. Load and use:
   ```powershell
   $workflow = Get-Content "workflow.json" | ConvertFrom-Json
   # Modify as needed
   # Send to API
   ```

### Method 3: Use Example Scripts

Use the provided scripts in `examples/`:

```powershell
.\examples\test-endpoint.ps1 -WorkflowFile "workflow.json"
```

## 📝 Prompt Engineering Tips

### Quality Tags (Essential!)

Always start with:

```
score_9, score_8_up, score_7_up, score_6_up, score_5_up, score_4_up
```

Or minimal version:

```
score_9
```

(weaker effect)

### Source Tags

Choose style:

- `source_pony` - MLP style
- `source_anime` - Anime aesthetic
- `source_furry` - Furry art style
- `source_cartoon` - Western cartoon style

### Rating Tags

Set content level:

- `rating_safe` - SFW
- `rating_questionable` - Mildly suggestive
- `rating_explicit` - NSFW

### Character Tags

Format: `character_name, series_name`

Examples:

- `twilight_sparkle, my_little_pony`
- `rainbow_dash, my_little_pony`

### Descriptive Tags

```
detailed background, high quality, vibrant colors, dramatic lighting,
dynamic pose, solo, full body, portrait, close-up
```

### Complete Prompt Example

```
score_9, score_8_up, score_7_up, score_6_up, score_5_up, score_4_up,
source_pony, rating_safe,
twilight_sparkle, purple coat, purple mane with pink streak,
alicorn, wings spread, flying,
library background, books floating, magic aura,
detailed shading, vibrant colors, dynamic pose
```

### Negative Prompt Best Practices

```
score_1, score_2, score_3,
blurry, low quality, bad anatomy, bad hands, extra limbs,
watermark, signature, text, artist name,
poorly drawn, deformed, ugly
```

## 🎯 Complete Working Example

Save this as `complete-example.json`:

```json
{
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
      "text": "score_9, score_8_up, score_7_up, score_6_up, score_5_up, score_4_up, source_pony, rating_safe, rainbow_dash, blue coat, rainbow mane, flying through clouds, detailed background, vibrant colors, dynamic pose",
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "7": {
    "inputs": {
      "text": "score_1, score_2, score_3, blurry, low quality, bad anatomy, watermark, signature",
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
      "filename_prefix": "PonyV6_RainbowDash",
      "images": ["8", 0]
    },
    "class_type": "SaveImage"
  }
}
```

Test it:

```powershell
$workflow = Get-Content "complete-example.json" | ConvertFrom-Json

$body = @{
    input = @{
        workflow = $workflow
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

# Save image
$imageData = [Convert]::FromBase64String($response.output.images[0].data)
[System.IO.File]::WriteAllBytes("output.png", $imageData)
Write-Host "Image saved to output.png"
```

---

**See also**:

- [Usage Guide](./02-usage-guide.md) - General API usage
- [Troubleshooting Guide](./04-troubleshooting-guide.md) - If workflows don't work
