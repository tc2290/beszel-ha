# Beszel Server Monitor - Documentation

Comprehensive guide for the Beszel Server Monitor Home Assistant Add-on.

## About Beszel

Beszel is a lightweight server monitoring platform that provides:

- **Docker/Podman stats** - Track CPU, memory, and network usage history per container
- **Historical data** - View system metrics over time with detailed graphs
- **Configurable alerts** - Get notified about CPU, memory, disk, bandwidth, temperature, and system status issues across 20+ platforms
- **GPU monitoring** - Support for Nvidia, AMD, and Intel GPUs
- **Multi-user support** - Each user manages their own systems, admins can share systems
- **OAuth/OIDC** - Support for multiple authentication providers
- **REST API** - Build custom integrations

This add-on runs the Beszel Hub (web interface) and optionally the Beszel Agent (for localhost monitoring).

## Configuration

The add-on supports the following configuration options:

```yaml
log_level: info
enable_agent: true
agent_port: 45876
```

### Option: `log_level`

The log level controls the verbosity of the Beszel hub logs.

**Valid values:** `trace`, `debug`, `info`, `notice`, `warning`, `error`, `fatal`

**Default:** `info`

**Example:**
```yaml
log_level: debug
```

Use `debug` or `trace` for troubleshooting issues. Use `warning` or `error` for production to reduce log verbosity.

### Option: `enable_agent`

Enable the built-in Beszel agent to monitor the Home Assistant host (localhost).

**Default:** `true`

When enabled, the agent runs alongside the hub and allows you to monitor your Home Assistant system's resources (CPU, memory, disk, network) and Docker containers.

**Why disable?** If you only want to use this add-on as a monitoring hub for remote systems (not monitoring the HA host itself), set this to `false`.

**Example:**
```yaml
enable_agent: false
```

### Option: `agent_port`

The port for the localhost monitoring agent to listen on.

**Default:** `45876`

**Example:**
```yaml
agent_port: 45876
```

This port must match the port you configure when adding the localhost system in the Beszel web interface. Only change this if you have a port conflict.

## Usage

### First Time Setup

1. Start the add-on from the Home Assistant add-ons page
2. Wait for the add-on to fully start (check the logs)
3. Open the Beszel web interface at `http://homeassistant.local:8090` or `http://[HOME_ASSISTANT_IP]:8090`
4. Create your admin account on first access
   - Choose a secure username and password
   - This account will have full administrative access

### Setting Up Localhost Monitoring

The add-on includes a built-in agent to monitor your Home Assistant host. Follow these steps to enable monitoring:

#### Step 1: Add System in Web Interface

1. In the Beszel web interface, click **"Add System"**
2. Enter the following details:
   - **Name**: `Home Assistant` (or your preferred name)
   - **Host**: `127.0.0.1` (⚠️ **Important:** Use the IP address, not "localhost")
   - **Port**: `45876` (or your configured `agent_port`)
