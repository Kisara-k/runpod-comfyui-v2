# RunPod Serverless ComfyUI with Pony Diffusion V6 XL

This repository contains everything you need to set up a serverless RunPod endpoint for generating images using Pony Diffusion V6 XL through ComfyUI, using the official [worker-comfyui](https://github.com/runpod-workers/worker-comfyui) worker.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Project Structure](#project-structure)
- [License](#license)

## 🎯 Overview

This setup allows you to:

- Run Pony Diffusion V6 XL on RunPod serverless infrastructure
- Use ComfyUI workflows via API calls
- Scale automatically based on demand
- Pay only for compute time used
- Get generated images as base64 or upload to S3

## ✅ Prerequisites

Before you begin, you'll need:

- A RunPod account ([sign up here](https://runpod.io))
- RunPod credits (~$5 to get started)
- Pony Diffusion V6 XL model file (~6.5GB) - download from [CivitAI](https://civitai.com/models/257749/pony-diffusion-v6-xl)
- Basic understanding of RunPod interface
- RunPod API key for testing

## 🚀 Quick Start

1. **Create a Network Volume and upload Pony Diffusion V6 XL model:**

   - Follow the [Deployment Guide](./docs/01-deployment-guide.md) Section 1

2. **Create RunPod Template:**

   - Use pre-built image: `runpod/worker-comfyui:5.4.1-sdxl`
   - Attach your Network Volume

3. **Deploy Endpoint:**

   - Follow the [Deployment Guide](./docs/01-deployment-guide.md) Section 2

4. **Test your endpoint:**
   - Use the examples in [Usage Guide](./docs/02-usage-guide.md)

## 📚 Documentation

Detailed guides are available in the `docs/` folder:

1. **[Deployment Guide](./docs/01-deployment-guide.md)** - Step-by-step instructions to deploy your endpoint
2. **[Usage Guide](./docs/02-usage-guide.md)** - How to use your endpoint and create workflows
3. **[Configuration Guide](./docs/03-configuration-guide.md)** - Environment variables and S3 setup
4. **[Troubleshooting Guide](./docs/04-troubleshooting-guide.md)** - Common issues and solutions
5. **[Workflow Examples](./docs/05-workflow-examples.md)** - Sample ComfyUI workflows for Pony Diffusion V6 XL

## 📁 Project Structure

```
runpod-comfyui-v2/
├── README.md                           # This file
├── QUICKSTART.md                       # 30-minute quick start guide
├── NETWORK-VOLUME-SETUP.md             # How to set up Network Volume with models
├── docs/
│   ├── 01-deployment-guide.md         # Deployment with pre-built worker
│   ├── 02-usage-guide.md              # API usage guide
│   ├── 03-configuration-guide.md      # Environment variables & S3
│   ├── 04-troubleshooting-guide.md    # Common issues & solutions
│   └── 05-workflow-examples.md        # Ready-to-use workflows
└── examples/
    ├── basic-workflow.json            # Simple text-to-image workflow
    ├── advanced-workflow.json         # Advanced workflow with LoRAs
    └── test-endpoint.ps1              # PowerShell test script
```

## 📝 Important Notes

### Pony Diffusion V6 XL Requirements

- **CLIP Skip**: Must be set to 2 (or -2)
- **Recommended Settings**:
  - Sampler: Euler a
  - Steps: 25
  - Resolution: 1024px (or any SDXL resolution)

### Quality Tags Template

For best results, use this prompt template:

```
score_9, score_8_up, score_7_up, score_6_up, score_5_up, score_4_up, [your description here]
```

### Source and Rating Tags

- **Source**: `source_pony`, `source_furry`, `source_cartoon`, `source_anime`
- **Rating**: `rating_safe`, `rating_questionable`, `rating_explicit`

### License Considerations

Pony Diffusion V6 XL is under a modified Fair AI Public License 1.0-SD. **Commercial inference on paid platforms is restricted** unless you have explicit permission. This restriction applies to RunPod serverless endpoints if you charge users for inference.

For commercial use, contact: contact@purplesmart.ai

## 🔗 Useful Links

- [RunPod Documentation](https://docs.runpod.io/)
- [worker-comfyui Repository](https://github.com/runpod-workers/worker-comfyui)
- [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- [Pony Diffusion V6 XL on CivitAI](https://civitai.com/models/257749/pony-diffusion-v6-xl)
- [Pony Smart AI Discord](https://discord.gg/pYsdjMfu3q)

## 📄 License

This project setup is provided as-is. Please respect the licenses of:

- Pony Diffusion V6 XL model (Fair AI Public License 1.0-SD with modifications)
- worker-comfyui (AGPL-3.0)
- ComfyUI (GPL-3.0)

---

**Created for educational purposes. Always verify license compliance for your use case.**
