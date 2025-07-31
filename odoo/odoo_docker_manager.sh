#!/bin/bash
# Simplified Odoo manager with Docker Compose

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
COMPOSE_FILE="$SCRIPT_DIR/compose.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Logging functions
log() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1" >&2; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
info() { echo -e "${CYAN}💡${NC} $1"; }

clear_screen() {
    clear
    echo -e "${BOLD}${CYAN}🐋 ODOO DOCKER MANAGER - $PROJECT_NAME${NC}\n"
}

pause() {
    echo -e "\n${YELLOW}Press ENTER to continue...${NC}"
    read -r
}

check_deps() {
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed. Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! docker compose version >/dev/null 2>&1; then
        error "Docker Compose is not available"
        exit 1
    fi
}

# Función para detectar y configurar SELinux (solo se usa en fix_permissions)
check_and_configure_selinux() {
    # Check if SELinux is available and active
    if command -v getenforce >/dev/null 2>&1; then
        local selinux_status=$(getenforce 2>/dev/null || echo "Disabled")

        if [[ "$selinux_status" == "Enforcing" ]]; then
            warn "SELinux detected in Enforcing mode"

            # Check if extra-addons directory exists
            if [[ -d "$SCRIPT_DIR/extra-addons" ]]; then
                log "Applying SELinux context for Docker..."

                # Apply SELinux context for containers
                if sudo chcon -Rt svirt_sandbox_file_t "$SCRIPT_DIR/extra-addons" 2>/dev/null; then
                    success "SELinux context applied correctly"
                else
                    warn "Could not apply SELinux context automatically"
                    info "Run manually: sudo chcon -Rt svirt_sandbox_file_t $SCRIPT_DIR/extra-addons"
                fi

                # Enable container policy if possible
                if sudo setsebool -P container_manage_cgroup on 2>/dev/null; then
                    success "SELinux policy for containers enabled"
                fi
            fi
        elif [[ "$selinux_status" == "Permissive" ]]; then
            info "SELinux in Permissive mode - should not cause problems"
        else
            info "SELinux disabled"
        fi
    fi
}

# Función para crear directorio con permisos básicos para Odoo
ensure_extra_addons_dir() {
    local dir_path="$SCRIPT_DIR/extra-addons"

    if [[ ! -d "$dir_path" ]]; then
        mkdir -p "$dir_path"

        # Apply correct owner (odoo user = 101:101) and permissions
        if command -v sudo >/dev/null 2>&1; then
            if sudo chown -R 101:101 "$dir_path" 2>/dev/null; then
                success "extra-addons directory created with owner 101:101"
            else
                warn "Could not set owner, directory created with current user"
            fi
        fi

        # Apply 777 permissions recursively
        if chmod -R 777 "$dir_path" 2>/dev/null; then
            success "777 permissions applied to extra-addons"
        else
            warn "Could not apply 777 permissions"
        fi
    fi
}

load_env_vars() {
    if [[ -f "$SCRIPT_DIR/.env" ]]; then
        export $(grep -v '^#' "$SCRIPT_DIR/.env" | grep -v '^$' | xargs)
    fi
}

create_env_template() {
    local env_file="$SCRIPT_DIR/.env"
    [[ -f "$env_file" ]] && return

    cat > "$env_file" << 'EOF'
# Odoo version to use
ODOO_VERSION=18

# APT packages you want to install in the custom image
# Separated by spaces
APT_PACKAGES=

# Python pip packages you want to install
# Separated by spaces
PIP_PACKAGES=

# Port to access Odoo (default 8069)
ODOO_PORT=8069

# Database configuration
POSTGRES_USER=odoo
POSTGRES_PASSWORD=odoo
POSTGRES_DB=postgres
EOF
    success ".env file created with default values"
}

