#!/usr/bin/with-contenv bashio

# Get configuration options
LOG_LEVEL=$(bashio::config 'log_level')
ENABLE_AGENT=$(bashio::config 'enable_agent')
AGENT_PORT=$(bashio::config 'agent_port')
BESZEL_VERSION_CONFIG=$(bashio::config 'beszel_version' 'latest')

bashio::log.info "Starting Beszel Server Monitor..."
bashio::log.info "Log level: ${LOG_LEVEL}"

# Set data directory to persistent storage
export BESZEL_DATA_DIR="/config/beszel_data"

# Detect CPU architecture and map to Beszel release label
detect_arch() {
    local machine
    machine=$(uname -m)
    case "${machine}" in
        x86_64)         echo "amd64" ;;
        aarch64)        echo "arm64" ;;
        armv7l|armhf|armv7) echo "arm" ;;
        *)
            bashio::log.error "Unsupported architecture: ${machine}"
            exit 1
            ;;
    esac
}

# Download a single beszel binary tarball and install it to /usr/local/bin
# Usage: download_beszel_binary <binary_name> <version> <arch>
# Returns 0 on success, 1 on failure
download_beszel_binary() {
    local binary_name="$1"
    local version="$2"
    local arch="$3"
    local tarball="/tmp/${binary_name}.tar.gz"
    local url

    if [ "${version}" = "latest" ]; then
        url="https://github.com/henrygd/beszel/releases/latest/download/${binary_name}_linux_${arch}.tar.gz"
    else
        url="https://github.com/henrygd/beszel/releases/download/${version}/${binary_name}_linux_${arch}.tar.gz"
    fi

    bashio::log.info "Downloading ${binary_name} from ${url}..."
    if ! wget -q -O "${tarball}" "${url}"; then
        bashio::log.warning "Failed to download ${binary_name}"
        rm -f "${tarball}"
        return 1
    fi

    if ! tar -xzf "${tarball}" -C /usr/local/bin/ "${binary_name}" 2>/dev/null; then
        bashio::log.warning "Failed to extract ${binary_name}"
        rm -f "${tarball}"
        return 1
    fi

    chmod +x "/usr/local/bin/${binary_name}"
    rm -f "${tarball}"
    return 0
}

