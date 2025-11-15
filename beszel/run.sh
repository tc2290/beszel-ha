#!/usr/bin/with-contenv bashio

# Get configuration options
LOG_LEVEL=$(bashio::config 'log_level')
ENABLE_AGENT=$(bashio::config 'enable_agent')
AGENT_PORT=$(bashio::config 'agent_port')

bashio::log.info "Starting Beszel Server Monitor..."
bashio::log.info "Log level: ${LOG_LEVEL}"

# Set data directory to persistent storage
export BESZEL_DATA_DIR="/config/beszel_data"

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
            if DOCKER_HOST="unix:///var/run/docker.sock" PORT="${AGENT_PORT}" KEY="${AGENT_KEY}" beszel-agent 2>&1 | while IFS= read -r line; do bashio::log.info "[Agent] ${line}"; done &
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
