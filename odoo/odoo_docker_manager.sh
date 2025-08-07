#!/bin/bash
# Optimized Odoo Docker Manager

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

# Status cache
STATUS_CACHE=""
STATUS_CACHE_TIME=0

# Load environment once at startup
load_env_vars() {
    [[ -f "$SCRIPT_DIR/.env" ]] || return 0
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
        export "$key=$value"
    done < "$SCRIPT_DIR/.env"
}

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

# Cached status function
get_status() {
    local current_time=$(date +%s)
    if [[ $((current_time - STATUS_CACHE_TIME)) -lt 2 ]]; then
        echo "$STATUS_CACHE"
        return
    fi

    local compose_output=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null)
    local odoo_running=$(echo "$compose_output" | grep '"Name":".*odoo"' | grep -q '"State":"running"' && echo "true" || echo "false")
    local db_running=$(echo "$compose_output" | grep '"Name":".*db"' | grep -q '"State":"running"' && echo "true" || echo "false")
    local services_exist=$(echo "$compose_output" | grep -q '"Name":".*odoo"' && echo "true" || echo "false")

    if [[ "$odoo_running" == "true" && "$db_running" == "true" ]]; then
        STATUS_CACHE="running"
    elif [[ "$services_exist" == "true" ]]; then
        STATUS_CACHE="stopped"
    else
        STATUS_CACHE="not_created"
    fi

    STATUS_CACHE_TIME=$current_time
    echo "$STATUS_CACHE"
}

wait_for_service() {
    local service="$1"
    local timeout=60
    local count=0

    while [[ $count -lt $timeout ]]; do
        if docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | grep "\"Name\":\".*$service\"" | grep -q '"State":"running"'; then
            return 0
        fi
        sleep 2
        ((count += 2))
    done
    return 1
}

check_deps() {
    command -v docker >/dev/null 2>&1 || { error "Docker not installed"; exit 1; }
    docker compose version >/dev/null 2>&1 || { error "Docker Compose not available"; exit 1; }
    docker info >/dev/null 2>&1 || { error "Docker daemon not running"; exit 1; }
    docker ps >/dev/null 2>&1 || { error "Cannot access Docker - add user to docker group"; exit 1; }
}