# Install or update beszel binaries based on configured version
install_or_update_beszel() {
    local configured_version="$1"
    local arch
    local installed_version
    local target_version

    # Detect architecture
    arch=$(detect_arch)
    bashio::log.info "Detected architecture: ${arch}"

    # Get installed version (or "none" if not present)
    if command -v beszel &>/dev/null; then
        installed_version=$(beszel --version 2>&1 | grep -oP 'v\d+\.\d+\.\d+' || echo "none")
    else
        installed_version="none"
    fi

    # Resolve target version
    if [ "${configured_version}" = "latest" ]; then
        bashio::log.info "Checking GitHub for latest Beszel release..."
        target_version=$(curl -sf https://api.github.com/repos/henrygd/beszel/releases/latest | jq -r '.tag_name' 2>/dev/null || echo "")

        if [ -z "${target_version}" ] || [ "${target_version}" = "null" ]; then
            if [ "${installed_version}" != "none" ]; then
                bashio::log.warning "Could not reach GitHub API — continuing with installed version ${installed_version}"
                return 0
            else
                bashio::log.error "Could not reach GitHub API and no binary is installed — cannot start"
                exit 1
            fi
        fi
    else
        target_version="${configured_version}"
    fi

    bashio::log.info "Installed: ${installed_version}  |  Target: ${target_version}"

    # Install or update if versions differ
    if [ "${installed_version}" != "${target_version}" ]; then
        bashio::log.info "Installing Beszel ${target_version}..."

        local download_ok=true
        if ! download_beszel_binary "beszel" "${configured_version}" "${arch}"; then
            download_ok=false
        fi
        if ! download_beszel_binary "beszel-agent" "${configured_version}" "${arch}"; then
            download_ok=false
        fi

        if [ "${download_ok}" = "false" ]; then
            if [ "${installed_version}" != "none" ]; then
                bashio::log.warning "Download failed — continuing with existing binary ${installed_version}"
                return 0
            else
                bashio::log.error "Download failed and no binary is installed — cannot start"
                exit 1
            fi
        fi

        bashio::log.info "✓ Beszel updated to ${target_version}"
    else
        bashio::log.info "✓ Beszel is up to date (${installed_version})"
    fi

    # For pinned versions: check if a newer release exists and notify
    if [ "${configured_version}" != "latest" ]; then
        bashio::log.info "Checking GitHub for newer Beszel releases..."
        local latest_version
        latest_version=$(curl -sf https://api.github.com/repos/henrygd/beszel/releases/latest | jq -r '.tag_name' 2>/dev/null || echo "")

        if [ -n "${latest_version}" ] && [ "${latest_version}" != "null" ] && [ "${latest_version}" != "${target_version}" ]; then
            bashio::log.warning "╔════════════════════════════════════════════════════════════════════════╗"
            bashio::log.warning "║  NEW BESZEL VERSION AVAILABLE!                                         ║"
            bashio::log.warning "╚════════════════════════════════════════════════════════════════════════╝"
            bashio::log.warning "Pinned: ${target_version} → Available: ${latest_version}"
            bashio::log.warning "Set beszel_version to 'latest' in add-on config to update."
            bashio::log.warning "════════════════════════════════════════════════════════════════════════"

            if bashio::supervisor.ping; then
                bashio::log.info "Sending update notification to Home Assistant..."
                curl -sSL -X POST \
                    -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
                    -H "Content-Type: application/json" \
                    -d "{
                        \"message\": \"Beszel ${latest_version} is available! You are running ${target_version}. Set beszel_version to 'latest' in the add-on configuration to update.\",
                        \"title\": \"Beszel Update Available\",
                        \"notification_id\": \"beszel_update_available\"
                    }" \
                    http://supervisor/core/api/services/persistent_notification/create 2>/dev/null || \
                    bashio::log.debug "Could not send notification to Home Assistant"
            fi
        fi
    fi
}

# Install / update Beszel binaries
install_or_update_beszel "${BESZEL_VERSION_CONFIG}"

# Create data directory if it doesn't exist
mkdir -p "${BESZEL_DATA_DIR}"

bashio::log.info "Data directory: ${BESZEL_DATA_DIR}"
bashio::log.info "Web interface will be available at http://homeassistant.local:8090"

# Handle agent key setup
AGENT_KEY_FILE="${BESZEL_DATA_DIR}/agent_key"

# Start the agent if enabled
if [ "${ENABLE_AGENT}" = "true" ]; then
    bashio::log.info "Agent enabled on port ${AGENT_PORT}"

    # Check if agent key exists
    if [ ! -f "${AGENT_KEY_FILE}" ] || [ ! -s "${AGENT_KEY_FILE}" ]; then
        bashio::log.notice "╔════════════════════════════════════════════════════════════════════════╗"
        bashio::log.notice "║           LOCALHOST AGENT SETUP REQUIRED                               ║"
        bashio::log.notice "╚════════════════════════════════════════════════════════════════════════╝"
        bashio::log.notice ""
        bashio::log.notice "No agent key found - please configure localhost monitoring:"
        bashio::log.notice ""
        bashio::log.notice "1. Open Beszel web UI at http://homeassistant.local:8090"
        bashio::log.notice "2. Click 'Add System' and configure:"
        bashio::log.notice "   - Name: Home Assistant"
        bashio::log.notice "   - Host: 127.0.0.1"
        bashio::log.notice "   - Port: ${AGENT_PORT}"
        bashio::log.notice "3. Copy the generated public key"
        bashio::log.notice "4. Run this command in Terminal add-on or via SSH:"
        bashio::log.notice "   echo 'YOUR_PUBLIC_KEY' > /config/beszel_data/agent_key"
        bashio::log.notice "5. Restart this add-on"
        bashio::log.notice ""
        bashio::log.notice "The agent will start automatically after configuration."
        bashio::log.notice "════════════════════════════════════════════════════════════════════════"
    else
        bashio::log.info "Using existing agent key"
        AGENT_KEY=$(cat "${AGENT_KEY_FILE}")

        # Validate agent key format (basic check)
        if [ ${#AGENT_KEY} -lt 20 ]; then
            bashio::log.warning "Agent key appears invalid (too short)"
            bashio::log.warning "Please reconfigure using the steps above"
        else
            # Check Docker socket availability
            if [ -S /var/run/docker.sock ]; then
                bashio::log.info "Docker socket found - container monitoring enabled"
            else
                bashio::log.warning "Docker socket not found - container stats will not be available"
            fi

            bashio::log.info "Starting Beszel agent for localhost monitoring..."
            # Start agent with error handling
            # Set HUB_URL to localhost since hub and agent run in same container
            if DOCKER_HOST="unix:///var/run/docker.sock" HUB_URL="http://localhost:8090" PORT="${AGENT_PORT}" KEY="${AGENT_KEY}" beszel-agent 2>&1 | while IFS= read -r line; do bashio::log.info "[Agent] ${line}"; done &
            then
                AGENT_PID=$!
                bashio::log.info "Agent started with PID ${AGENT_PID}"

                # Give agent a moment to start and check if it's still running
                sleep 2
                if ! kill -0 ${AGENT_PID} 2>/dev/null; then
                    bashio::log.error "Agent failed to start - check logs above for errors"
                    bashio::log.error "Common issues:"
                    bashio::log.error "  - Invalid agent key format"
                    bashio::log.error "  - Port ${AGENT_PORT} already in use"
                    bashio::log.error "  - Missing Docker socket permissions"
                fi
            else
                bashio::log.error "Failed to launch Beszel agent"
            fi
        fi
    fi
else
    bashio::log.info "Agent disabled in configuration (monitoring hub only)"
fi

# Cleanup function to stop both processes gracefully
cleanup() {
    local exit_code=$?
    bashio::log.info "Shutting down gracefully..."

    if [ ! -z "${HUB_PID}" ] && kill -0 ${HUB_PID} 2>/dev/null; then
        bashio::log.info "Stopping Beszel hub (PID ${HUB_PID})..."
        kill -TERM ${HUB_PID} 2>/dev/null || true
        # Wait up to 10 seconds for graceful shutdown
        for i in {1..10}; do
            if ! kill -0 ${HUB_PID} 2>/dev/null; then
                break
            fi
            sleep 1
        done
        # Force kill if still running
        if kill -0 ${HUB_PID} 2>/dev/null; then
            bashio::log.warning "Hub did not stop gracefully, forcing..."
            kill -KILL ${HUB_PID} 2>/dev/null || true
        fi
    fi

    if [ ! -z "${AGENT_PID}" ] && kill -0 ${AGENT_PID} 2>/dev/null; then
        bashio::log.info "Stopping Beszel agent (PID ${AGENT_PID})..."
        kill -TERM ${AGENT_PID} 2>/dev/null || true
        # Wait up to 5 seconds for graceful shutdown
        for i in {1..5}; do
            if ! kill -0 ${AGENT_PID} 2>/dev/null; then
                break
            fi
            sleep 1
        done
        # Force kill if still running
        if kill -0 ${AGENT_PID} 2>/dev/null; then
            bashio::log.warning "Agent did not stop gracefully, forcing..."
            kill -KILL ${AGENT_PID} 2>/dev/null || true
        fi
    fi

    bashio::log.info "Shutdown complete"
    exit ${exit_code}
}

trap cleanup EXIT TERM INT

# Run Beszel hub in background
cd "${BESZEL_DATA_DIR}"
bashio::log.info "Starting Beszel hub..."

# Start hub with error handling
if beszel serve --http=0.0.0.0:8090 2>&1 | while IFS= read -r line; do bashio::log.info "[Hub] ${line}"; done &
then
    HUB_PID=$!
    bashio::log.info "Hub started with PID ${HUB_PID}"

    # Give hub a moment to start and check if it's still running
    sleep 2
    if ! kill -0 ${HUB_PID} 2>/dev/null; then
        bashio::log.error "Hub failed to start - check logs above for errors"
        bashio::log.error "Common issues:"
        bashio::log.error "  - Port 8090 already in use"
        bashio::log.error "  - Database corruption in ${BESZEL_DATA_DIR}"
        bashio::log.error "  - Insufficient disk space"
        exit 1
    fi
else
    bashio::log.error "Failed to launch Beszel hub"
    exit 1
fi

bashio::log.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bashio::log.info "✓ Beszel Server Monitor is running"
bashio::log.info "  Web Interface: http://homeassistant.local:8090"
if [ "${ENABLE_AGENT}" = "true" ] && [ -f "${AGENT_KEY_FILE}" ] && [ -s "${AGENT_KEY_FILE}" ]; then
    bashio::log.info "  Agent Port: ${AGENT_PORT} (localhost monitoring active)"
fi
bashio::log.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Wait for any process to exit
wait -n
EXIT_CODE=$?

# Determine which process exited
if [ ! -z "${HUB_PID}" ] && ! kill -0 ${HUB_PID} 2>/dev/null; then
    bashio::log.error "╔════════════════════════════════════════════════════════════════════════╗"
    bashio::log.error "║  Beszel hub process died unexpectedly (exit code: ${EXIT_CODE})                  ║"
    bashio::log.error "╚════════════════════════════════════════════════════════════════════════╝"
    bashio::log.error "Check the logs above for error messages"
    bashio::log.error "If the issue persists, check DOCS.md for troubleshooting steps"
elif [ ! -z "${AGENT_PID}" ] && ! kill -0 ${AGENT_PID} 2>/dev/null; then
    bashio::log.error "╔════════════════════════════════════════════════════════════════════════╗"
    bashio::log.error "║  Beszel agent process died unexpectedly (exit code: ${EXIT_CODE})                ║"
    bashio::log.error "╚════════════════════════════════════════════════════════════════════════╝"
    bashio::log.error "Check the logs above for error messages"
    bashio::log.error "Common causes:"
    bashio::log.error "  - Invalid agent key"
    bashio::log.error "  - Port conflict on ${AGENT_PORT}"
    bashio::log.error "  - Network connectivity issues"
else
    bashio::log.error "A process exited unexpectedly (exit code: ${EXIT_CODE})"
fi

cleanup
exit 1
