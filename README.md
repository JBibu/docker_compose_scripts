# Docker Compose Scripts

A collection of production-ready Docker Compose management scripts for popular applications and services. Each script provides an intuitive interface for managing containerized applications with minimal configuration.

## 📋 Table of Contents

- [Overview](#overview)
- [Available Scripts](#available-scripts)
- [Quick Start](#quick-start)
- [General Requirements](#general-requirements)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

This repository contains standalone management scripts that simplify Docker Compose operations for various applications. Each script is designed to be:

- **Self-contained**: Everything needed in a single executable script
- **Production-ready**: Includes proper error handling, logging, and safety checks
- **User-friendly**: Interactive menus and clear command-line interfaces
- **Configurable**: Environment-based configuration with sensible defaults
- **Cross-platform**: Works on Linux, macOS, and Windows (with WSL)

## 📦 Available Scripts

### Odoo Docker Manager
**Location**: `odoo/odoo_docker_manager`

A comprehensive management script for Odoo ERP with PostgreSQL backend.

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
git clone <repository-url>
cd docker_compose_scripts/odoo
chmod +x odoo_docker_manager

# Start interactive mode
./odoo_docker_manager

# Or use direct commands
./odoo_docker_manager start
./odoo_docker_manager help
```

[📖 View full Odoo documentation →](odoo/README.md)

---

*More scripts coming soon! See [Contributing](#contributing) to add your own.*

## 🚀 Quick Start

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd docker_compose_scripts
   ```

2. **Navigate to desired application**:
   ```bash
   cd odoo  # or any other available script directory
   ```

3. **Make script executable**:
   ```bash
   chmod +x *_manager
   ```

4. **Run the script**:
   ```bash
   ./odoo_docker_manager  # Interactive mode
   # or
   ./odoo_docker_manager help  # See available commands
   ```

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

## 📁 Repository Structure

```
docker_compose_scripts/
├── README.md                 # This file
├── CONTRIBUTING.md          # Contribution guidelines
├── LICENSE                  # Project license
│
├── odoo/                    # Odoo ERP management
│   ├── README.md           # Odoo-specific documentation
│   ├── odoo_docker_manager # Main management script
│   └── examples/           # Example configurations
│
├── nextcloud/              # (Coming soon)
│   ├── README.md
│   └── nextcloud_manager
│
├── wordpress/              # (Coming soon)
│   ├── README.md
│   └── wordpress_manager
│
└── templates/              # Script templates for contributors
    ├── script_template.sh
    └── README_template.md
```

## 🛠️ Common Script Features

All management scripts in this repository follow these conventions:

### Command Structure
```bash
./app_manager [command]

# Available commands (common across all scripts):
start           # Start all services
stop            # Stop all services  
restart         # Restart all services
rebuild         # Rebuild images and restart
logs            # Show real-time logs
clean           # Remove all data (with confirmation)
help            # Show detailed help
                # (no command starts interactive menu)
```

### Configuration
Each script uses a `.env` file for configuration:
```bash
# Example .env structure
APP_VERSION=latest
APP_PORT=8080
DB_PASSWORD=secure_password
CUSTOM_PACKAGES=package1 package2
```

### Interactive Menus
All scripts provide user-friendly interactive menus when run without arguments:
```
🐋 APPLICATION DOCKER MANAGER

📊 System Status:
  Application: 🟢 Running
  Database: 🟢 Running

Available options:
1) 🛑 Stop services
2) 🔄 Restart services
3) 🔨 Rebuild image
4) 📋 View real-time logs
5) 🔧 Fix permissions
6) 📖 Show help
7) 🚪 Exit

Select an option:
```

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Adding New Scripts

1. **Create a new directory** for your application
2. **Use the template** from `templates/script_template.sh`
3. **Follow naming convention**: `{app}_docker_manager`
4. **Include documentation**: Add a comprehensive README.md
5. **Test thoroughly**: Ensure it works across different environments

### Improvement Guidelines

- 🔒 **Security first**: Never hardcode credentials
- 📝 **Document everything**: Clear comments and user documentation
- 🧪 **Test extensively**: Multiple OS, Docker versions, edge cases
- 🎨 **Consistent UI**: Follow the established interactive menu style
- ⚡ **Performance matters**: Efficient startup and resource usage

### Submit Your Contribution

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-app-manager`
3. Add your script and documentation
4. Test on at least 2 different platforms
5. Submit a pull request with detailed description

[📖 Read full contributing guidelines →](CONTRIBUTING.md)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/your-repo/docker_compose_scripts/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/your-repo/docker_compose_scripts/discussions)
- 📧 **Email**: support@your-domain.com

## 🗺️ Roadmap

### Coming Soon
- [ ] **NextCloud Manager** - Personal cloud storage
- [ ] **WordPress Manager** - Website and blog platform
- [ ] **GitLab Manager** - Git repository and CI/CD
- [ ] **Jitsi Manager** - Video conferencing
- [ ] **Minecraft Manager** - Game server management

### Planned Features
- [ ] Multi-environment support (dev/staging/prod)
- [ ] Automated backup scheduling
- [ ] Health monitoring and alerts
- [ ] Configuration templates gallery
- [ ] Web-based management interface

---

<div align="center">

**⭐ Star this repository if you find it useful!**

Made with ❤️ for the Docker community

</div>
