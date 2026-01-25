---
title: "CloudStore API Reference"
subtitle: "Version 2.0"
author: "CloudStore Engineering Team"
date: "January 2026"
format: "article"
toc: true
toc_depth: 3
section_numbers: true
---

# Introduction

CloudStore is a distributed object storage service designed for high availability and scalability. This document provides a complete reference for the CloudStore REST API.

## Base URL

All API requests should be made to:

```
https://api.cloudstore.io/v2
```

## Authentication

CloudStore uses API keys for authentication. Include your key in the request header:

```http
Authorization: Bearer YOUR_API_KEY
```

### Obtaining an API Key

1. Log in to the CloudStore Console
2. Navigate to Settings → API Keys
3. Click "Generate New Key"
4. Copy and securely store your key

> **Warning**: API keys provide full access to your account. Never commit keys to version control or share them publicly.

## Rate Limits

| Plan | Requests/minute | Requests/day |
|------|-----------------|--------------|
| Free | 60 | 10,000 |
| Pro | 600 | 100,000 |
| Enterprise | Unlimited | Unlimited |

Rate limit headers are included in all responses:

```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1640000000
```

---

# Objects

Objects are the primary resource in CloudStore. Each object consists of data and metadata.

## Object Model

```json
{
  "id": "obj_abc123",
  "bucket": "my-bucket",
  "key": "path/to/file.txt",
  "size": 1024,
  "content_type": "text/plain",
  "etag": "d41d8cd98f00b204e9800998ecf8427e",
  "created_at": "2026-01-15T10:30:00Z",
  "updated_at": "2026-01-15T10:30:00Z",
  "metadata": {
    "custom-key": "custom-value"
  }
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique object identifier |
| `bucket` | string | Parent bucket name |
| `key` | string | Object key (path) |
| `size` | integer | Size in bytes |
| `content_type` | string | MIME type |
| `etag` | string | MD5 hash of content |
| `created_at` | datetime | Creation timestamp (ISO 8601) |
| `updated_at` | datetime | Last modification timestamp |
| `metadata` | object | Custom key-value pairs |

## Upload Object

Upload a new object to a bucket.

### Request

```http
PUT /buckets/{bucket}/objects/{key}
Content-Type: application/octet-stream
Content-Length: 1024
X-CloudStore-Meta-Custom: value

<binary data>
```

### Parameters

| Parameter | Location | Required | Description |
|-----------|----------|----------|-------------|
| `bucket` | path | Yes | Target bucket name |
| `key` | path | Yes | Object key |
| `Content-Type` | header | No | MIME type (default: `application/octet-stream`) |
| `X-CloudStore-Meta-*` | header | No | Custom metadata |

### Response

```http
HTTP/1.1 201 Created
Content-Type: application/json

{
  "id": "obj_abc123",
  "bucket": "my-bucket",
  "key": "path/to/file.txt",
  "size": 1024,
  "etag": "d41d8cd98f00b204e9800998ecf8427e"
}
```

### Example

```python
import requests

url = "https://api.cloudstore.io/v2/buckets/my-bucket/objects/hello.txt"
headers = {
    "Authorization": "Bearer YOUR_API_KEY",
    "Content-Type": "text/plain"
}
data = "Hello, World!"

response = requests.put(url, headers=headers, data=data)
print(response.json())
```

## Download Object

Retrieve an object's content.

### Request

```http
GET /buckets/{bucket}/objects/{key}
```

### Response

```http
HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: 13
ETag: "65a8e27d8879283831b664bd8b7f0ad4"

Hello, World!
```

### Conditional Requests

Use conditional headers for cache optimization:

```http
GET /buckets/my-bucket/objects/file.txt
If-None-Match: "65a8e27d8879283831b664bd8b7f0ad4"
```

If the object hasn't changed:

```http
HTTP/1.1 304 Not Modified
```

## Delete Object

Remove an object from a bucket.

### Request

```http
DELETE /buckets/{bucket}/objects/{key}
```

### Response

```http
HTTP/1.1 204 No Content
```

## List Objects

List objects in a bucket with optional filtering.

### Request

```http
GET /buckets/{bucket}/objects?prefix=images/&limit=100&cursor=abc123
```

### Query Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `prefix` | string | - | Filter by key prefix |
| `limit` | integer | 1000 | Maximum results (1-1000) |
| `cursor` | string | - | Pagination cursor |

### Response

```json
{
  "objects": [
    {
      "key": "images/photo1.jpg",
      "size": 102400,
      "updated_at": "2026-01-15T10:30:00Z"
    },
    {
      "key": "images/photo2.jpg",
      "size": 204800,
      "updated_at": "2026-01-14T09:15:00Z"
    }
  ],
  "cursor": "def456",
  "has_more": true
}
```

---

# Buckets

Buckets are containers for objects. Each bucket has a globally unique name.

## Create Bucket

```http
POST /buckets
Content-Type: application/json