# SELinux detection and configuration
check_and_configure_selinux() {
    local dir_path="$SCRIPT_DIR/extra-addons"

    # Check if SELinux is available and active
    if command -v getenforce >/dev/null 2>&1; then
        local selinux_status=$(getenforce 2>/dev/null || echo "Disabled")

        if [[ "$selinux_status" == "Enforcing" ]]; then
            warn "SELinux detected in Enforcing mode"

            # Check if extra-addons directory exists
            if [[ -d "$dir_path" ]]; then
                log "Applying SELinux context for Docker..."

                # Apply SELinux context for containers
                if sudo chcon -Rt svirt_sandbox_file_t "$dir_path" 2>/dev/null; then
                    success "SELinux context applied correctly"
                else
                    warn "Could not apply SELinux context automatically"
                    info "Run manually: sudo chcon -Rt svirt_sandbox_file_t $dir_path"
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

# Enhanced directory creation with automatic permissions and SELinux
ensure_extra_addons_dir() {
    local dir_path="$SCRIPT_DIR/extra-addons"

    if [[ ! -d "$dir_path" ]]; then
        log "Creating extra-addons directory with proper permissions..."
        mkdir -p "$dir_path"

        # Apply 777 permissions automatically
        if chmod -R 777 "$dir_path" 2>/dev/null; then
            success "extra-addons directory created with 777 permissions"
        else
            warn "Could not apply 777 permissions automatically"
        fi

        # Apply SELinux configuration automatically if needed
        if command -v getenforce >/dev/null 2>&1; then
            local selinux_status=$(getenforce 2>/dev/null || echo "Disabled")

            if [[ "$selinux_status" == "Enforcing" ]]; then
                log "Applying SELinux context for Docker..."

                if sudo chcon -Rt svirt_sandbox_file_t "$dir_path" 2>/dev/null; then
                    success "SELinux context applied automatically"
                else
                    warn "Could not apply SELinux context automatically"
                    info "Run manually: sudo chcon -Rt svirt_sandbox_file_t $dir_path"
                fi

                # Enable container policy if possible
                if sudo setsebool -P container_manage_cgroup on 2>/dev/null; then
                    success "SELinux policy for containers enabled"
                fi
            elif [[ "$selinux_status" == "Permissive" ]]; then
                info "SELinux in Permissive mode - no additional configuration needed"
            fi
        fi
    fi
}

# Permission management (ONLY used when explicitly called)
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
    if chmod -R 777 "$dir_path"; then
        success "777 permissions applied recursively to extra-addons"
    else
        error "Could not apply permissions"
        return 1
    fi

    # Apply SELinux fix using the shared function
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

create_env_template() {
    [[ -f "$SCRIPT_DIR/.env" ]] && return
    cat > "$SCRIPT_DIR/.env" << 'EOF'
# Odoo version to use
ODOO_VERSION=18

# APT packages (space-separated)
APT_PACKAGES=

# Python packages (space-separated)
PIP_PACKAGES=

# Port configuration
ODOO_PORT=8069

# Database configuration
POSTGRES_USER=odoo
POSTGRES_PASSWORD=odoo
POSTGRES_DB=postgres
EOF
    success ".env file created"
}

generate_dockerfile() {
    [[ -f "$SCRIPT_DIR/Dockerfile" ]] && [[ "${FORCE_DOCKERFILE_REGEN:-}" != "true" ]] && return 0

    log "Generating Dockerfile for Odoo ${ODOO_VERSION:-18}..."

    cat > "$SCRIPT_DIR/Dockerfile" << EOF
FROM odoo:${ODOO_VERSION:-18}
USER root
EOF

    if [[ -n "${APT_PACKAGES:-}" ]]; then
        echo "RUN apt-get update && apt-get install -y $APT_PACKAGES && apt-get clean" >> "$SCRIPT_DIR/Dockerfile"
    fi

    echo "USER odoo" >> "$SCRIPT_DIR/Dockerfile"

    if [[ -n "${PIP_PACKAGES:-}" ]]; then
        echo "RUN pip3 install --no-cache-dir --break-system-packages $PIP_PACKAGES" >> "$SCRIPT_DIR/Dockerfile"
    fi

    success "Dockerfile generated"
}

create_compose() {
    [[ -f "$COMPOSE_FILE" ]] && return 0

    cat > "$COMPOSE_FILE" << EOF
services:
  db:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-odoo}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-odoo}
      POSTGRES_DB: ${POSTGRES_DB:-postgres}
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-odoo}"]
      interval: 10s
      timeout: 5s
      retries: 5

  odoo:
    build: .
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "${ODOO_PORT:-8069}:8069"
    environment:
      - HOST=db
      - USER=${POSTGRES_USER:-odoo}
      - PASSWORD=${POSTGRES_PASSWORD:-odoo}
    volumes:
      - odoo_data:/var/lib/odoo
      - ./extra-addons:/mnt/extra-addons:rw
    restart: unless-stopped

volumes:
  db_data:
  odoo_data:
EOF
    success "compose.yaml created"
}

setup_project() {
    create_env_template
    load_env_vars
    generate_dockerfile
    create_compose
    ensure_extra_addons_dir  # Creates directory with automatic permissions and SELinux
}

