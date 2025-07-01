![image](https://github.com/user-attachments/assets/3b812131-5959-46bd-b866-993cd28c97c2)

Docker Compose management scripts for developers. These scripts help you deploy and manage docker compose instances with reliable configurations and developer-friendly workflows.

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

## Odoo Docker Manager

**File**: `odoo/odoo_docker_manager.sh`

Main script for managing Odoo ERP deployments.

**What it does:**
- Deploy complete Odoo stack with one command
- Install APT and Python packages automatically
- Manage Odoo modules
- Configure security settings (including SELinux)
- Handle backup and restore operations
- Monitor performance and aggregate logs
- Provide terminal-based management interface

## Getting Started

```bash
# Get the scripts
git clone https://github.com/JBibu/docker_compose_scripts.git
cd docker_compose_scripts/odoo
chmod +x odoo_docker_manager.sh

# Run interactive interface
./odoo_docker_manager.sh

# Or run specific commands
./odoo_docker_manager.sh start
./odoo_docker_manager.sh help
```

## Documentation

For detailed setup and production deployment instructions, see the [complete Odoo documentation](odoo/README.md).

## License

GPL-3.0 License - see [LICENSE](LICENSE) file.