3. Click **"Add"** or **"Generate Key"** - a public key will be displayed
4. **Copy the public key** shown in the web interface (you'll need this in the next step)

#### Step 2: Configure the Agent Key

The agent needs this public key to establish a secure connection. You have two options:

**Option A: Using Home Assistant Terminal Add-on (Recommended)**

1. Install and start the "Terminal & SSH" add-on if not already installed
2. Open the Terminal add-on
3. Run the following command (replace `YOUR_PUBLIC_KEY` with the key from Step 1):
   ```bash
   echo 'YOUR_PUBLIC_KEY' > /config/beszel_data/agent_key
   ```

**Option B: Using SSH**

1. SSH into your Home Assistant host
2. Run the following command (replace `YOUR_PUBLIC_KEY` with the key from Step 1):
   ```bash
   echo 'YOUR_PUBLIC_KEY' > /config/beszel_data/agent_key
   ```

#### Step 3: Restart the Add-on

1. Go back to the Home Assistant add-ons page
2. Click on the Beszel Server Monitor add-on
3. Click **"Restart"**
4. Monitor the logs to confirm the agent starts successfully

#### Step 4: Verify Connection

1. Return to the Beszel web interface
2. You should see the "Home Assistant" system appear in your dashboard
3. After a few moments, metrics should start appearing (CPU, memory, disk, network)

**First-time setup log messages:**

When you first start the add-on (before configuring the agent key), you'll see:
```
[INFO] Agent enabled on port 45876
[NOTICE] No agent key found - please configure localhost in web UI first
[NOTICE] After adding localhost system, save the public key to: /config/beszel_data/agent_key
```

After configuring the key and restarting:
```
[INFO] Agent enabled on port 45876
[INFO] Using existing agent key
[INFO] Starting Beszel agent for localhost monitoring...
```

### Monitoring Remote Systems

To monitor other systems beyond your Home Assistant host, install the Beszel agent on each remote system.

#### Docker Agent Installation

On each remote system you want to monitor, make sure Docker is installed, then run:

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

**Important:** Replace `your-public-key-from-hub` with the public key generated when you add the system in the Beszel web interface.

#### Binary Installation (Linux)

Download and install the agent:

```bash
curl -sL "https://github.com/henrygd/beszel/releases/latest/download/beszel-agent_linux_amd64.tar.gz" | tar -xz -O beszel-agent | tee ./beszel-agent >/dev/null && chmod +x beszel-agent
```

Run the agent:

```bash
PORT=45876 KEY='your-public-key' ./beszel-agent
```

For other architectures, replace `amd64` with `arm64` or `arm` as needed.

#### Adding Remote Systems to Dashboard

1. In the Beszel web interface, click **"Add System"**
2. Enter the system details:
   - **Name**: A friendly name for the system (e.g., "Production Server")
   - **Host**: IP address or hostname of the remote system running the agent
   - **Port**: `45876` (default, or your custom port)
3. Copy the generated public key
4. Configure the agent on the remote system with this key
5. The system will appear in your dashboard once the agent connects

## Features Deep Dive

### Docker Container Monitoring

Beszel automatically discovers and monitors Docker containers running on each monitored system:

- **Per-container metrics**: CPU usage, memory usage, network I/O
- **Container list**: View all running containers
- **Historical data**: Track container resource usage over time

**Requirements:**
- Docker socket access (automatically configured for localhost)
- For remote systems: mount `/var/run/docker.sock` in the agent container

### Alert Configuration

Set up alerts for various metrics:

1. In the web interface, go to system settings
2. Configure thresholds for:
   - CPU usage percentage
   - Memory usage percentage
   - Disk usage percentage
   - Network bandwidth
   - Temperature (if sensors available)
   - System offline status
3. Choose notification platform(s) - supports 20+ platforms including:
   - Discord
   - Slack
   - Telegram
   - Email
   - Webhooks
   - And many more

### Multi-User Management

As an admin, you can:
- Create additional user accounts
- Share systems with specific users
- Control access permissions
- Each user has their own dashboard and systems

### OAuth/OIDC Authentication

For enhanced security, configure OAuth providers:
- Google
- GitHub
- Generic OIDC providers
- And more

Refer to the [Beszel documentation](https://beszel.dev/) for OAuth setup details.

## Data Storage

All Beszel data is stored in `/config/beszel_data` within your Home Assistant configuration directory.

**What's stored:**
- SQLite database with metrics history
- User accounts and settings
- System configurations
- Agent keys
- Alert configurations

**Persistence:**
- Data persists across add-on restarts
- Data persists across add-on updates
- Data is included in Home Assistant backups (if `/config` is backed up)

**Manual backup:**
```bash
# Create a backup
tar -czf beszel-backup-$(date +%Y%m%d).tar.gz /config/beszel_data

# Restore from backup
tar -xzf beszel-backup-YYYYMMDD.tar.gz -C /
```

## Troubleshooting

### Agent Not Connecting (Localhost)

**Symptoms:** Localhost system shows as "offline" or "disconnected" in web interface

**Solutions:**

1. **Verify agent key is configured:**
   ```bash
   cat /config/beszel_data/agent_key
   ```
   Should display the public key. If empty or missing, reconfigure using Step 2 above.

2. **Check add-on logs:**
   - Look for `[INFO] Starting Beszel agent for localhost monitoring...`
   - If you see `[NOTICE] No agent key found`, the key file is missing or empty

3. **Verify port configuration:**
   - Agent port in add-on config must match the port specified when adding the system
   - Default: `45876`

4. **Restart the add-on** after configuring the agent key

5. **Check system configuration in web UI:**
   - Host must be `127.0.0.1` (not "localhost")
   - Port must match `agent_port` configuration

### Docker Stats Not Showing

**Symptoms:** Container list is empty or shows no stats

**Solutions:**

1. **Verify Docker API access:**
   - The add-on has `docker_api: true` in configuration
   - This is required for container monitoring

2. **Check Docker socket permissions:**
   Look for this in logs:
   ```
   [INFO] Docker socket found at /var/run/docker.sock
   ```

   If you see:
   ```
   [WARNING] Docker socket not found - container stats may not be available
   ```

   This indicates a Docker socket access issue. Verify Home Assistant Supervisor is properly configured.

3. **For remote systems:**
   - Ensure the agent container has Docker socket mounted: `-v /var/run/docker.sock:/var/run/docker.sock:ro`

### Web Interface Not Accessible

**Symptoms:** Cannot access `http://homeassistant.local:8090`

**Solutions:**

1. **Verify add-on is running:**
   - Check add-on status in Home Assistant
   - Review logs for startup errors

2. **Check port availability:**
   - Ensure port 8090 is not used by another service
   - Try accessing via IP address: `http://[HA_IP]:8090`

3. **Network connectivity:**
   - Try from the same network as Home Assistant
   - Check firewall rules if accessing remotely

4. **Wait for full startup:**
   - First startup may take 30-60 seconds
   - Check logs for `[INFO] Hub started with PID`

### High CPU or Memory Usage

**Symptoms:** Add-on consuming significant resources

**Solutions:**

1. **Check retention settings:**
   - In Beszel web interface, review data retention settings
   - Reduce retention period if storing too much historical data

2. **Review monitored systems:**
   - Each monitored system adds overhead
   - Consider if all systems need to be monitored

3. **Adjust polling intervals:**
   - In system settings, increase polling intervals
   - Default is typically 15-30 seconds

4. **Database maintenance:**
   - Beszel uses SQLite, which may benefit from occasional vacuuming
   - Refer to Beszel documentation for database optimization

### Permission Errors

**Symptoms:** Errors related to file permissions in logs

**Solutions:**

1. **Check `/config/beszel_data` permissions:**
   ```bash
   ls -la /config/ | grep beszel_data
   ```

2. **Fix permissions if needed:**
   ```bash
   chown -R root:root /config/beszel_data
   chmod -R 755 /config/beszel_data
   ```

### Upgrade Issues

**Symptoms:** Add-on fails to start after updating

**Solutions:**

1. **Check changelog** for breaking changes
2. **Review logs** for specific error messages
3. **Backup and reinstall** if necessary:
   ```bash
   # Backup data
   cp -r /config/beszel_data /config/beszel_data.backup

   # Uninstall and reinstall add-on
   # Then restore data if needed
   ```

## Security Considerations

### Why SYS_ADMIN Privilege?

The add-on requests `SYS_ADMIN` capability for the following reasons:

- **System metrics collection:** Reading CPU, memory, and disk statistics requires elevated privileges
- **Temperature monitoring:** Accessing hardware sensors
- **Network statistics:** Detailed network interface metrics

**Security measures:**
- Add-on runs in a containerized environment
- Only has access to `/config` directory (read-write)
- All data stored locally within Home Assistant
- No external data transmission (except to your configured alert platforms)

### Securing Your Installation

1. **Use strong passwords** for Beszel user accounts
2. **Enable OAuth/OIDC** for additional authentication security
3. **Restrict network access** to port 8090 if exposing to internet
4. **Keep the add-on updated** to receive security patches
5. **Use HTTPS** if exposing the web interface externally (via reverse proxy)

### Agent Key Security

- Agent keys are asymmetric (public/private key pair)
- Public keys are safe to store and transmit
- Private keys never leave the hub
- Each system has a unique key pair
- Regenerate keys if compromised

## Advanced Configuration

### Reverse Proxy Setup

To access Beszel securely over the internet, use a reverse proxy with HTTPS:

**Nginx example:**
```nginx
location /beszel/ {
    proxy_pass http://localhost:8090/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

**Note:** Beszel may have issues with sub-path serving. Consider using a subdomain instead.

### Custom Agent Ports

If port 45876 conflicts with another service:

1. Change `agent_port` in add-on configuration
2. Restart the add-on
3. Update the port when adding the localhost system in web interface

### Monitoring Beszel Itself

The add-on includes a watchdog health check at `http://localhost:8090/api/health`

This allows Home Assistant Supervisor to monitor the Beszel hub health and restart if necessary.

## API Access

Beszel provides a REST API for custom integrations.

**API documentation:** Refer to [Beszel API docs](https://beszel.dev/api) for endpoints and usage.

**Example - Get systems:**
```bash
curl -H "Authorization: Bearer YOUR_API_TOKEN" \
  http://localhost:8090/api/systems
```

**Generating API tokens:** Available in Beszel web interface user settings.

## Limits and Known Issues

### Resource Requirements

- **Minimum RAM:** 128 MB (hub only)
- **Recommended RAM:** 256 MB (hub + agent + multiple systems)
- **Disk space:** Varies based on retention settings, typically 100-500 MB
- **CPU:** Very light, <5% on modern systems

### Known Limitations

1. **Sub-path serving:** Beszel does not work well behind reverse proxies using sub-paths (e.g., `/beszel/`). Use subdomains instead.
2. **IPv6:** May require additional configuration for IPv6-only networks
3. **Podman:** Podman support is experimental, primarily tested with Docker

## Support and Resources

- **Beszel Official Documentation:** [beszel.dev](https://beszel.dev/)
- **Beszel GitHub Repository:** [github.com/henrygd/beszel](https://github.com/henrygd/beszel)
- **Report Beszel Issues:** [github.com/henrygd/beszel/issues](https://github.com/henrygd/beszel/issues)
- **Add-on Issues:** Report add-on-specific issues to the add-on repository
- **Home Assistant Community:** [community.home-assistant.io](https://community.home-assistant.io)

## License

Beszel is licensed under the MIT License. See the [Beszel GitHub repository](https://github.com/henrygd/beszel) for full license details.

This Home Assistant add-on is independently maintained and not officially affiliated with the Beszel project.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.
