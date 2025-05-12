# Docker Applications Deployment Script

This script automates the deployment of multiple Docker applications behind a Traefik reverse proxy with automatic HTTPS using Cloudflare DNS. The script provides a modular and secure way to deploy various self-hosted applications with proper domain routing and SSL certificates.

## Features

- **Automatic Service Discovery**: Uses Traefik v2 for automatic service discovery and routing
- **SSL/TLS Automation**: Automated HTTPS certificates via Cloudflare DNS challenge
- **Subdomain Routing**: Each service is accessible via its own subdomain
- **Multi-Platform Support**: Works on various Linux distributions (Ubuntu, Debian, CentOS, RHEL, Fedora, Arch)
- **Docker & Docker Compose**: Automatic installation and configuration
- **Service Integration**: Multiple pre-configured applications:
  - Traefik (Reverse Proxy)
  - Nginx (Web Server)
  - Portainer (Container Management)
  - Nginx Proxy Manager (Web Proxy)
  - Odoo (Business Management)
  - Dolibarr (ERP/CRM)
  - Cloudflare Tunnel (Secure Access)

## Security Features

- Automatic HTTPS redirection
- Secure headers configuration
- Network isolation using Docker networks
- Basic authentication for admin interfaces
- No exposed ports except 80 and 443
- Cloudflare DNS integration for added security

## Prerequisites

- A domain name managed by Cloudflare
- Cloudflare API credentials
- Linux-based operating system
- Root or sudo privileges

## Quick Start

1. Clone the repository
2. Run the deployment script: ./deploy_docker_apps.sh
3. Enter your domain name and Cloudflare credentials when prompted
4. Select which applications to install

## Network Architecture

```
Internet -> Cloudflare -> Traefik -> Services
                              ├─ nginx.domain.com
                              ├─ portainer.domain.com
                              ├─ npm.domain.com
                              ├─ odoo.domain.com
                              ├─ dolibarr.domain.com
                              └─ traefik.domain.com
```

## Environment Configuration

Each service has its own environment configuration file (.env) for easy customization:

- Database credentials
- Application settings
- Domain configuration
- API keys and tokens

## Maintenance

The script includes functions for:

- Updating existing installations
- Adding new services
- Managing Docker networks
- Environment variable management
- Service status monitoring

## Directory Structure

```
├── deploy_docker_apps.sh    # Main deployment script
├── cloudflare/              # Cloudflare tunnel configuration
├── dolibarr/               # Dolibarr ERP/CRM
├── nginx/                  # Nginx web server
├── nginx-proxy-manager/    # Nginx Proxy Manager
├── odoo/                   # Odoo business suite
│   ├── custom-addons/     # Custom Odoo modules
│   └── odoo.conf          # Odoo configuration
├── portainer/             # Container management
└── traefik/              # Reverse proxy configuration
    └── data/             # Traefik static configuration
```