show_status() {
    local status=$(get_status)
    local modules=$(find "$SCRIPT_DIR/extra-addons" -maxdepth 1 -type d ! -path "$SCRIPT_DIR/extra-addons" 2>/dev/null | wc -l)

    echo -e "${BOLD}📊 System Status:${NC}"
    echo "  Odoo ${ODOO_VERSION:-18}: $(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | grep '"Name":".*odoo"' | grep -q '"State":"running"' && echo "🟢 Running" || echo "🔴 Stopped")"
    echo "  PostgreSQL: $(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | grep '"Name":".*db"' | grep -q '"State":"running"' && echo "🟢 Running" || echo "🔴 Stopped")"

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
            success "Stack running - http://localhost:${ODOO_PORT:-8069}"
            ;;
        "stopped")
            warn "Stack stopped"
            ;;
        *)
            info "Stack not configured"
            ;;
    esac

    [[ $modules -gt 0 ]] && info "Extra modules: $modules"
    [[ -n "${APT_PACKAGES:-}${PIP_PACKAGES:-}" ]] && info "Custom packages configured"
    echo ""
}

start() {
    clear_screen
    log "Starting Odoo services..."

    if ! docker compose -f "$COMPOSE_FILE" up -d --build; then
        error "Failed to start services"
        warn "If there are permission issues, use fix-permissions option"
        return 1
    fi

    log "Waiting for services..."
    sleep 5

    if wait_for_service "db" && wait_for_service "odoo"; then
        success "Odoo started - http://localhost:${ODOO_PORT:-8069}"
        info "For extra modules: Apps > Update Apps List"
    else
        error "Services failed to start properly"
        warn "If there are permission issues, use fix-permissions option"
        return 1
    fi
}

stop() {
    clear_screen
    log "Stopping services..."
    docker compose -f "$COMPOSE_FILE" down && success "Stopped successfully"
}

restart() {
    clear_screen
    log "Restarting services..."
    docker compose -f "$COMPOSE_FILE" restart
    sleep 3
    if [[ "$(get_status)" == "running" ]]; then
        success "Restarted - http://localhost:${ODOO_PORT:-8069}"
    else
        error "Restart failed"
        warn "If there are permission issues, use fix-permissions option"
    fi
}

rebuild() {
    clear_screen
    log "Rebuilding image..."
    FORCE_DOCKERFILE_REGEN=true generate_dockerfile
    docker compose -f "$COMPOSE_FILE" up -d --build --force-recreate
    sleep 5
    if [[ "$(get_status)" == "running" ]]; then
        success "Rebuilt - http://localhost:${ODOO_PORT:-8069}"
    else
        error "Rebuild failed"
        warn "If there are permission issues, use fix-permissions option"
    fi
}

show_logs() {
    clear_screen
    info "Odoo logs (Ctrl+C to exit)"
    docker compose -f "$COMPOSE_FILE" logs -f odoo
}

clean_data() {
    clear_screen
    warn "WARNING: This will delete ALL Odoo data permanently!"
    read -p "Type 'CONFIRM' to proceed: " confirm

    if [[ "$confirm" == "CONFIRM" ]]; then
        log "Deleting data..."
        docker compose -f "$COMPOSE_FILE" down -v
        docker volume prune -f >/dev/null 2>&1 || true
        success "Data deleted"
    else
        info "Cancelled"
    fi
}

open_odoo_shell() {
    clear_screen
    log "Opening Odoo shell..."

    if [[ "$(get_status)" != "running" ]]; then
        error "Odoo not running - start it first"
        return 1
    fi

    docker compose -f "$COMPOSE_FILE" exec odoo odoo shell
}

