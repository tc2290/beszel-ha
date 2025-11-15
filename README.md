# Beszel Home Assistant Add-ons

![Project Stage][project-stage-shield]

[project-stage-shield]: https://img.shields.io/badge/project%20stage-production%20ready-brightgreen.svg

Home Assistant add-ons for [Beszel](https://beszel.dev/) - a lightweight server monitoring platform.

## About

This repository contains Home Assistant add-ons for Beszel, a lightweight server monitoring platform that provides:

- **Docker/Podman stats** - Track CPU, memory, and network usage per container
- **Historical data** - View system metrics over time with detailed graphs
- **Configurable alerts** - Get notified across 20+ platforms (Discord, Slack, email, etc.)
- **GPU monitoring** - Support for Nvidia, AMD, and Intel GPUs
- **Multi-user support** - Each user manages their own systems
- **OAuth/OIDC** - Multiple authentication providers
- **REST API** - Build custom integrations

## Installation

1. Click the Home Assistant My button below to add this repository:

   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https://github.com/tc2290/beszel-ha)

2. Or manually add the repository:
   - Go to **Settings** → **Add-ons** → **Add-on Store** (bottom right)
   - Click **⋮** (top right) → **Repositories**
   - Add `https://github.com/tc2290/beszel-ha` and click **Add**

3. Find "Beszel Server Monitor" in the add-on store and click **Install**

## Add-ons Provided

### [Beszel Server Monitor](beszel/)

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armhf Architecture][armhf-shield]
![Supports armv7 Architecture][armv7-shield]

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg

Lightweight server monitoring hub with historical data, Docker stats, and alerts. This add-on runs the Beszel Hub (web interface) and optionally a local agent to monitor your Home Assistant host.

[Read the full documentation](beszel/DOCS.md)

## Support

- [Beszel Documentation](https://beszel.dev/)
- [Beszel GitHub Repository](https://github.com/henrygd/beszel)
- [Report Add-on Issues](https://github.com/tc2290/beszel-ha/issues)

## License

MIT License - See [LICENSE](LICENSE) for details.
