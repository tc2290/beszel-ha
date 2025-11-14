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

# Handle agent key migration/setup
AGENT_KEY_FILE="${BESZEL_DATA_DIR}/agent_key"
AGENT_SETUP_FLAG="${BESZEL_DATA_DIR}/.agent_auto_configured"

# Start the agent if enabled
if [ "${ENABLE_AGENT}" = "true" ]; then
    bashio::log.info "Agent enabled on port ${AGENT_PORT}"

    # Check if we need to generate a new agent key
    if [ ! -f "${AGENT_KEY_FILE}" ]; then
        bashio::log.notice "First-time agent setup detected"
        bashio::log.notice "Agent key will be auto-generated on first hub startup"
        bashio::log.notice "After hub starts, add localhost system in web UI with port ${AGENT_PORT}"

        # Mark for auto-configuration after hub is ready
        touch "${AGENT_SETUP_FLAG}"
    else
        bashio::log.info "Using existing agent key from ${AGENT_KEY_FILE}"
    fi

    # Start agent in background
    if [ -f "${AGENT_KEY_FILE}" ]; then
        AGENT_KEY=$(cat "${AGENT_KEY_FILE}")

        # Check Docker socket availability
        if [ -S /var/run/docker.sock ]; then
            bashio::log.info "Docker socket found at /var/run/docker.sock"
            ls -la /var/run/docker.sock
        else
            bashio::log.warning "Docker socket not found - container stats may not be available"
        fi

        bashio::log.info "Starting Beszel agent for localhost monitoring..."
        # Ensure Docker socket is accessible to the agent
        DOCKER_HOST="unix:///var/run/docker.sock" PORT="${AGENT_PORT}" KEY="${AGENT_KEY}" beszel-agent &
        AGENT_PID=$!
        bashio::log.info "Agent started with PID ${AGENT_PID}"
    else
        bashio::log.warning "Agent key not yet available - start agent manually after setting up localhost in web UI"
        bashio::log.warning "To start agent: echo 'YOUR_PUBLIC_KEY' > ${AGENT_KEY_FILE} && supervisorctl restart addon_local_beszel"
    fi
fi

# Cleanup function to stop both processes gracefully
cleanup() {
    bashio::log.info "Shutting down..."
    if [ ! -z "${HUB_PID}" ] && kill -0 ${HUB_PID} 2>/dev/null; then
        bashio::log.info "Stopping hub..."
        kill -TERM ${HUB_PID} 2>/dev/null || true
    fi
    if [ ! -z "${AGENT_PID}" ] && kill -0 ${AGENT_PID} 2>/dev/null; then
        bashio::log.info "Stopping agent..."
        kill -TERM ${AGENT_PID} 2>/dev/null || true
    fi
    wait 2>/dev/null || true
}

trap cleanup EXIT TERM INT

# Run Beszel hub in background
cd "${BESZEL_DATA_DIR}"
bashio::log.info "Starting Beszel hub..."
beszel serve --http=0.0.0.0:8090 &
HUB_PID=$!
bashio::log.info "Hub started with PID ${HUB_PID}"

# Wait for any process to exit
wait -n

# If we get here, one process died, so trigger cleanup
bashio::log.error "A process exited unexpectedly"
cleanup
exit 1