generate_dockerfile() {
    local dockerfile_path="$SCRIPT_DIR/Dockerfile"

    # Solo generar si no existe o si se fuerza la regeneración
    if [[ -f "$dockerfile_path" ]] && [[ "${FORCE_DOCKERFILE_REGEN:-}" != "true" ]]; then
        return
    fi

    # Load variables from .env
    load_env_vars

    local base_version="${ODOO_VERSION:-18}"
    local apt_packages="${APT_PACKAGES:-}"
    local pip_packages="${PIP_PACKAGES:-}"

    log "Generating Dockerfile for Odoo $base_version..."

    cat > "$dockerfile_path" << EOF
FROM odoo:$base_version

USER root

# Install additional APT packages
EOF

    if [[ -n "$apt_packages" ]]; then
        echo "RUN apt-get update && apt-get install -y \\" >> "$dockerfile_path"
        for package in $apt_packages; do
            echo "    $package \\" >> "$dockerfile_path"
        done
        echo "    && apt-get clean && rm -rf /var/lib/apt/lists/*" >> "$dockerfile_path"
    else
        echo "# No additional APT packages configured" >> "$dockerfile_path"
    fi

    cat >> "$dockerfile_path" << 'EOF'

USER odoo

# Install additional Python packages (avoiding PEP668)
EOF

    if [[ -n "$pip_packages" ]]; then
        if [[ $(echo $pip_packages | wc -w) -eq 1 ]]; then
            # Single package - no backslash needed
            echo "RUN pip3 install --no-cache-dir --break-system-packages $pip_packages" >> "$dockerfile_path"
        else
            # Multiple packages - use backslashes correctly
            echo "RUN pip3 install --no-cache-dir --break-system-packages \\" >> "$dockerfile_path"
            local packages_array=($pip_packages)
            for i in "${!packages_array[@]}"; do
                if [[ $i -eq $((${#packages_array[@]} - 1)) ]]; then
                    # Last package, no backslash
                    echo "    ${packages_array[$i]}" >> "$dockerfile_path"
                else
                    # Not last package, add backslash
                    echo "    ${packages_array[$i]} \\" >> "$dockerfile_path"
                fi
            done
        fi
    else
        echo "# No additional Python packages configured" >> "$dockerfile_path"
    fi

    success "Dockerfile generated for Odoo $base_version"

    if [[ -n "$apt_packages" ]]; then
        info "APT packages: $apt_packages"
    fi

    if [[ -n "$pip_packages" ]]; then
        info "Python packages: $pip_packages (installed with --break-system-packages)"
    fi
}

create_compose() {
    [[ -f "$COMPOSE_FILE" ]] && return

    # Load variables from .env
    load_env_vars

    local odoo_port="${ODOO_PORT:-8069}"
    local postgres_user="${POSTGRES_USER:-odoo}"
    local postgres_password="${POSTGRES_PASSWORD:-odoo}"
    local postgres_db="${POSTGRES_DB:-postgres}"

    cat > "$COMPOSE_FILE" << EOF
services:
  db:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_USER: $postgres_user
      POSTGRES_PASSWORD: $postgres_password
      POSTGRES_DB: $postgres_db
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $postgres_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  odoo:
    build:
      context: .
      dockerfile: Dockerfile
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "$odoo_port:8069"
    environment:
      - HOST=db
      - USER=$postgres_user
      - PASSWORD=$postgres_password
    volumes:
      - odoo_data:/var/lib/odoo
      - ./extra-addons:/mnt/extra-addons:rw
    restart: unless-stopped

volumes:
  db_data:
  odoo_data:
EOF
    success "compose.yaml created with custom configuration"
}

setup_project() {
    log "Setting up project..."

    create_env_template
    load_env_vars
    generate_dockerfile
    create_compose
    ensure_extra_addons_dir  # Solo crea el directorio, sin permisos especiales

    success "Project configured"
}

# Función específica para arreglar permisos (SOLO se ejecuta con la opción 5)
fix_permissions() {
    clear_screen
    log "Applying 777 permissions to extra-addons..."

    local dir_path="$SCRIPT_DIR/extra-addons"

    # Create directory if it doesn't exist
    if [[ ! -d "$dir_path" ]]; then
        mkdir -p "$dir_path"
        success "extra-addons directory created"
    fi

    # Apply recursive chmod 777
    if sudo chmod -R 777 "$dir_path"; then
        success "777 permissions applied recursively to extra-addons"
    else
        error "Could not apply permissions"
    fi

    # Apply SELinux fix if available
    check_and_configure_selinux

    # Show directory contents
    local module_count=$(find "$dir_path" -maxdepth 1 -type d ! -path "$dir_path" 2>/dev/null | wc -l)
    if [[ $module_count -gt 0 ]]; then
        info "Modules found: $module_count"
        ls -la "$dir_path" | grep '^d' | awk '{print "  -", $9}' | grep -v '^\s*-\s*\.$' | grep -v '^\s*-\s*\.\.$'
    else
        info "No modules in extra-addons"
    fi
}

get_status() {
    local odoo_running=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | grep '"Name":".*odoo"' | grep -q '"State":"running"' && echo "true" || echo "false")
    local db_running=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | grep '"Name":".*db"' | grep -q '"State":"running"' && echo "true" || echo "false")
    local services_exist=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | grep -q '"Name":".*odoo"' && echo "true" || echo "false")

    if [[ "$odoo_running" == "true" && "$db_running" == "true" ]]; then
        echo "running"
    elif [[ "$services_exist" == "true" ]]; then
        echo "stopped"
    else
        echo "not_created"
    fi
}

show_status() {
    load_env_vars
    local status=$(get_status)
    local modules=$(find "$SCRIPT_DIR/extra-addons" -maxdepth 1 -type d ! -path "$SCRIPT_DIR/extra-addons" 2>/dev/null | wc -l)
    local odoo_version="${ODOO_VERSION:-18}"
    local odoo_port="${ODOO_PORT:-8069}"

    # Detailed status of individual services
    local odoo_status=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | grep '"Name":".*odoo"' | grep -q '"State":"running"' && echo "🟢 Running" || echo "🔴 Stopped")
    local db_status=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | grep '"Name":".*db"' | grep -q '"State":"running"' && echo "🟢 Running" || echo "🔴 Stopped")

    echo -e "${BOLD}📊 System Status:${NC}"
    echo "  Odoo $odoo_version: $odoo_status"
    echo "  PostgreSQL: $db_status"

    # Show SELinux status if available
    if command -v getenforce >/dev/null 2>&1; then
        local selinux_status=$(getenforce 2>/dev/null || echo "Error")
        local selinux_icon="ℹ️"
        if [[ "$selinux_status" == "Enforcing" ]]; then
            selinux_icon="⚠️"
        fi
        echo "  SELinux: $selinux_icon $selinux_status"
    fi
    echo ""

    case $status in
        "running")
            success "Complete stack running"
            info "Web access: http://localhost:$odoo_port"
            ;;
        "stopped")
            warn "Stack stopped - use 'Start' option"
            ;;
        *)
            info "Stack not configured"
            ;;
    esac

    [[ $modules -gt 0 ]] && info "Extra modules available: $modules"

    # Show custom configuration
    if [[ -n "${APT_PACKAGES:-}" ]] || [[ -n "${PIP_PACKAGES:-}" ]]; then
        echo ""
        info "Custom configuration:"
        [[ -n "${APT_PACKAGES:-}" ]] && echo "  APT: ${APT_PACKAGES}"
        [[ -n "${PIP_PACKAGES:-}" ]] && echo "  PIP: ${PIP_PACKAGES} (with --break-system-packages)"
    fi
    echo ""
}

