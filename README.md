# Docker Apps Automated Installation

This repository provides an automated setup for various Docker applications using docker-compose, with Traefik as the reverse proxy and automatic SSL certificate management.

## Features

- Automated installation of multiple applications
- Traefik reverse proxy with automatic SSL
- Cloudflare DNS integration
- Configurable shared network infrastructure
- Modular configuration
- Secure by default
- Multi-platform support (Linux/Windows)
- Visual installation progress with Nord icons
- Dracula theme colors for better readability
- Background process visibility
- Phase transitions with progress indicators
- Improved error handling and logging

## Visual Improvements

- **Progress Tracking**: Visual spinners show real-time progress
- **Color Coding**: Uses Dracula theme colors for better visibility
- **Nord Icons**: Beautiful icons for status indicators
- **Phase Transitions**: Clear separation between installation phases
- **Error Visualization**: Enhanced error reporting with color coding
- **Status Updates**: Real-time feedback on background processes

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
- fontconfig (automatically installed if missing)
- Nord fonts (automatically installed if missing)

## Directory Structure

```
.
├── deploy_docker_apps.sh        # Main deployment script
├── cloudflare/                  # Cloudflare tunnel configuration
│   ├── cloudflare.env          # Cloudflare environment variables
│   └── docker-compose-cloudflare.yml
├── dolibarr/                   # Dolibarr ERP configuration
│   ├── dolibarr.env           # Dolibarr environment variables
│   └── docker-compose-dolibarr.yml
├── nginx/                      # Nginx web server configuration
│   ├── nginx.env              # Nginx environment variables
│   └── docker-compose-nginx.yml
├── nginx-proxy-manager/        # NPM configuration
│   ├── nginx-proxy.env        # NPM environment variables
│   └── docker-compose-nginx-proxy.yml
├── odoo/                      # Odoo ERP configuration
│   ├── custom-addons/        # Custom Odoo modules
│   ├── odoo.env             # Odoo environment variables
│   ├── docker-compose-odoo.yml
│   ├── odoo_config.sh        # Odoo configuration script
│   └── odoo.conf            # Odoo server configuration
├── portainer/                # Portainer configuration
│   ├── portainer.env        # Portainer environment variables
│   └── docker-compose-portainer.yml
└── traefik/                 # Traefik reverse proxy configuration
    ├── traefik.env         # Traefik environment variables
    ├── docker-compose-traefik.yml
    └── data/               # Traefik data directory
        ├── acme.json      # SSL certificates
        ├── config.yml     # Dynamic configuration
        └── traefik.yml    # Static configuration
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

4. The script will:
   - Check and install required fonts and dependencies
   - Detect your Linux distribution
   - Install Docker and Docker Compose if needed
   - Guide you through service selection with visual feedback
   - Show real-time progress for each installation phase
   - Provide clear status updates and error messages

5. Environment Files:
   - Each service has its own environment file (e.g., `traefik.env`, `odoo.env`)
   - Files are created with default values during installation
   - Review and modify the environment files as needed
   - Configuration is automatically loaded by respective services

## Installation Phases

1. **Environment Setup**
   - Font installation check
   - System requirements verification
   - Linux distribution detection

2. **Docker Environment**
   - Docker installation/verification
   - Docker Compose setup
   - Network configuration

3. **Application Installation**
   - Interactive service selection
   - Dependency resolution
   - Configuration generation
   - Container deployment

4. **Completion**
   - Service verification
   - URL display
   - Log file generation

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

- Configurable shared Docker network (default: proxy)
- Consistent network naming across all services
- Secure internal communication
- External access through Traefik only

## Environment Variables

Each service has its own service-specific environment file:

- `traefik/traefik.env`: Traefik configuration variables
- `odoo/odoo.env`: Odoo and PostgreSQL settings
- `dolibarr/dolibarr.env`: Dolibarr and MariaDB configuration
- `nginx/nginx.env`: Nginx server settings
- `portainer/portainer.env`: Portainer configuration
- `nginx-proxy-manager/nginx-proxy.env`: NPM settings
- `cloudflare/cloudflare.env`: Cloudflare credentials and tunnel configuration

Example structure for key environment files:

### Environment Variables Structure

Each service has its own `.env` file that includes service-specific settings and shared configuration.

#### Shared Configuration

```properties
NETWORK_NAME=proxy              # Shared Docker network name
DOMAIN_NAME=your.domain.com     # Base domain for all services
```

#### Service-Specific Configuration (Example: Odoo)

```properties
ODOO_VERSION=latest
ODOO_PORT=8069
POSTGRES_VERSION=latest
POSTGRES_DB=postgres
POSTGRES_USER=odoo
POSTGRES_PASSWORD=secure_password
```

## Security

- Automatic SSL certificate management
- Secure password handling
- No default credentials
- Restricted network access
- Regular security updates

## Security Features

### Traefik Security Configuration
- Automatic HTTPS redirection
- SSL/TLS certificate management via Cloudflare
- Strict security headers implementation
- HTTP/3 support (optional)
- Rate limiting
- IP filtering capabilities

### Application Security
- Secure headers middleware for all services
- CORS policy enforcement
- XSS protection
- Content Security Policy
- Strict Transport Security (HSTS)
- Frame options control
- Content type verification
- Referrer policy enforcement
- Permissions policy control

### Database Security
- Automated PostgreSQL health checks
- Secure credential management
- Volume isolation
- Network segmentation

### Network Security
- Isolated Docker network
- Internal service discovery
- External access control
- Cloudflare tunnel integration

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
