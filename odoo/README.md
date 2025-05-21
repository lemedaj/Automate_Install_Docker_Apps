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

## ⚙️ Environment Variables

### Network Configuration
```properties
NETWORK_NAME=proxy            # Docker network name (e.g., proxy, web)
DOMAIN_NAME=localhost         # Domain for services (e.g., example.com)
```

### Odoo Configuration
```properties
ODOO_VERSION=18.0            # Odoo version to use (e.g., 16.0, 17.0, 18.0)
ODOO_PORT=8069               # Web interface port (e.g., 8069, 8080)
ODOO_DB_HOST=db              # Database host name (e.g., db, postgres)
ODOO_MASTER_PASSWORD=odoo    # Master password for database management
```

### PostgreSQL Configuration
```properties
POSTGRES_VERSION=17          # PostgreSQL version (e.g., 15, 16, 17)
POSTGRES_DB=postgres         # Default database name (e.g., odoo_db)
POSTGRES_USER=odoo           # Database user (e.g., odoo, admin)
POSTGRES_PASSWORD=odoo       # Database password (e.g., odoo123)
```

### pgAdmin Configuration
```properties
PGADMIN_EMAIL=admin@example.com    # Admin email (e.g., admin@example.com)
PGADMIN_PASSWORD=admin             # Admin password (e.g., admin123)
```

### Traefik Configuration
```properties
TRAEFIK_ROUTER=odoo               # Router name (e.g., odoo, myapp)
TRAEFIK_ENTRYPOINT=websecure      # HTTPS entrypoint (e.g., websecure)
TRAEFIK_CERT_RESOLVER=cloudflare  # Certificate resolver (e.g., cloudflare)
```

## 🛠 Configuration

The service can be configured using the interactive configuration script:

```bash
./odoo_config.sh
```

The script will:
1. Prompt for necessary configuration values
2. Generate odoo.env file with your settings
3. Update odoo.conf with database configuration
4. Configure docker-compose-odoo.yml with your settings
5. Create required Docker resources
6. Start the containers (optional)

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
   docker compose -f docker-compose-odoo.yml --env-file odoo.env up -d
   ```

## 📊 Services

### Odoo
- **URL**: https://odoo.[your-domain]
- **Port**: 8069 (configurable)
- **Database Management**: https://odoo.[your-domain]/web/database/manager

### PostgreSQL
- **Host**: db
- **Port**: 5432
- **Database**: postgres (configurable)

### pgAdmin
- **URL**: https://pgadmin.[your-domain]
- **Default Email**: admin@[your-domain]
- **Default Password**: admin (configurable)

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
