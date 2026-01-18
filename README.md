# 🗺️ Mapas Bonitos

Plataforma web para generar mapas artísticos y minimalistas de cualquier ciudad del mundo.

![Demo](maptoposter-main/posters/tokyo_japanese_ink_20260108_165830.png)

## ✨ Características

- **17 temas únicos**: Desde Noir hasta Neon Cyberpunk
- **Cualquier ciudad**: Geocodificación automática vía Nominatim
- **Alta resolución**: Mapas listos para imprimir (300 DPI)
- **Interfaz moderna**: Frontend responsive sin frameworks
- **Cola asíncrona**: Generación en background con MySQL
- **Rate limiting**: Protección contra abuso

## 🏗️ Arquitectura

```
┌─────────────────┐     ┌─────────────┐     ┌─────────────────┐
│   Frontend      │────▶│   API PHP   │────▶│  MySQL Queue    │
│   HTML/CSS/JS   │     │   Vanilla   │     │  (jobs table)   │
└─────────────────┘     └─────────────┘     └────────┬────────┘
                                                     │
                        ┌─────────────┐              ▼
                        │   Storage   │◀────┌─────────────────┐
                        │   /renders  │     │  Python Worker  │
                        └─────────────┘     │  (systemd)      │
                                            └─────────────────┘
```

## 🚀 Instalación Rápida

### Requisitos

- PHP 8.0+
- MySQL 5.7+ / MariaDB 10.3+
- Python 3.9+
- 2GB+ RAM

### 1. Clonar repositorio

```bash
git clone https://github.com/tu-usuario/mapasbonitos.git
cd mapasbonitos
```

### 2. Configurar base de datos

```bash
# Crear base de datos y usuario
mysql -u root -p < deploy/schema.sql
mysql -u root -p dvdgp_mapas < deploy/seed_themes.sql
```

### 3. Configurar entorno

```bash
cp .env.example private/.env
# Editar private/.env con tus credenciales
```

### 4. Instalar worker Python

```bash
# Crear virtual environment
python3 -m venv venv
venv/bin/pip install -r maptoposter-main/requirements.txt

# Instalar como servicio (producción)
sudo bash deploy/install_worker.sh $(pwd)
```

### 5. Configurar servidor web

Ver [deploy/DEPLOYMENT.md](deploy/DEPLOYMENT.md) para guía completa de HestiaCP.

## 📁 Estructura del Proyecto

```
mapasbonitos/
├── api/                      # Backend PHP
│   ├── config.php            # Configuración
│   ├── db.php                # Conexión MySQL
│   ├── jobs.php              # Crear/consultar jobs
│   ├── themes.php            # Listar temas
│   ├── download.php          # Descargar mapas
│   ├── rate_limiter.php      # Control de rate limit
│   └── response.php          # Helper de respuestas JSON
│
├── public/                   # Frontend
│   ├── css/styles.css        # Estilos
│   ├── js/app.js             # JavaScript
│   ├── examples/             # Imágenes de ejemplo
│   └── index.html            # Página principal
│
├── maptoposter-main/         # Motor de generación Python
│   ├── create_map_poster.py  # Script principal
│   ├── worker.py             # Worker de cola
│   ├── themes/               # 17 temas JSON
│   ├── fonts/                # Fuentes Roboto
│   └── requirements.txt      # Dependencias Python
│
├── storage/renders/          # Mapas generados (gitignored)
├── private/.env              # Configuración (gitignored)
│
├── deploy/                   # Scripts de deployment
│   ├── schema.sql            # Schema MySQL
│   ├── seed_themes.sql       # Datos iniciales
│   ├── install_worker.sh     # Instalador worker
│   ├── worker.sh             # Gestión del worker
│   ├── mapasbonitos-worker.service  # systemd unit
│   └── DEPLOYMENT.md         # Guía de deployment
│
├── .env.example              # Template de configuración
├── .gitignore
└── README.md
```

## 🎨 Temas Disponibles

| Tema | Descripción |
|------|-------------|
| `noir` | Fondo negro, calles blancas - estética de galería |
| `midnight_blue` | Azul marino con dorado - atlas de lujo |
| `neon_cyberpunk` | Rosa/cian eléctrico - vibes de ciudad nocturna |
| `blueprint` | Estilo plano arquitectónico |
| `japanese_ink` | Tinta tradicional japonesa |
| `warm_beige` | Tonos sepia - mapa vintage |
| `ocean` | Azules y turquesas - ciudades costeras |
| `sunset` | Naranjas y rosas cálidos |
| `forest` | Verdes profundos - estética botánica |
| `terracotta` | Calidez mediterránea |
| `pastel_dream` | Pasteles suaves y oníricos |
| `copper_patina` | Cobre oxidado con verde |
| `autumn` | Naranjas quemados y rojos |
| `monochrome_blue` | Familia de azules |
| `contrast_zones` | Alto contraste urbano |
| `feature_based` | Jerarquía de carreteras clásica |
| `gradient_roads` | Degradado suave |

## 🔌 API Endpoints

### `POST /api/jobs.php` - Crear job

```json
{
  "location": "Madrid, España",
  "theme": "noir",
  "distance": 10000,
  "title": "MADRID",
  "subtitle": "España"
}
```

### `GET /api/jobs.php?id={id}` - Consultar status

Respuesta:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "status": "done",
    "result_url": "/api/download.php?id=1"
  }
}
```

### `GET /api/themes.php` - Listar temas

### `GET /api/download.php?id={id}` - Descargar mapa

## ⚙️ Configuración

Variables de entorno en `private/.env`:

```env
# Base de datos
DB_HOST=localhost
DB_NAME=dvdgp_mapas
DB_USER=dvdgp_mapas_usr
DB_PASS=tu_password

# Aplicación
APP_URL=https://mapas.iaiapro.com
APP_ENV=production
APP_DEBUG=false

# Rate limiting
RATE_LIMIT_MAX_JOBS=5
RATE_LIMIT_WINDOW_HOURS=1
```

## 🔧 Comandos del Worker

```bash
# Usando el script de gestión
./deploy/worker.sh status
./deploy/worker.sh restart
./deploy/worker.sh logs

# Test de conexión a BD
./deploy/worker.sh test

# Usando systemctl directamente
sudo systemctl status mapasbonitos-worker
sudo journalctl -u mapasbonitos-worker -f
```

## 📊 Base de Datos

### Tabla `jobs`
- Cola de trabajos de generación
- Estados: `queued` → `running` → `done` / `error`

### Tabla `themes`
- Catálogo de temas con configuración JSON

### Tabla `geocode_cache`
- Caché de geocodificación (TTL 30 días)

### Tabla `rate_limits`
- Tracking de requests por IP

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Añadir nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📝 Licencia

MIT License - Ver [LICENSE](LICENSE) para más detalles.

## 🙏 Créditos

- Datos de mapas: [OpenStreetMap](https://www.openstreetmap.org/copyright)
- Geocodificación: [Nominatim](https://nominatim.org/)
- Librería de mapas: [OSMnx](https://github.com/gboeing/osmnx)
- Fuentes: [Roboto](https://fonts.google.com/specimen/Roboto)

---

Hecho con ❤️ para crear mapas bonitos de cualquier lugar del mundo.