start() {
    clear_screen
    load_env_vars
    log "Starting Odoo services..."

    local odoo_port="${ODOO_PORT:-8069}"

    if docker compose -f "$COMPOSE_FILE" up -d --build; then
        success "Odoo started successfully"
        info "Web access: http://localhost:$odoo_port"
        [[ -d "$SCRIPT_DIR/extra-addons" ]] && info "To use extra modules: Apps > Update Apps List"
        info "If you have permission issues, use option 5 to fix permissions"
    else
        error "Error starting Odoo"
        warn "If there are permission issues, use option 5 to fix permissions"
    fi
}

stop() {
    clear_screen
    log "Stopping Odoo services..."

    if docker compose -f "$COMPOSE_FILE" down; then
        success "Odoo stopped successfully"
    else
        error "Error stopping Odoo"
    fi
}

restart() {
    clear_screen
    load_env_vars
    log "Restarting Odoo services..."

    local odoo_port="${ODOO_PORT:-8069}"

    if docker compose -f "$COMPOSE_FILE" restart; then
        success "Odoo restarted successfully"
        info "Web access: http://localhost:$odoo_port"
        info "If you have permission issues, use option 5 to fix permissions"
    else
        error "Error restarting Odoo"
        warn "If there are permission issues, use option 5 to fix permissions"
    fi
}

rebuild() {
    clear_screen
    load_env_vars
    log "Rebuilding Odoo image..."

    local odoo_port="${ODOO_PORT:-8069}"

    # Forzar regeneración del Dockerfile con configuración actual
    FORCE_DOCKERFILE_REGEN=true generate_dockerfile

    if docker compose -f "$COMPOSE_FILE" up -d --build --force-recreate; then
        success "Image rebuilt and Odoo started successfully"
        info "Web access: http://localhost:$odoo_port"
        info "If you have permission issues, use option 5 to fix permissions"
    else
        error "Error rebuilding image"
        warn "If there are permission issues, use option 5 to fix permissions"
    fi
}

show_logs() {
    clear_screen
    info "Showing Odoo logs in real time (Ctrl+C to exit)"
    echo ""
    docker compose -f "$COMPOSE_FILE" logs -f odoo
}

clean_data() {
    clear_screen
    warn "WARNING: This operation will delete ALL Odoo data"
    error "This action is IRREVERSIBLE and cannot be undone"
    echo ""

    read -p "$(echo -e ${YELLOW})Type 'CONFIRM' to proceed: $(echo -e ${NC})" confirm

    if [[ "$confirm" == "CONFIRM" ]]; then
        log "Deleting data and volumes..."
        if docker compose -f "$COMPOSE_FILE" down -v; then
            success "Data deleted successfully"
        else
            error "Error deleting data"
        fi
    else
        info "Operation cancelled by user"
    fi
}

