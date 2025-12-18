ARG BUILD_FROM
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Beszel hub and dependencies for version checking
RUN apk add --no-cache \
    ca-certificates \
    curl \
    jq

# Download and install Beszel hub and agent
ARG BUILD_ARCH
RUN \
    case "${BUILD_ARCH}" in \
        amd64) ARCH="amd64" ;; \
        aarch64) ARCH="arm64" ;; \
        armhf|armv7) ARCH="arm" ;; \
    esac \
    && wget -q -O /tmp/beszel.tar.gz \
        "https://github.com/henrygd/beszel/releases/latest/download/beszel_linux_${ARCH}.tar.gz" \
    && tar -xzf /tmp/beszel.tar.gz -C /usr/local/bin/ \
    && chmod +x /usr/local/bin/beszel \
    && rm -f /tmp/beszel.tar.gz \
    && wget -q -O /tmp/beszel-agent.tar.gz \
        "https://github.com/henrygd/beszel/releases/latest/download/beszel-agent_linux_${ARCH}.tar.gz" \
    && tar -xzf /tmp/beszel-agent.tar.gz -C /usr/local/bin/ \
    && chmod +x /usr/local/bin/beszel-agent \
    && rm -f /tmp/beszel-agent.tar.gz

# Create data directory
RUN mkdir -p /data/beszel_data

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

# Expose web interface and agent ports
EXPOSE 8090 45876

CMD ["/run.sh"]
