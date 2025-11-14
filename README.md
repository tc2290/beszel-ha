# Beszel Server Monitor - Home Assistant Add-on

Lightweight server monitoring hub with historical data, Docker stats, and alerts.

## About

Beszel is a lightweight server monitoring platform that provides:

- **Docker/Podman stats** - Track CPU, memory, and network usage history per container
- **Historical data** - View system metrics over time with detailed graphs
- **Configurable alerts** - Get notified about CPU, memory, disk, bandwidth, temperature, and system status issues
- **Multi-user support** - Each user manages their own systems
- **REST API** - Build custom integrations

This add-on runs the Beszel Hub, which provides the web interface for viewing and managing your monitored systems.

## Installation

1. Add this repository to your Home Assistant instance
2. Install the "Beszel Server Monitor" add-on
3. Start the add-on
4. Access the web interface at `http://homeassistant.local:8090`
5. Create your admin account on first access

## Configuration

```yaml
log_level: info
enable_agent: true
agent_port: 45876
```

### Option: `log_level`

The log level for the Beszel hub.

Valid values: `trace`, `debug`, `info`, `notice`, `warning`, `error`, `fatal`

### Option: `enable_agent`

Enable the built-in Beszel agent to monitor the Home Assistant host (localhost).

Default: `true`

When enabled, the agent will run alongside the hub and allow you to monitor your Home Assistant system's resources (CPU, memory, disk, network) and Docker containers.

### Option: `agent_port`

The port for the localhost monitoring agent to listen on.

Default: `45876`

This should match the port you configure when adding the localhost system in the Beszel web interface.

## Usage

### First Time Setup

1. Open the Beszel web interface at `http://homeassistant.local:8090`
2. Create your admin account
3. Go to Settings > Tokens to generate a universal token for connecting agents

### Setting Up Localhost Monitoring

The add-on includes a built-in agent to monitor your Home Assistant host. To enable it:

1. In the Beszel web interface, click "Add System"
2. Enter the following details:
   - **Name**: `Home Assistant` (or your preferred name)
   - **Host**: `127.0.0.1` (use IP address, not "localhost")
   - **Port**: `45876` (or your configured `agent_port`)
3. Copy the public key shown in the web interface
4. Save the public key to the agent configuration:
   - SSH into your Home Assistant host or use the Terminal add-on
   - Run: `echo 'YOUR_PUBLIC_KEY' > /config/beszel_data/agent_key`
   - Replace `YOUR_PUBLIC_KEY` with the actual key from step 3
5. Restart the Beszel add-on from the Home Assistant add-ons page
6. The localhost system will connect automatically and appear in your dashboard

**Note**: After the first setup, the agent will start automatically on subsequent restarts.

### Monitoring Additional Systems

To monitor other systems beyond your Home Assistant host, install the Beszel agent on each system.

#### Docker Agent Installation

On each remote system you want to monitor, run:

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

Replace `your-public-key-from-hub` with the key from your Beszel hub settings.

#### Binary Installation (Linux)

Download and install the agent:

```bash
curl -sL "https://github.com/henrygd/beszel/releases/latest/download/beszel-agent_linux_amd64.tar.gz" | tar -xz -O beszel-agent | tee ./beszel-agent >/dev/null && chmod +x beszel-agent
```

Run the agent:

```bash
PORT=45876 KEY='your-public-key' ./beszel-agent
```

### Adding Remote Systems to Monitor

1. In the Beszel web interface, click "Add System"
2. Enter the system details:
   - **Name**: A friendly name for the system
   - **Host**: IP address or hostname of the remote system running the agent
   - **Port**: `45876` (default)
3. The system will appear in your dashboard once connected

## Features

- **Lightweight** - Uses minimal resources compared to other monitoring solutions
- **Docker Integration** - Automatically discovers and monitors Docker containers
- **Historical Data** - View system metrics over time
- **Alerts** - Configure notifications for various metrics across 20+ platforms
- **GPU Monitoring** - Support for Nvidia, AMD, and Intel GPUs
- **Multi-user** - Each user has their own systems, admins can share systems
- **OAuth/OIDC** - Support for multiple authentication providers

## Data Storage

All Beszel data is stored in `/config/beszel_data` within your Home Assistant configuration directory. This ensures your monitoring data persists across add-on updates.

## Support

- [Beszel Documentation](https://beszel.dev/)
- [GitHub Repository](https://github.com/henrygd/beszel)
- [Report Issues](https://github.com/henrygd/beszel/issues)

## License

MIT License - See [Beszel GitHub](https://github.com/henrygd/beszel) for details.
