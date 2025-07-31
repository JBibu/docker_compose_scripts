![image](https://github.com/user-attachments/assets/3b812131-5959-46bd-b866-993cd28c97c2)

Docker Compose management scripts for developers. These scripts help you deploy and manage docker compose instances with reliable configurations and developer-friendly workflows.

⚠️ Known Regression in Docker Buildx
This project may be affected by a regression in recent buildx versions (docker/buildx#3328).

## What This Is

A collection of Docker Compose management scripts for development.

**Key Features:**
- Reliable deployment configurations
- Developer workflow optimization  
- Standalone script functionality
- Environment-based configuration
- Cross-platform support (Linux, macOS, Windows with WSL)

## Requirements

**You'll need:**
- Docker Engine 20.10.0+
- Docker Compose v2.0.0+
- Bash 4.0+
- Standard utilities: `curl`, `wget`, `grep`, `awk`

**Platform specifics:**
- **Linux**: Tested on major distributions, handles SELinux automatically, needs sudo
- **macOS**: Requires Docker Desktop, works on macOS 11+
- **Windows**: Use WSL2 with Docker Desktop, Ubuntu WSL recommended

## Getting Started

### Available scripts:

- [Odoo](odoo)

## License

GPL-3.0 License - see [LICENSE](LICENSE) file.
