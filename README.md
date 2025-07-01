# Odoo Docker Management Scripts

A production-ready Docker Compose management collection specifically designed for Odoo developers. These scripts provide streamlined deployment and management of Odoo instances with enterprise-grade reliability and developer-focused workflows.

## 🎯 Overview

This repository contains professional-grade Docker Compose management scripts tailored for Odoo development and deployment. Each script is engineered for production environments with:

- **Production-Ready Architecture**: Enterprise-level error handling, logging, and safety mechanisms
- **Developer-Centric Design**: Optimized workflows for Odoo development cycles
- **Self-Contained Execution**: Complete functionality in standalone scripts
- **Environment-Based Configuration**: Flexible configuration with production defaults
- **Cross-Platform Compatibility**: Linux, macOS, and Windows (WSL) support

## 🔧 Requirements

### Core Dependencies
- **Docker Engine** (20.10.0 or later)
- **Docker Compose** (v2.0.0 or later)
- **Bash** (4.0 or later)
- **System Utilities**: `curl`, `wget`, `grep`, `awk`

### Platform Requirements

**Linux**:
- Production-tested on major distributions
- Automatic SELinux configuration (RHEL/CentOS/Fedora)
- Sudo privileges required for system-level operations

**macOS**:
- Docker Desktop required
- Validated on macOS 11+ (Big Sur and later)

**Windows**:
- WSL2 with Docker Desktop
- Ubuntu-based WSL distribution recommended

## 📦 Odoo Docker Manager

**Script Location**: `odoo/odoo_docker_manager.sh`

Production-grade Odoo ERP management solution designed for enterprise deployments and development workflows.

### Core Features

- 🚀 **One-Command Deployment**: Complete Odoo stack initialization
- 🔧 **Package Management**: Automated APT and Python pip package installation
- 📦 **Module Management**: Enterprise module installation and configuration
- 🛡️ **Security Hardening**: Automatic SELinux configuration and security policies
- 🔄 **Backup/Restore Operations**: Production-grade data protection
- 📊 **Monitoring & Logging**: Real-time performance monitoring and log aggregation
- 🎨 **Interactive Interface**: Professional terminal-based management UI

### Quick Start

```bash
# Repository setup
git clone https://github.com/JBibu/docker_compose_scripts.git
cd docker_compose_scripts/odoo
chmod +x odoo_docker_manager.sh

# Interactive management interface
./odoo_docker_manager.sh

# Direct command execution
./odoo_docker_manager.sh start
./odoo_docker_manager.sh help
```

### Production Deployment

For production environments, review the comprehensive documentation:

[📖 Complete Odoo Documentation →](odoo/README.md)

## 📄 License

Licensed under GPL-3.0 License. See [LICENSE](LICENSE) for complete terms and conditions.
