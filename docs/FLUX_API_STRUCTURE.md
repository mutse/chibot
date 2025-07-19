# FLUX.1 Kontext API - Response Structure Analysis

Based on the code analysis of `lib/services/flux_kontext_service.dart`, here are the exact JSON field names and API structure:

## API Endpoints

### Base URL
```
https://api.bfl.ml/v1
```

### Core Endpoints
1. **Submit Request**: `POST /flux-kontext-pro`
2. **Check Status**: `GET /get_result?id={request_id}`

## Request Format Field Names

### Text-to-Image Generation
```json
{
  "prompt": "string (required)",
  "aspect_ratio": "string (optional)",
  "seed": "integer (optional)",
  "prompt_upsampling": "boolean (optional)",
  "safety_tolerance": "integer (optional, range 0-6)",
  "output_format": "string (optional, values: png, jpeg)"
}
```

### Image-to-Image Editing
```json
{
  "prompt": "string (required)",
  "image": "string (required, URL or base64)",
  "strength": "float (optional, range 0.0-1.0)",
  "guidance_scale": "float (optional, range 0.0-10.0)",
  "aspect_ratio": "string (optional)"
}
```

### Field Details
- **prompt**: Text description of desired image
- **aspect_ratio**: "1:1", "16:9", "9:16", "21:9", "4:3", "3:4", "5:4", "4:5" (default: "1:1")
- **seed**: Integer for consistent results
- **prompt_upsampling**: Boolean (default: false)
- **safety_tolerance**: Integer 0-6 (default varies by account)
- **output_format**: "png" or "jpeg" (default: "png")
- **image**: Base64 string or URL for reference image
- **strength**: 0.0-1.0 (default: 0.8)
- **guidance_scale**: 0.0-10.0 (default: 2.5)

## Response Format Field Names

### Submit API Response
```json
{
  "id": "unique-request-id-string",
  "status": "Pending|Ready|Failed|Error",
  "polling_url": "https://api.bfl.ml/v1/get_result?id=unique-request-id"
}
```

### Result Check Response
```json
{
  "result": {
    "sample": "https://storage.googleapis.com/generated-image-url.png",
    "prompt": "original prompt text",
    "metadata": {
      "aspect_ratio": "16:9",
      "seed": 12345,
      "safety_check": "passed",
      "model_schedule": "flux-kontext-pro",
      "insights": "image analysis tags"
    }
  }
}
```

## Error Response Structure
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "descriptive error message",
    "details": "additional details"
  }
}
```

## Quick Test Commands

### Using cURL:

1. **Basic text-to-image**:
```bash
curl -X POST https://api.bfl.ml/v1/flux-kontext-pro \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "prompt": "a simple landscape with mountains and lake",
    "aspect_ratio": "16:9"
  }'
```

2. **Check results**:
```bash
curl -X GET "https://api.bfl.ml/v1/get_result?id=YOUR_REQUEST_ID" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

## Implementation Notes

- **Status**: Always "Pending" on initial response
- **Polling**: Must poll the result endpoint until status changes from "Pending" to "Ready"
- **Rate Limits**: Check API documentation for your account tier
- **Timeouts**: Implement reasonable polling intervals (2-5 seconds)

## Files Created for Testing

1. **`test_flux_kontext_api.sh`** - Comprehensive test script with dry-run and live testing modes
2. **`simple_flux_test.sh`** - Minimal test script for quick API verification
3. **`flux_api_examples.json`** - Complete JSON examples and parameter reference
4. **`basic_flux_request.json`** - Sample JSON payload for testing

## Usage Instructions

1. Set environment variable: `export FLUX_API_KEY=your-actual-key`
2. Run test: `./test_flux_kontext_api.sh`
3. For minimal test: `./simple_flux_test.sh`

The exact field names match the Dart service implementation exactly, including the snake_case naming convention used throughout the API.