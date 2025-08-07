# Odoo Docker Manager

<p align="center"><img width="1471" height="426" alt="image" src="https://github.com/user-attachments/assets/aaac23c3-122a-420d-91bc-9831a32c95db" /></p>

Management script for deploying Odoo ERP with Docker Compose. Sets up Odoo with PostgreSQL, custom modules, and package management in one command.

## Quick Start

```bash
# Make executable and run
chmod +x odoo_docker_manager.sh
./odoo_docker_manager.sh
# Access Odoo at http://localhost:8069
```

## Features

- Interactive menu interface
- Install APT and Python packages
- Module management - drop modules in `extra-addons/` (folder must be in the same path as the script)
- SELinux configuration for RHEL/Fedora
- Real-time logs with `./odoo_docker_manager.sh logs`

## Configuration

Edit `.env` file (created automatically):

```bash
ODOO_VERSION=18                   # Odoo version
ODOO_PORT=8069                    # Access port
APT_PACKAGES=git curl             # System packages
PIP_PACKAGES=requests pillow      # Python packages
POSTGRES_PASSWORD=odoo            # Database password
```

After changes: `./odoo_docker_manager.sh rebuild`

## Custom Modules

1. Copy modules to `extra-addons/` directory
2. Restart: `./odoo_docker_manager.sh restart`
3. In Odoo: Apps → Update Apps List

## Commands

```bash
./odoo_docker_manager.sh start           # Start services
./odoo_docker_manager.sh stop            # Stop services
./odoo_docker_manager.sh restart         # Restart services
./odoo_docker_manager.sh rebuild         # Rebuild with new config
./odoo_docker_manager.sh logs            # Show real-time logs
./odoo_docker_manager.sh fix-permissions # Fix permission issues
./odoo_docker_manager.sh clean           # Remove all data
./odoo_docker_manager.sh help            # Show help
```

## Troubleshooting

**Permission errors**: `./odoo_docker_manager.sh fix-permissions`

**Port in use**: Change `ODOO_PORT` in `.env` and rebuild

**SELinux issues**: Script handles automatically, or manually:
```bash
sudo chcon -Rt svirt_sandbox_file_t extra-addons/
```

**Module not showing**: Check `extra-addons/module/__manifest__.py` exists

## Requirements

- Docker & Docker Compose
- 4GB RAM recommended
- Linux, macOS, or Windows with WSL2
