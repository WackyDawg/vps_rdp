# VPS RDP Server

A containerized Ubuntu desktop environment with remote access capabilities using RustDesk and a Node.js status server.

## Features

- Ubuntu 22.04 with XFCE desktop environment
- RustDesk remote desktop access
- Chrome browser pre-installed
- Node.js server providing system information
- Virtual display using Xvfb

## Quick Start

### Using Docker

```bash
docker build -t vps-rdp .
docker run -p 7860:7860 vps-rdp
```

### Local Development

```bash
npm install
node server.js
```

## Remote Access

After starting the container, RustDesk will be configured with:
- **Password**: `WackydawgTheBotFather`
- **ID**: Displayed in container logs

Connect using the RustDesk client with these credentials.

## API Endpoint

The server exposes system information at `http://localhost:7860/`:

```json
{
  "server_time": "2024-01-01T00:00:00.000Z",
  "local_time": "1/1/2024, 12:00:00 AM",
  "timestamp": 1704067200000,
  "timezone": "UTC",
  "uptime_seconds": 120,
  "uptime_human_readable": "2 minutes",
  "server_ip": "192.168.1.100",
  "hostname": "container-id",
  "platform": "linux",
  "cpu_model": "Intel(R) Core(TM) i7",
  "cpu_cores": 4,
  "ram_total_mb": 8192,
  "ram_free_mb": 4096
}
```

## Configuration

- **Port**: 7860 (Node.js server)
- **Desktop User**: `desktopuser` / `password123`
- **Display**: `:99` (1280x720)

## Requirements

- Docker
- Node.js 18+ (for local development)