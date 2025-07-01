![image](https://github.com/user-attachments/assets/c6daeed9-20dd-4561-8464-60ab88662668)

A collection of production-ready Docker Compose management scripts for popular applications and services. Each script provides an intuitive interface for managing containerized applications with minimal configuration.

## 🎯 Overview

This repository contains standalone management scripts that simplify Docker Compose operations for various applications. Each script is designed to be:

- **Self-contained**: Everything needed in a single executable script
- **Production-ready**: Includes proper error handling, logging, and safety checks
- **User-friendly**: Interactive menus and clear command-line interfaces
- **Configurable**: Environment-based configuration with sensible defaults
- **Cross-platform**: Works on Linux, macOS, and Windows (with WSL)

## 🔧 General Requirements

All scripts in this repository require:

- **Docker Engine** (20.10.0 or later)
- **Docker Compose** (v2.0.0 or later)
- **Bash** (4.0 or later)
- **Basic system utilities**: `curl`, `wget`, `grep`, `awk`

### Platform-Specific Notes

**Linux**:
- Most distributions supported out of the box
- SELinux configurations handled automatically (Fedora/RHEL/CentOS)
- sudo access may be required for some operations

**macOS**:
- Requires Docker Desktop
- All scripts tested on macOS 11+ (Big Sur and later)

**Windows**:
- Requires WSL2 with Docker Desktop
- Ubuntu or similar Linux distribution in WSL recommended

## 📦 Available Scripts

### Odoo Docker Manager
**Location**: `odoo/odoo_docker_manager.sh`

A comprehensive management script for Odoo ERP.

**Features**:
- 🚀 One-command Odoo deployment
- 🔧 Custom package installation (APT + Python pip)
- 📦 Extra modules management
- 🛡️ SELinux automatic configuration
- 🔄 Built-in backup and restore capabilities
- 📊 Real-time monitoring and logs
- 🎨 Interactive terminal UI

**Quick Setup**:
```bash
# Clone and setup
git clone https://github.com/JBibu/docker_compose_scripts.git
cd docker_compose_scripts/odoo
chmod +x odoo_docker_manager.sh

# Start interactive mode
./odoo_docker_manager.sh

# Or use direct commands
./odoo_docker_manager.sh start
./odoo_docker_manager.sh help
```

[📖 View full Odoo documentation →](odoo/README.md)

---

*More scripts coming soon! See [Contributing](#contributing) to add your own.*

## 📄 License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.