show_help() {
    clear_screen
    load_env_vars
    echo -e "${BOLD}📖 Help - Odoo Docker Manager${NC}\n"

    echo -e "${BOLD}Available commands:${NC}"
    echo "  ./odoo_docker_manager.sh start           - Start Odoo services"
    echo "  ./odoo_docker_manager.sh stop            - Stop Odoo services"
    echo "  ./odoo_docker_manager.sh restart         - Restart Odoo services"
    echo "  ./odoo_docker_manager.sh rebuild         - Rebuild custom image"
    echo "  ./odoo_docker_manager.sh logs            - Show real-time logs"
    echo "  ./odoo_docker_manager.sh clean           - Delete all data"
    echo "  ./odoo_docker_manager.sh fix-permissions - Fix permission issues"
    echo "  ./odoo_docker_manager.sh help            - Show this help"
    echo "  ./odoo_docker_manager.sh                 - Start interactive menu"
    echo ""

    echo -e "${BOLD}Custom configuration (.env):${NC}"
    info "File: ./.env"
    info "Current version: Odoo ${ODOO_VERSION:-18}"
    info "Port: ${ODOO_PORT:-8069}"
    [[ -n "${APT_PACKAGES:-}" ]] && info "APT packages: ${APT_PACKAGES}"
    [[ -n "${PIP_PACKAGES:-}" ]] && info "Python packages: ${PIP_PACKAGES} (with --break-system-packages)"
    echo ""

    echo -e "${BOLD}Extra modules management:${NC}"
    info "Move modules to directory: ./extra-addons/"
    info "In Odoo: Apps > Update Apps List"
    echo ""

    echo -e "${BOLD}Troubleshooting (SELinux/Permissions):${NC}"
    warn "If you have permission errors:"
    info "Use option 5 (Fix permissions) from the menu"
    info "Or run: ./odoo_docker_manager.sh fix-permissions"
    echo ""

    echo -e "${BOLD}Additional information:${NC}"
    info "Database: PostgreSQL 15"
    info "DB User: ${POSTGRES_USER:-odoo} / ${POSTGRES_PASSWORD:-odoo}"
    info "After modifying .env, use 'rebuild' to apply changes"
    info "Automatic support for SELinux on Fedora/Red Hat/CentOS"
    info "Python packages installed with --break-system-packages (avoids PEP668)"
}

open_odoo_shell() {
    clear_screen
    log "Opening Odoo shell..."
    docker compose -f "$COMPOSE_FILE" exec odoo odoo shell
}

show_menu() {
    local status=$(get_status)

    echo -e "${BOLD}Available options:${NC}"

    if [[ "$status" == "running" ]]; then
        echo "1) 🛑 Stop services"
        echo "2) 🔄 Restart services"
        echo "3) 🔨 Rebuild image"
        echo "4) 📋 View real-time logs"
        echo "5) 🔧 Fix permissions (SELinux/Docker)"
        echo "6) 📖 Show help"
        echo "7) 🐚 Open Odoo shell"
        echo "8) 🚪 Exit"
    else
        echo "1) 🚀 Start services"
        echo "2) 🔨 Rebuild image"
        echo "3) 🔧 Fix permissions (SELinux/Docker)"
        echo "4) 🗑️ Clean all data"
        echo "5) 📖 Show help"
        echo "6) 🚪 Exit"
    fi
    echo ""
}

interactive_menu() {
    while true; do
        clear_screen
        show_status
        show_menu

        read -p "$(echo -e ${CYAN})Select an option: $(echo -e ${NC})" choice

        local status=$(get_status)

        if [[ "$status" == "running" ]]; then
            case $choice in
                1) stop; pause ;;
                2) restart; pause ;;
                3) rebuild; pause ;;
                4) show_logs ;;
                5) fix_permissions; pause ;;
                6) show_help; pause ;;
                7) open_odoo_shell; pause ;;
                8) echo -e "\n${GREEN}Goodbye!${NC}"; exit 0 ;;
                *) error "Invalid option, please try again"; pause ;;
            esac
        else
            case $choice in
                1) start; pause ;;
                2) rebuild; pause ;;
                3) fix_permissions; pause ;;
                4) clean_data; pause ;;
                5) show_help; pause ;;
                6) echo -e "\n${GREEN}Goodbye!${NC}"; exit 0 ;;
                *) error "Invalid option, please try again"; pause ;;
            esac
        fi
    done
}

main() {
    check_deps
    setup_project

    case "${1:-menu}" in
        start) start ;;
        stop) stop ;;
        restart) restart ;;
        rebuild) rebuild ;;
        logs) show_logs ;;
        clean) clean_data ;;
        fix-permissions) fix_permissions ;;
        help) show_help ;;
        *) interactive_menu ;;
    esac
}

main "$@"