run_tests() {
    clear_screen
    local modules="${1:-}"

    if [[ -z "$modules" ]]; then
        echo -e "${BOLD}Test Options:${NC}"
        echo "1) Run ALL tests"
        echo "2) Enter module name(s)"
        read -p "Choose (1-2): " choice

        case "$choice" in
            1) modules="" ;;
            2) read -p "Module name(s) (comma-separated): " modules ;;
            *) error "Invalid option"; return 1 ;;
        esac
    fi

    if [[ "$(get_status)" != "running" ]]; then
        error "Odoo not running - start it first"
        return 1
    fi

    local test_db="test_$(date +%Y%m%d_%H%M%S)"

    if [[ -z "$modules" ]]; then
        log "Running ALL tests..."
        docker compose -f "$COMPOSE_FILE" exec odoo odoo -d "$test_db" --test-enable --stop-after-init --log-level=test --without-demo=all
    else
        log "Testing modules: $modules"
        docker compose -f "$COMPOSE_FILE" exec odoo odoo -d "$test_db" --test-enable --stop-after-init --log-level=test --without-demo=all -i "$modules"
    fi

    # Cleanup
    docker compose -f "$COMPOSE_FILE" exec db psql -U "${POSTGRES_USER:-odoo}" -c "DROP DATABASE IF EXISTS $test_db;" 2>/dev/null || true
    [[ $? -eq 0 ]] && success "Tests completed" || error "Tests failed"
}

show_help() {
    clear_screen
    echo -e "${BOLD}📖 Odoo Docker Manager Help${NC}\n"
    echo "Commands:"
    echo "  start           - Start Odoo services"
    echo "  stop            - Stop services"
    echo "  restart         - Restart services"
    echo "  rebuild         - Rebuild with current config"
    echo "  logs            - Show real-time logs"
    echo "  test [modules]  - Run tests"
    echo "  clean           - Delete all data"
    echo "  fix-permissions - Fix permission issues (SELinux/Docker)"
    echo "  shell           - Open Odoo shell"
    echo "  help            - Show this help"
    echo ""
    echo "Configuration: Edit .env file"
    echo "Extra modules: Place in ./extra-addons/"
    echo ""
    echo -e "${BOLD}Troubleshooting:${NC}"
    info "Permission issues are automatically handled during setup"
    info "Use 'fix-permissions' if you encounter permission errors later"
    info "Automatic support for SELinux on Fedora/Red Hat/CentOS"
}

show_menu() {
    local status=$(get_status)
    echo -e "${BOLD}Available options:${NC}"

    if [[ "$status" == "running" ]]; then
        echo "1) 🛑 Stop services"
        echo "2) 🔄 Restart services"
        echo "3) 🔨 Rebuild image"
        echo "4) 📋 View logs"
        echo "5) 🔧 Fix permissions (SELinux/Docker)"
        echo "6) 🐚 Open shell"
        echo "7) 🧪 Run tests"
        echo "8) 📖 Help"
        echo "9) 🚪 Exit"
    else
        echo "1) 🚀 Start services"
        echo "2) 🔨 Rebuild image"
        echo "3) 🔧 Fix permissions (SELinux/Docker)"
        echo "4) 🗑️ Clean data"
        echo "5) 📖 Help"
        echo "6) 🚪 Exit"
    fi
    echo ""
}

interactive_menu() {
    while true; do
        clear_screen
        show_status
        show_menu

        read -p "$(echo -e ${CYAN})Select option: $(echo -e ${NC})" choice
        local status=$(get_status)

        if [[ "$status" == "running" ]]; then
            case $choice in
                1) stop; pause ;;
                2) restart; pause ;;
                3) rebuild; pause ;;
                4) show_logs ;;
                5) fix_permissions; pause ;;
                6) open_odoo_shell; pause ;;
                7) run_tests; pause ;;
                8) show_help; pause ;;
                9) echo -e "\n${GREEN}Goodbye!${NC}"; exit 0 ;;
                *) error "Invalid option"; pause ;;
            esac
        else
            case $choice in
                1) start; pause ;;
                2) rebuild; pause ;;
                3) fix_permissions; pause ;;
                4) clean_data; pause ;;
                5) show_help; pause ;;
                6) echo -e "\n${GREEN}Goodbye!${NC}"; exit 0 ;;
                *) error "Invalid option"; pause ;;
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
        test) shift; run_tests "$*" ;;
        clean) clean_data ;;
        fix-permissions) fix_permissions ;;
        shell) open_odoo_shell ;;
        help) show_help ;;
        *) interactive_menu ;;
    esac
}

main "$@"
