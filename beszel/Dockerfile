ARG BUILD_FROM
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install dependencies (beszel binaries are downloaded at runtime)
RUN apk add --no-cache \
    ca-certificates \
    curl \
    jq \
    wget

# Create data directory
RUN mkdir -p /data/beszel_data

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

# Expose web interface and agent ports
EXPOSE 8090 45876

CMD ["/run.sh"]
