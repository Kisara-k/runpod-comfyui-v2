# Test RunPod Serverless ComfyUI Endpoint
# PowerShell script to test your Pony Diffusion V6 XL endpoint

param(
    [Parameter(Mandatory=$false)]
    [string]$ApiKey = $env:RUNPOD_API_KEY,
    
    [Parameter(Mandatory=$false)]
    [string]$EndpointId = $env:RUNPOD_ENDPOINT_ID,
    
    [Parameter(Mandatory=$false)]
    [string]$WorkflowFile = "basic-workflow.json",
    
    [Parameter(Mandatory=$false)]
    [switch]$Async = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "output"
)

# Check for required parameters
if (-not $ApiKey) {
    Write-Host "❌ Error: API Key not provided." -ForegroundColor Red
    Write-Host "Set environment variable RUNPOD_API_KEY or use -ApiKey parameter" -ForegroundColor Yellow
    exit 1
}

if (-not $EndpointId) {
    Write-Host "❌ Error: Endpoint ID not provided." -ForegroundColor Red
    Write-Host "Set environment variable RUNPOD_ENDPOINT_ID or use -EndpointId parameter" -ForegroundColor Yellow
    exit 1
}

# Check if workflow file exists
if (-not (Test-Path $WorkflowFile)) {
    Write-Host "❌ Error: Workflow file not found: $WorkflowFile" -ForegroundColor Red
    exit 1
}

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

Write-Host "🚀 RunPod Serverless ComfyUI - Pony Diffusion V6 XL" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Load workflow
Write-Host "📄 Loading workflow from: $WorkflowFile" -ForegroundColor Yellow
try {
    $workflow = Get-Content $WorkflowFile -Raw | ConvertFrom-Json
} catch {
    Write-Host "❌ Error parsing workflow JSON: $_" -ForegroundColor Red
    exit 1
}

# Create request body
$body = @{
    input = @{
        workflow = $workflow
    }
} | ConvertTo-Json -Depth 10

# Determine endpoint URL
$endpoint = if ($Async) { "run" } else { "runsync" }
$url = "https://api.runpod.ai/v2/$EndpointId/$endpoint"

Write-Host "🌐 Endpoint: $url" -ForegroundColor Yellow
Write-Host "⏱️  Mode: $(if ($Async) { 'Async' } else { 'Sync' })" -ForegroundColor Yellow
Write-Host ""

# Send request
Write-Host "📤 Sending request..." -ForegroundColor Green
$startTime = Get-Date

try {
    $response = Invoke-RestMethod `
        -Uri $url `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $ApiKey"
            "Content-Type" = "application/json"
        } `
        -Body $body
} catch {
    Write-Host "❌ Request failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Yellow
    Write-Host $_.ErrorDetails.Message
    exit 1
}

# Handle async response
if ($Async) {
    $jobId = $response.id
    Write-Host "✅ Job submitted: $jobId" -ForegroundColor Green
    Write-Host "📊 Status: $($response.status)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔄 Polling for completion..." -ForegroundColor Yellow
    
    $statusUrl = "https://api.runpod.ai/v2/$EndpointId/status/$jobId"
    
    do {
        Start-Sleep -Seconds 2
        try {
            $response = Invoke-RestMethod `
                -Uri $statusUrl `
                -Headers @{ "Authorization" = "Bearer $ApiKey" }
            
            Write-Host "   Status: $($response.status)" -ForegroundColor Cyan
        } catch {
            Write-Host "❌ Error checking status: $_" -ForegroundColor Red
            exit 1
        }
    } while ($response.status -in @("IN_QUEUE", "IN_PROGRESS"))
}

$endTime = Get-Date
$totalTime = ($endTime - $startTime).TotalSeconds

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "📊 Results" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Status: $($response.status)" -ForegroundColor $(if ($response.status -eq "COMPLETED") { "Green" } else { "Red" })

if ($response.status -eq "COMPLETED") {
    Write-Host "⏱️  Delay Time: $($response.delayTime)ms" -ForegroundColor Yellow
    Write-Host "⚡ Execution Time: $($response.executionTime)ms" -ForegroundColor Yellow
    Write-Host "🕐 Total Time: $([math]::Round($totalTime, 2))s" -ForegroundColor Yellow
    Write-Host ""
    
    # Process images
    if ($response.output.images) {
        Write-Host "🖼️  Generated $($response.output.images.Count) image(s):" -ForegroundColor Green
        Write-Host ""
        
        $imageCount = 0
        foreach ($img in $response.output.images) {
            $imageCount++
            
            if ($img.type -eq "base64") {
                # Save base64 image
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $filename = "output_${timestamp}_${imageCount}.png"
                $filepath = Join-Path $OutputDir $filename
                
                try {
                    $imageBytes = [Convert]::FromBase64String($img.data)
                    [System.IO.File]::WriteAllBytes($filepath, $imageBytes)
                    Write-Host "   ✅ Saved: $filepath" -ForegroundColor Green
                } catch {
                    Write-Host "   ❌ Failed to save image: $_" -ForegroundColor Red
                }
            } elseif ($img.type -eq "s3_url") {
                # S3 URL
                Write-Host "   🔗 S3 URL: $($img.data)" -ForegroundColor Cyan
            }
        }
        
        Write-Host ""
        Write-Host "✨ Success! Images saved to: $OutputDir" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No images in response" -ForegroundColor Yellow
    }
    
    # Show errors if any
    if ($response.output.errors) {
        Write-Host ""
        Write-Host "⚠️  Warnings/Errors:" -ForegroundColor Yellow
        foreach ($error in $response.output.errors) {
            Write-Host "   - $error" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "❌ Job failed!" -ForegroundColor Red
    if ($response.error) {
        Write-Host "Error: $($response.error)" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Full response:" -ForegroundColor Yellow
    $response | ConvertTo-Json -Depth 10 | Write-Host
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
