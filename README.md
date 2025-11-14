# Beszel Server Monitor

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg

Lightweight server monitoring hub with historical data, Docker stats, and alerts.

## About

Beszel is a lightweight server monitoring platform that includes:

- **Docker/Podman stats** - Track CPU, memory, and network usage per container
- **Historical data** - View system metrics over time with detailed graphs
- **Configurable alerts** - Get notified across 20+ platforms (Discord, Slack, email, etc.)
- **GPU monitoring** - Support for Nvidia, AMD, and Intel GPUs
- **Multi-user support** - Each user manages their own systems
- **OAuth/OIDC** - Multiple authentication providers
- **REST API** - Build custom integrations

This add-on runs the Beszel Hub (web interface) and optionally a local agent to monitor your Home Assistant host.

## Installation

1. Click the Home Assistant My button below to add this repository:

   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https://github.com/tc2290/beszel-ha)

   Or manually add the repository:
   - Go to **Settings** → **Add-ons** → **Add-on Store** (bottom right)
   - Click **⋮** (top right) → **Repositories**
   - Add the repository URL and click **Add**

2. Find "Beszel Server Monitor" in the add-on store and click **Install**
3. Start the add-on
4. Access the web interface at `http://homeassistant.local:8090`
5. Create your admin account on first access

## Configuration

```yaml
log_level: info
enable_agent: true
agent_port: 45876
```

### Options

- **`log_level`**: Verbosity of logs (`trace`, `debug`, `info`, `notice`, `warning`, `error`, `fatal`)
- **`enable_agent`**: Enable built-in agent to monitor Home Assistant host (default: `true`)
- **`agent_port`**: Port for localhost monitoring agent (default: `45876`)

## Quick Start

### Monitor Your Home Assistant Host

1. In the Beszel web UI, click **"Add System"**
2. Configure:
   - **Name**: `Home Assistant`
   - **Host**: `127.0.0.1`
   - **Port**: `45876`
3. Copy the generated public key
4. Add the key using Terminal add-on or SSH:
   ```bash
   echo 'YOUR_PUBLIC_KEY' > /config/beszel_data/agent_key
   ```
5. Restart this add-on
6. Your Home Assistant system will appear in the dashboard

### Monitor Remote Systems

Install the agent on remote systems using Docker:

```bash
docker run -d \
  --name beszel-agent \
  --restart unless-stopped \
  --network host \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e PORT=45876 \
  -e KEY='your-public-key-from-hub' \
  henrygd/beszel-agent
```

Then add the system in the Beszel web interface with the remote host's IP address.

## Documentation

For detailed setup instructions, troubleshooting, and advanced configuration, see the [full documentation](DOCS.md).

## Features

- Lightweight resource usage
- Automatic Docker container discovery
- Historical metrics with graphs
- Customizable alerts
- Multi-user management
- OAuth/OIDC authentication
- REST API access

## Data Storage

All data is stored in `/config/beszel_data` and persists across add-on updates.

## Support

- [Beszel Documentation](https://beszel.dev/)
- [GitHub Repository](https://github.com/henrygd/beszel)
- [Report Issues](https://github.com/henrygd/beszel/issues)

## License

MIT License - See [Beszel GitHub](https://github.com/henrygd/beszel) for details.
