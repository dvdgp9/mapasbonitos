# Guía de Deployment - HestiaCP

Esta guía cubre la instalación de **Mapas Bonitos** en un servidor Hetzner con HestiaCP.

## Requisitos del Servidor

- **OS**: Ubuntu 20.04+ / Debian 11+
- **PHP**: 8.0+
- **MySQL**: 5.7+ o MariaDB 10.3+
- **Python**: 3.9+
- **RAM**: Mínimo 2GB (recomendado 4GB para generación de mapas grandes)
- **Disco**: 10GB+ libre para mapas generados

## Paso 1: Preparar el Dominio en HestiaCP

1. Accede al panel HestiaCP
2. Ve a **WEB** → **Add Web Domain**
3. Configura:
   - **Domain**: `mapas.iaiapro.com`
   - **IP Address**: Selecciona tu IP
   - **Proxy Support**: Activado
   - **SSL Support**: Activado (Let's Encrypt)
4. Guarda y espera a que se configure el SSL

## Paso 2: Clonar el Repositorio

```bash
# Conectar al servidor via SSH
ssh usuario@servidor

# Ir al directorio web (ajustar según tu configuración HestiaCP)
cd /home/admin/web/mapas.iaiapro.com/public_html

# Clonar el repositorio (o subir via SFTP)
git clone https://github.com/tu-usuario/mapasbonitos.git .

# O si ya tienes los archivos, asegúrate de que estén en el directorio correcto
```

## Paso 3: Crear Base de Datos MySQL

### Opción A: Via HestiaCP Panel

1. Ve a **DB** → **Add Database**
2. Configura:
   - **Database**: `dvdgp_mapas`
   - **User**: `dvdgp_mapas_usr`
   - **Password**: `mapasusrPASS2!`
3. Guarda

### Opción B: Via CLI

```bash
mysql -u root -p

CREATE DATABASE dvdgp_mapas CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'dvdgp_mapas_usr'@'localhost' IDENTIFIED BY 'mapasusrPASS2!';
GRANT ALL PRIVILEGES ON dvdgp_mapas.* TO 'dvdgp_mapas_usr'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

## Paso 4: Ejecutar Schema SQL

```bash
cd /home/admin/web/mapas.iaiapro.com/public_html

# Crear tablas
mysql -u dvdgp_mapas_usr -p dvdgp_mapas < deploy/schema.sql

# Poblar temas
mysql -u dvdgp_mapas_usr -p dvdgp_mapas < deploy/seed_themes.sql
```

## Paso 5: Configurar Variables de Entorno

```bash
# Copiar archivo de ejemplo
cp .env.example private/.env

# Editar configuración
nano private/.env
```

Asegúrate de que contenga:

```env
DB_HOST=localhost
DB_NAME=dvdgp_mapas
DB_USER=dvdgp_mapas_usr
DB_PASS=mapasusrPASS2!
DB_CHARSET=utf8mb4

APP_URL=https://mapas.iaiapro.com
APP_ENV=production
APP_DEBUG=false
```

## Paso 6: Configurar Permisos

```bash
# Crear directorio de storage si no existe
mkdir -p storage/renders

# Establecer permisos
chown -R admin:admin .
chmod -R 755 .
chmod -R 775 storage
chmod 600 private/.env
```

## Paso 7: Configurar Virtual Host en HestiaCP

HestiaCP debería haber creado la configuración automáticamente. Si necesitas ajustes:

1. Ve a **WEB** → Selecciona el dominio → **Edit**
2. En **Advanced options**, añade la configuración de Nginx/Apache si es necesario

### Para Nginx (Custom template)

Si necesitas un template personalizado:

```nginx
location /api {
    try_files $uri $uri/ /api/index.php?$query_string;
}

location / {
    root /home/admin/web/mapas.iaiapro.com/public_html/public;
    index index.html;
    try_files $uri $uri/ /index.html;
}
```

### Alternativa: Symlink para DocumentRoot

```bash
# Si el DocumentRoot de HestiaCP apunta a public_html
# Puedes crear un symlink o mover los archivos

# Opción 1: Mover public/* al root
mv public/* .
mv api api_backup  # si hay conflicto

# Opción 2: Cambiar DocumentRoot en HestiaCP a public_html/public
# Esto se hace editando el template del dominio
```

## Paso 8: Instalar Worker Python

```bash
# Ejecutar script de instalación como root
sudo bash deploy/install_worker.sh /home/admin/web/mapas.iaiapro.com/public_html
```

### Instalación Manual (alternativa)

```bash
# 1. Crear virtual environment
python3 -m venv venv

# 2. Instalar dependencias
venv/bin/pip install -r maptoposter-main/requirements.txt

# 3. Copiar service file
sudo cp deploy/mapasbonitos-worker.service /etc/systemd/system/

# 4. Editar paths en el service file
sudo nano /etc/systemd/system/mapasbonitos-worker.service
# Ajustar WorkingDirectory y ExecStart al path correcto

# 5. Habilitar y arrancar servicio
sudo systemctl daemon-reload
sudo systemctl enable mapasbonitos-worker
sudo systemctl start mapasbonitos-worker

# 6. Verificar status
sudo systemctl status mapasbonitos-worker
```

## Paso 9: Verificar Instalación

### Test de Base de Datos

```bash
# Desde el directorio del proyecto
venv/bin/python maptoposter-main/worker.py --test-db
```

Debería mostrar:
```
✓ Database connection successful!
  Jobs in database: 0
  Active themes: 17
```

### Test de API

```bash
# Listar temas
curl https://mapas.iaiapro.com/api/themes.php

# Crear un job de prueba
curl -X POST https://mapas.iaiapro.com/api/jobs.php \
  -H "Content-Type: application/json" \
  -d '{"location":"Madrid, España","theme":"noir","distance":8000}'
```

### Verificar Worker

```bash
# Ver logs del worker
sudo journalctl -u mapasbonitos-worker -f

# Debería empezar a procesar el job de prueba
```

## Paso 10: Configurar Cron para Limpieza (Opcional)

```bash
# Editar crontab
crontab -e

# Añadir limpieza de rate limits y cache expirado (cada día a las 3am)
0 3 * * * mysql -u dvdgp_mapas_usr -pmapasusrPASS2! dvdgp_mapas -e "DELETE FROM rate_limits WHERE created_at < DATE_SUB(NOW(), INTERVAL 2 HOUR); DELETE FROM geocode_cache WHERE expires_at < NOW();"
```

## Troubleshooting

### El worker no arranca

```bash
# Ver logs detallados
sudo journalctl -u mapasbonitos-worker -n 50

# Verificar permisos
ls -la /home/admin/web/mapas.iaiapro.com/public_html/storage/renders/

# Probar manualmente
cd /home/admin/web/mapas.iaiapro.com/public_html/maptoposter-main
../venv/bin/python worker.py
```

### Error de conexión a base de datos

```bash
# Verificar que MySQL está corriendo
sudo systemctl status mysql

# Probar conexión manual
mysql -u dvdgp_mapas_usr -p dvdgp_mapas

# Verificar archivo .env
cat private/.env
```

### Los mapas no se generan

1. Verificar que el worker está corriendo: `systemctl status mapasbonitos-worker`
2. Revisar logs: `journalctl -u mapasbonitos-worker -f`
3. Verificar permisos de storage: `ls -la storage/renders/`
4. Probar generación manual:
   ```bash
   cd maptoposter-main
   ../venv/bin/python create_map_poster.py -c "Madrid" -C "España" -t noir -d 8000
   ```

### Errores de PHP

```bash
# Ver logs de PHP
tail -f /var/log/apache2/error.log  # Apache
tail -f /var/log/nginx/error.log    # Nginx

# Verificar versión de PHP
php -v
```

## Comandos Útiles

```bash
# Gestión del worker
./deploy/worker.sh status
./deploy/worker.sh restart
./deploy/worker.sh logs

# Ver jobs en cola
mysql -u dvdgp_mapas_usr -p dvdgp_mapas -e "SELECT id, location, status, created_at FROM jobs ORDER BY created_at DESC LIMIT 10;"

# Limpiar jobs de error
mysql -u dvdgp_mapas_usr -p dvdgp_mapas -e "DELETE FROM jobs WHERE status = 'error' AND created_at < DATE_SUB(NOW(), INTERVAL 7 DAY);"
```

## Estructura Final

```
/home/admin/web/mapas.iaiapro.com/public_html/
├── api/                    # Endpoints PHP
├── deploy/                 # Scripts de deployment
├── maptoposter-main/       # Código Python
│   ├── themes/
│   ├── fonts/
│   ├── create_map_poster.py
│   └── worker.py
├── private/                # Configuración sensible
│   └── .env
├── public/                 # Frontend (puede ser DocumentRoot)
│   ├── css/
│   ├── js/
│   └── index.html
├── storage/                # Mapas generados
│   └── renders/
├── venv/                   # Python virtual environment
├── .env.example
├── .gitignore
└── README.md
```

---

**¡Deployment completado!** 🗺️

Visita https://mapas.iaiapro.com para verificar que todo funciona correctamente.
