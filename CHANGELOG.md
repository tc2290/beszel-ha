# Changelog

## 0.3.0 (2024-11-14)

### Changed
- **Migrated from JSON to YAML configuration**
  - Converted `config.json` to `config.yaml` for better alignment with HA standards
  - Configuration syntax remains the same for users
- **Enhanced documentation**
  - Added comprehensive `DOCS.md` with detailed setup and troubleshooting
  - Simplified `README.md` for cleaner add-on store presentation
  - Added architecture badges to README
- **Improved agent key setup UX**
  - Added prominent setup instructions in logs when agent key is missing
  - Included step-by-step configuration guide on first startup
  - Better visual formatting of setup instructions
- **Enhanced error handling**
  - Detailed error messages identifying which process failed (hub vs agent)
  - Added common troubleshooting tips in error messages
  - Graceful shutdown with timeout handling
  - Prefixed log messages with `[Hub]` and `[Agent]` for clarity
- **Better process management**
  - Improved graceful shutdown with proper timeout handling (10s for hub, 5s for agent)
  - Force-kill fallback if graceful shutdown times out
  - Startup validation to detect early failures
  - Clear status messages when processes start successfully

### Added
- **Watchdog health monitoring**
  - Added `watchdog: http://localhost:8090/api/health` to config
  - Enables Home Assistant Supervisor to monitor and restart if needed
- **Agent key validation**
  - Basic validation to detect invalid keys (minimum length check)
  - Warning messages if agent key appears malformed

### Removed
- **Dropped i386 architecture support**
  - i386 was incorrectly mapped to amd64 binaries
  - Removed from config.yaml, build.json, and Dockerfile
  - Supported architectures: aarch64, amd64, armhf, armv7

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
