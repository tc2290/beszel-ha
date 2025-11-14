# Changelog

## 0.2.0

- **Added built-in localhost monitoring agent**
  - Beszel agent now installed alongside hub for monitoring Home Assistant host
  - Agent enabled by default on port 45876
  - Configurable via `enable_agent` and `agent_port` options
- **Seamless upgrade path**
  - Existing installations automatically preserve all data
  - Agent setup instructions provided in logs on first run
  - Manual agent key configuration supported via persistent storage
- **New configuration options**
  - `enable_agent`: Enable/disable localhost agent (default: true)
  - `agent_port`: Configure agent listening port (default: 45876)
- **Docker integration improvements**
  - Added Docker API access for container monitoring
  - Added SYS_ADMIN privilege for system-level monitoring
- **Process management improvements**
  - Both hub and agent now run as managed background processes
  - Improved graceful shutdown handling
  - Better error logging when processes exit unexpectedly
- Updated documentation with localhost monitoring setup (use 127.0.0.1, not "localhost")

## 0.1.2

- Removed image field to force local build from Dockerfile

## 0.1.1

- Fixed download URLs for Beszel binaries
- Corrected ARM architecture mapping

## 0.1.0

- Initial release
- Beszel v0.16.0
- Web interface on port 8090
- Multi-architecture support (amd64, aarch64, armv7, armhf, i386)
- Persistent data storage in Home Assistant config
