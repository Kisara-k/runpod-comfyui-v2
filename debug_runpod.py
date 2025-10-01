#!/usr/bin/env python3
"""
Debug script to test RunPod API calls and find the correct endpoint configuration.
"""

import os
import json
import time
import requests
from pprint import pprint
import dotenv
dotenv.load_dotenv()

# Credentials
API_KEY = os.getenv("RUNPOD_API_KEY")
ENDPOINT_ID = os.getenv("RUNPOD_ENDPOINT_ID")

# Test workflow (minimal for debugging)
workflow = {
    "3": {
        "inputs": {
            "seed": 42,
            "steps": 20,
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
            "width": 512,
            "height": 512,
            "batch_size": 1
        },
        "class_type": "EmptyLatentImage"
    },
    "6": {
        "inputs": {
            "text": "score_9, score_8_up, a simple test image",
            "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode"
    },
    "7": {
        "inputs": {
            "text": "score_1, score_2, score_3",
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
            "filename_prefix": "test",
            "images": ["8", 0]
        },
        "class_type": "SaveImage"
    }
}

def test_endpoint(url_template, payload_template, description):
    """Test a specific endpoint configuration."""
    
    print(f"\n{'='*60}")
    print(f"Testing: {description}")
    print(f"URL: {url_template.format(endpoint_id=ENDPOINT_ID)}")
    print('='*60)
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}"
    }
    
    url = url_template.format(endpoint_id=ENDPOINT_ID)
    payload = payload_template
    
    try:
        print("🚀 Sending request...")
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ SUCCESS!")
            pprint(result)
            return result
        else:
            print("❌ FAILED!")
            print(f"Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ EXCEPTION: {e}")
        return None

def main():
    """Test different endpoint configurations."""
    
    print("RunPod API Debug Tool")
    print(f"Endpoint ID: {ENDPOINT_ID}")
    print(f"API Key: {API_KEY[:8]}...{API_KEY[-4:]}")
    
    # Test configurations
    configs = [
        # Load Balancer Sync
        {
            "url": "https://api.runpod.ai/v2/{endpoint_id}/runsync",
            "payload": {"input": {"workflow": workflow}},
            "description": "Load Balancer Sync (/runsync)"
        },
        
        # Direct Serverless Async
        {
            "url": "https://api.runpod.ai/v2/{endpoint_id}/run",
            "payload": {"input": {"workflow": workflow}},
            "description": "Direct Serverless Async (/run)"
        },
        
        # Queue API
        {
            "url": "https://api.runpod.ai/v2/queue/{endpoint_id}/run",
            "payload": {"input": {"workflow": workflow}},
            "description": "Queue API (/queue/.../run)"
        },
        
        # Alternative payload format 1
        {
            "url": "https://api.runpod.ai/v2/{endpoint_id}/runsync",
            "payload": {"workflow": workflow},
            "description": "Load Balancer Sync - Direct workflow"
        },
        
        # Alternative payload format 2
        {
            "url": "https://api.runpod.ai/v2/{endpoint_id}/run",
            "payload": {"workflow": workflow},
            "description": "Direct Serverless - Direct workflow"
        },
        
        # ComfyUI worker format
        {
            "url": "https://api.runpod.ai/v2/{endpoint_id}/runsync",
            "payload": {"input": {"workflow": workflow, "images": []}},
            "description": "ComfyUI Worker Format"
        }
    ]
    
    successful_config = None
    
    for config in configs:
        result = test_endpoint(config["url"], config["payload"], config["description"])
        if result:
            successful_config = config
            
            # If async endpoint, try to poll for results
            if "run" in config["url"] and not "runsync" in config["url"]:
                print("\n🔄 Async endpoint detected, attempting to poll...")
                job_id = result.get("id") or result.get("jobId")
                if job_id:
                    poll_url = config["url"].replace("/run", f"/status/{job_id}").format(endpoint_id=ENDPOINT_ID)
                    print(f"Polling URL: {poll_url}")
                    
                    headers = {"Authorization": f"Bearer {API_KEY}"}
                    for i in range(30):  # Poll for up to 60 seconds
                        time.sleep(2)
                        try:
                            status_resp = requests.get(poll_url, headers=headers, timeout=10)
                            if status_resp.status_code == 200:
                                status_result = status_resp.json()
                                status = status_result.get("status")
                                print(f"Poll {i+1}: Status = {status}")
                                
                                if status == "COMPLETED":
                                    print("✅ Job completed!")
                                    pprint(status_result)
                                    break
                                elif status == "FAILED":
                                    print("❌ Job failed!")
                                    print(f"Error: {status_result.get('error')}")
                                    break
                            else:
                                print(f"Poll failed: {status_resp.status_code} - {status_resp.text}")
                                break
                        except Exception as e:
                            print(f"Poll error: {e}")
                            break
            
            break
    
    if successful_config:
        print(f"\n🎉 WORKING CONFIGURATION FOUND!")
        print(f"URL Pattern: {successful_config['url']}")
        print(f"Payload Format: {json.dumps(successful_config['payload'], indent=2)}")
        
        # Generate notebook update
        if "queue" in successful_config["url"]:
            mode = "queue"
        elif "runsync" in successful_config["url"]:
            mode = "load_balancer"
        else:
            mode = "serverless"
            
        print(f"\n📝 UPDATE YOUR .ENV FILE:")
        print(f"RUNPOD_API_MODE={mode}")
        
    else:
        print("\n❌ NO WORKING CONFIGURATION FOUND")
        print("Check your endpoint ID and API key")

if __name__ == "__main__":
    main()