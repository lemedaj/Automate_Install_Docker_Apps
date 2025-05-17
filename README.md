# Docker Apps Automated Installation

This repository provides an automated setup for various Docker applications using docker-compose, with Traefik as the reverse proxy and automatic SSL certificate management.

## Features

- Automated installation of multiple applications
- Traefik reverse proxy with automatic SSL
- Cloudflare DNS integration
- Modular configuration
- Secure by default
- Multi-platform support (Linux/Windows)

## Applications Included

- **Odoo**: Open source ERP and CRM
- **Dolibarr**: Business/Enterprise management software
- **Portainer**: Docker management UI
- **Nginx**: Web server
- **Nginx Proxy Manager**: Visual proxy management
- **Traefik**: Modern reverse proxy
- **Cloudflare**: DNS and tunnel integration

## Prerequisites

- Docker
- Docker Compose
- Git
- Domain name with Cloudflare DNS
- Bash/PowerShell

## Directory Structure

```
.
├── deploy_docker_apps.sh       # Main deployment script
├── cloudflare/                 # Cloudflare tunnel configuration
├── dolibarr/                  # Dolibarr ERP configuration
├── nginx/                     # Nginx web server configuration
├── nginx-proxy-manager/       # NPM configuration
├── odoo/                     # Odoo ERP configuration
│   ├── custom-addons/       # Custom Odoo modules
│   ├── docker-compose-odoo.yml
│   ├── odoo_config.sh       # Odoo configuration script
│   └── odoo.conf           # Odoo server configuration
├── portainer/               # Portainer configuration
└── traefik/                # Traefik reverse proxy configuration
    └── data/              # Traefik data directory
        ├── acme.json     # SSL certificates
        ├── config.yml    # Dynamic configuration
        └── traefik.yml   # Static configuration
```

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/lemedaj/Automate_Install_Docker_Apps.git
   cd Automate_Install_Docker_Apps
   ```

2. Make the script executable:
   ```bash
   chmod +x deploy_docker_apps.sh
   ```

3. Run the deployment script:
   ```bash
   ./deploy_docker_apps.sh
   ```

4. Follow the interactive prompts to configure your services.

## Configuration

### Odoo Configuration
- Uses PostgreSQL database
- Customizable through odoo.conf
- Supports custom addons
- Automatic database backup
- Comprehensive logging options

### Traefik Configuration
- Automatic SSL certificate management
- Cloudflare DNS integration
- Dashboard access
- Security middleware

### Network Configuration
- Uses traefik_proxy network
- Secure internal communication
- External access through Traefik only

## Environment Variables

Each service has its own .env file with the following structure:

### Odoo Environment
```properties
ODOO_VERSION=latest
ODOO_PORT=8069
POSTGRES_VERSION=latest
POSTGRES_DB=postgres
POSTGRES_USER=odoo
POSTGRES_PASSWORD=secure_password
DOMAIN_NAME=your.domain.com
```

## Security

- Automatic SSL certificate management
- Secure password handling
- No default credentials
- Restricted network access
- Regular security updates

## Maintenance

### Backup
- Database backups configured for each service
- Volume backup support
- Automated backup scheduling

### Updates
- Update containers: `docker-compose pull`
- Rebuild services: `docker-compose up -d --build`
- Check logs: `docker-compose logs -f`

## Troubleshooting

Common issues and solutions:
1. Network conflicts: Check port availability
2. Permission issues: Verify file permissions
3. SSL errors: Check Cloudflare configuration
4. Database connection: Verify credentials

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue in the GitHub repository.
