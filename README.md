# GAMIT/GLOBK Docker

🛰️ **Docker image for GAMIT/GLOBK 10.71** - GPS/GNSS data processing software from MIT.

> ⚠️ **License Required**: GAMIT/GLOBK requires a license from MIT. Apply at [http://geoweb.mit.edu/gg/license.php](http://geoweb.mit.edu/gg/license.php)

## Quick Start

```bash
# Build with your MIT credentials
docker build \
  --build-arg GG_USER=guest \
  --build-arg GG_PASSWORD=your_password \
  -t gamit:10.71 .

# Run interactively
docker run -it -v $(pwd)/data:/data gamit:10.71

# Run globk
docker run gamit:10.71 globs
```

## What's Included

| Program | Description |
|---------|-------------|
| `globs` | GLOBK - Global Kalman Filter (Ver 5.35) |
| `glred` | Network constraint processing |
| `glfor` | Forward Kalman filter |
| `glinit` | Initialization |
| `autcln` | Automatic data cleaning |
| `track` | Kinematic positioning |

## Build Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `GG_USER` | Yes | MIT FTP username (default: `guest`) |
| `GG_PASSWORD` | **Yes** | MIT FTP password |

## Volume Mounts

```bash
docker run -v /your/rinex:/data gamit:10.71
```

## Environment

- **Base**: Ubuntu 24.04 LTS
- **Compiler**: gfortran 13 (with legacy compatibility flags)
- **GAMIT Version**: 10.71 + latest incremental updates

## License

This Docker configuration is MIT licensed. **GAMIT/GLOBK software itself requires a separate license from MIT.**

---
Created with ❤️ for the geodesy community
