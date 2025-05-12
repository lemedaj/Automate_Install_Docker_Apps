# Docker Applications Deployment Script

This script automates the deployment of multiple Docker applications behind a Traefik reverse proxy with automatic HTTPS using Cloudflare DNS. The script provides a modular and secure way to deploy various self-hosted applications with proper domain routing and SSL certificates.

## Overview

- 🔒 **Secure by Default**: HTTPS, authentication, and secure headers
- 🚀 **Easy Deployment**: One-click setup for multiple applications
- 🔄 **Auto Configuration**: Automatic service discovery and routing
- 🌐 **Cross-Platform**: Works on both Linux and Windows
- 🛡️ **Cloudflare Integration**: DNS and SSL automation

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
- Operating System:
  - Linux-based system (Ubuntu, Debian, CentOS, RHEL, Fedora, Arch), or
  - Windows with Git Bash installed
- Docker and Docker Compose
- Root/Administrator privileges

## Quick Start

### On Linux:

1. Clone the repository
2. Make the script executable: `chmod +x deploy_docker_apps.sh`
3. Run the deployment script: `./deploy_docker_apps.sh`

### On Windows:

1. Clone the repository
2. Install Git for Windows if not already installed
3. Run PowerShell as Administrator
4. Run the deployment script: `.\deploy_docker_apps.ps1`

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

The setup process will guide you through configuring:

1. **Domain Settings**:
   - Domain name
   - Cloudflare email
   - Cloudflare API key

2. **Traefik Dashboard**:
   - Custom port (default: 8080)
   - Username and password
   - SSL certificate automation

3. **Service-Specific Settings**:
   - Database credentials
   - Application ports
   - Custom configurations

## Maintenance

The script includes functions for:

- Updating existing installations
- Adding new services
- Managing Docker networks
- Environment variable management
- Service status monitoring

## Directory Structure

```
├── deploy_docker_apps.sh     # Main deployment script
├── deploy_docker_apps.ps1    # PowerShell wrapper for Windows
├── cloudflare/               # Cloudflare tunnel configuration
│   └── docker-compose-cloudflare.yml
├── dolibarr/                # Dolibarr ERP/CRM
│   └── docker-compose-dolibarr.yml
├── nginx/                   # Nginx web server
│   └── docker-compose-nginx.yml
├── nginx-proxy-manager/     # Nginx Proxy Manager
│   └── docker-compose-nginx-proxy.yml
├── odoo/                    # Odoo business suite
│   ├── docker-compose-odoo.yml
│   ├── custom-addons/      # Custom Odoo modules
│   └── odoo.conf           # Odoo configuration
├── portainer/              # Container management
│   └── docker-compose-portainer.yml
└── traefik/               # Reverse proxy configuration
    ├── docker-compose.yml
    ├── .env               # Traefik environment configuration
    └── data/
        ├── traefik.yml    # Main Traefik configuration
        ├── config.yml     # Dynamic configuration
        └── acme.json      # SSL certificates storage
```

## Configuration Files

- **traefik.yml**: Main Traefik configuration (entrypoints, providers, etc.)
- **config.yml**: Dynamic configuration (middlewares, TLS options)
- **.env**: Environment variables for each service
- **docker-compose.yml**: Service definitions and configurations