{
  "name": "my-bucket",
  "region": "us-east-1",
  "versioning": true
}
```

### Response

```http
HTTP/1.1 201 Created
Location: /buckets/my-bucket

{
  "name": "my-bucket",
  "region": "us-east-1",
  "versioning": true,
  "created_at": "2026-01-15T10:30:00Z"
}
```

## Delete Bucket

> **Note**: Bucket must be empty before deletion.

```http
DELETE /buckets/{bucket}
```

---

# Error Handling

## Error Response Format

All errors follow a consistent format:

```json
{
  "error": {
    "code": "OBJECT_NOT_FOUND",
    "message": "The specified object does not exist",
    "details": {
      "bucket": "my-bucket",
      "key": "nonexistent.txt"
    }
  }
}
```

## Error Codes

| HTTP Status | Code | Description |
|-------------|------|-------------|
| 400 | `INVALID_REQUEST` | Malformed request |
| 401 | `UNAUTHORIZED` | Missing or invalid API key |
| 403 | `FORBIDDEN` | Insufficient permissions |
| 404 | `NOT_FOUND` | Resource not found |
| 409 | `CONFLICT` | Resource already exists |
| 429 | `RATE_LIMITED` | Too many requests |
| 500 | `INTERNAL_ERROR` | Server error |

## Retry Strategy

For transient errors (5xx), implement exponential backoff:

```python
import time
import random

def retry_with_backoff(func, max_retries=5):
    for attempt in range(max_retries):
        try:
            return func()
        except ServerError:
            if attempt == max_retries - 1:
                raise
            delay = (2 ** attempt) + random.uniform(0, 1)
            time.sleep(delay)
```

---

# SDKs

Official SDKs are available for popular languages:

## Python

```bash
pip install cloudstore
```

```python
from cloudstore import Client

client = Client(api_key="YOUR_API_KEY")

# Upload
client.upload("my-bucket", "hello.txt", b"Hello, World!")

# Download
data = client.download("my-bucket", "hello.txt")

# List
for obj in client.list("my-bucket", prefix="images/"):
    print(obj.key)
```

## JavaScript/Node.js

```bash
npm install @cloudstore/sdk
```

```javascript
const CloudStore = require('@cloudstore/sdk');

const client = new CloudStore({ apiKey: 'YOUR_API_KEY' });

// Upload
await client.upload('my-bucket', 'hello.txt', 'Hello, World!');

// Download
const data = await client.download('my-bucket', 'hello.txt');

// List
const objects = await client.list('my-bucket', { prefix: 'images/' });
```

## Go

```bash
go get github.com/cloudstore/cloudstore-go
```

```go
package main

import (
    "github.com/cloudstore/cloudstore-go"
)

func main() {
    client := cloudstore.NewClient("YOUR_API_KEY")
    
    // Upload
    client.Upload("my-bucket", "hello.txt", []byte("Hello, World!"))
    
    // Download
    data, _ := client.Download("my-bucket", "hello.txt")
    
    // List
    objects, _ := client.List("my-bucket", cloudstore.ListOptions{
        Prefix: "images/",
    })
}
```

---

# Appendix

## A. Supported Regions

| Region Code | Location |
|-------------|----------|
| `us-east-1` | Virginia, USA |
| `us-west-2` | Oregon, USA |
| `eu-west-1` | Ireland |
| `eu-central-1` | Frankfurt, Germany |
| `ap-southeast-1` | Singapore |
| `ap-northeast-1` | Tokyo, Japan |

## B. Content-Type Detection

If `Content-Type` is not specified, CloudStore infers it from the file extension:

| Extension | Content-Type |
|-----------|--------------|
| `.txt` | `text/plain` |
| `.html` | `text/html` |
| `.json` | `application/json` |
| `.jpg`, `.jpeg` | `image/jpeg` |
| `.png` | `image/png` |
| `.pdf` | `application/pdf` |

## C. Changelog

### Version 2.0 (January 2026)

- Added bucket versioning
- Improved rate limiting
- New regions: `ap-southeast-1`, `ap-northeast-1`

### Version 1.0 (June 2025)

- Initial release
