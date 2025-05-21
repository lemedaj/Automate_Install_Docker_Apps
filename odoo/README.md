# Odoo Service Configuration and Installation

This directory contains the configuration files and setup scripts for running Odoo with PostgreSQL and pgAdmin in Docker containers, behind Traefik reverse proxy.

## 📋 Prerequisites

- Docker and Docker Compose installed
- Traefik reverse proxy configured and running
- Docker network `proxy` created (or your custom network)

## 🗂 Directory Structure

```
odoo/
├── docker-compose-odoo.yml    # Docker Compose configuration
├── odoo_config.sh            # Configuration script
├── odoo.conf                 # Odoo server configuration
├── odoo.env                  # Environment variables
└── custom-addons/           # Directory for custom Odoo modules
```

## 🛠 Configuration

The service can be configured using the interactive configuration script:

```bash
./odoo_config.sh
```

### Configuration Options

#### Network Configuration
- **Network Name**: Docker network for the containers (default: proxy)
- **Domain Name**: Domain for accessing Odoo and pgAdmin (default: localhost)

#### Odoo Configuration
- Version: 16.0
- Port: 8069
- Database Host: db

#### PostgreSQL Configuration
- Version: 15
- Database: postgres
- Default User: odoo
- Default Password: odoo

#### pgAdmin Configuration
- Email: admin@[your-domain]
- Default Password: admin

## 🚀 Installation

1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd odoo
   ```

2. Make the configuration script executable:
   ```bash
   chmod +x odoo_config.sh
   ```

3. Run the configuration script:
   ```bash
   ./odoo_config.sh
   ```

4. Follow the interactive prompts to configure your installation.

## 🔧 Manual Installation

If you prefer to set up manually:

1. Create required Docker volumes:
   ```bash
   docker volume create odoo_data
   docker volume create postgres_data
   docker volume create pgadmin_data
   ```

2. Ensure the Docker network exists:
   ```bash
   docker network create proxy   # or your custom network name
   ```

3. Configure environment variables in `odoo.env`

4. Start the services:
   ```bash
   docker compose -f docker-compose-odoo.yml up -d
   ```

## 📊 Services

### Odoo
- **URL**: https://odoo.[your-domain]
- **Port**: 8069
- **Database Management**: https://odoo.[your-domain]/web/database/manager

### PostgreSQL
- **Host**: db
- **Port**: 5432
- **Database**: postgres

### pgAdmin
- **URL**: https://pgadmin.[your-domain]
- Access with configured email and password

## 🔒 Security Notes

1. Change default passwords in production
2. Secure database management interface
3. Use strong passwords for all services
4. Keep backups of your data
5. Regularly update containers

## 📝 Configuration Files

### docker-compose-odoo.yml
- Defines services: Odoo, PostgreSQL, and pgAdmin
- Sets up volumes and networks
- Configures Traefik labels

### odoo.conf
- Odoo server configuration
- Database settings
- Performance tuning
- Security parameters

### odoo.env
- Environment variables
- Service configurations
- Network settings
- Credentials

## 🛟 Troubleshooting

1. Check container status:
   ```bash
   docker ps
   ```

2. View container logs:
   ```bash
   docker logs odoo
   docker logs postgres
   docker logs pgadmin
   ```

3. Common issues:
   - Network connectivity: Ensure network exists and containers are connected
   - Permission issues: Check volume permissions
   - Database connection: Verify PostgreSQL credentials and connectivity

## 🔄 Maintenance

### Backup

1. Database backup:
   ```bash
   docker exec postgres pg_dump -U odoo postgres > backup.sql
   ```

### Updates

1. Pull new images:
   ```bash
   docker compose -f docker-compose-odoo.yml pull
   ```

2. Restart services:
   ```bash
   docker compose -f docker-compose-odoo.yml up -d
   ```

## 📚 Additional Resources

- [Odoo Documentation](https://www.odoo.com/documentation/16.0/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)
