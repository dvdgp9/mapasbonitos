# MAPAS BONITOS - Plataforma Web de Generación de Mapas

## Background and Motivation

Crear una plataforma web completa que permita a usuarios generar mapas bonitos de cualquier ciudad del mundo usando el código Python existente en `maptoposter-main`. La plataforma debe ser simple, escalable y fácil de desplegar en HestiaCP.

### Contexto técnico
- **Código existente**: Generador Python con osmnx/matplotlib que crea mapas de alta calidad
- **17 temas disponibles**: De noir a neon_cyberpunk, todos en formato JSON
- **Stack decidido**: PHP vanilla + MySQL + HTML/CSS/JS + Worker Python
- **Hosting**: Hetzner con HestiaCP
- **Dominio**: mapas.iaiapro.com

### Arquitectura elegida (Híbrida MySQL-based)
```
[Frontend HTML/JS] → [API PHP] → [MySQL Jobs Queue] → [Worker Python] → [Storage]
                                      ↓
                                [Geocode Cache]
                                [Rate Limits]
```

## Key Challenges and Analysis

### 1. **Arquitectura de Cola sin Redis**
- **Desafío**: Manejar cola de trabajos asíncronos solo con MySQL
- **Solución**: Tabla `jobs` con índice en `status` + worker Python con polling
- **Ventaja**: Simplifica deployment inicial, escalable a Redis después

### 2. **Caché de Geocoding**
- **Problema**: Nominatim tiene rate limits estrictos (1 req/seg)
- **Solución**: Tabla `geocode_cache` con TTL de 30 días + hash de queries
- **Beneficio**: Respuesta instantánea para ciudades populares

### 3. **Rate Limiting sin Redis**
- **Desafío**: Prevenir abuso sin herramientas externas
- **Solución**: Tabla `rate_limits` con tracking por IP + ventanas de tiempo
- **Límites**: 5 jobs/hora por IP anónima, configurable

### 4. **Storage de Mapas Generados**
- **Estrategia**: Sistema de archivos local en `storage/renders/{job_id}/poster.png`
- **Path público**: Servido vía PHP o symlink a `public/renders/`
- **Futuro**: Migrable a S3-compatible (MinIO, Wasabi, etc.)

### 5. **Worker Python como Servicio**
- **Integración**: Servicio systemd que corre independiente del webserver
- **Resilencia**: Auto-restart + cleanup de jobs estancados
- **Deploy**: Script de instalación para HestiaCP

### 6. **Frontend sin Frameworks**
- **Vanilla JS**: Fetch API + polling para status + preview de temas
- **UX**: Configurador interactivo → envío → polling con progress → descarga
- **Responsive**: CSS Grid/Flexbox para mobile-first

## High-level Task Breakdown

### **Fase 1: Infraestructura Base y Configuración del Repo**
**Objetivo**: Estructura de directorios, archivos de configuración, schema MySQL y preparación para GitHub.

#### Tareas:
1. **Crear estructura de directorios**
   - `/api` → endpoints PHP
   - `/public` → frontend HTML/CSS/JS
   - `/storage/renders` → mapas generados (gitignored)
   - `/private` → .env y configs sensibles (gitignored)
   - `/deploy` → scripts de deployment y systemd
   - `/maptoposter-main` → código Python existente (ya existe)
   
2. **Archivo `.gitignore`**
   - Excluir: `storage/`, `private/`, `*.pyc`, `.env`, `.DS_Store`
   
3. **Crear `.env.example`**
   - Template con todas las variables necesarias (DB, paths, etc.)
   
4. **Diseñar schema MySQL completo**
   - Tabla `jobs`: cola de trabajos
   - Tabla `geocode_cache`: caché de geocoding
   - Tabla `rate_limits`: control de rate limiting
   - Tabla `themes`: catálogo de temas (migrar desde JSON)
   - Índices optimizados para queries frecuentes
   
5. **Script SQL de inicialización**
   - `deploy/schema.sql` → crear todas las tablas
   - `deploy/seed_themes.sql` → poblar temas desde JSON

**Criterios de éxito**:
- ✅ Estructura de carpetas completa
- ✅ `.gitignore` protege archivos sensibles
- ✅ Schema SQL ejecutable y probado
- ✅ `.env.example` documentado

---

### **Fase 2: Backend API PHP (Vanilla)**
**Objetivo**: 4 endpoints RESTful que manejan jobs, temas, status y descarga.

#### Endpoints a crear:

1. **`POST /api/jobs.php`** - Crear nuevo job
   - Input: `{location, theme, distance?, title?, subtitle?}`
   - Validación: rate limit por IP, validar theme existe
   - Output: `{job_id, status: "queued"}`
   
2. **`GET /api/jobs.php?id={job_id}`** - Consultar status
   - Output: `{id, status, progress?, result_url?, error?}`
   - Estados: `queued`, `running`, `done`, `error`
   
3. **`GET /api/themes.php`** - Listar temas disponibles
   - Output: `[{id, name, description, preview_colors}]`
   - Incluir colores principales para preview
   
4. **`GET /api/download.php?id={job_id}`** - Descargar mapa
   - Validación: job completado, archivo existe
   - Headers: Content-Disposition para descarga
   - Seguridad: path traversal protection

#### Funcionalidades comunes:
- **`/api/config.php`**: Clase Config para cargar .env
- **`/api/db.php`**: Clase Database con PDO + prepared statements
- **`/api/rate_limiter.php`**: Clase RateLimiter para control de IPs
- Headers CORS apropiados
- JSON responses consistentes
- Error handling robusto

**Criterios de éxito**:
- ✅ 4 endpoints funcionales y documentados
- ✅ Rate limiting funciona (5 req/hora/IP)
- ✅ Respuestas JSON válidas y consistentes
- ✅ Manejo de errores adecuado

---

### **Fase 3: Worker Python Integrado**
**Objetivo**: Adaptar `worker.py` existente y crear servicio systemd.

#### Tareas:

1. **Ajustar `worker.py` para nueva estructura**
   - Leer `.env` desde `/private/.env` o root del proyecto
   - Storage path a `/storage/renders/{job_id}/poster.png`
   - Cargar temas desde MySQL (tabla `themes`) en lugar de solo archivos JSON
   - Logging mejorado con timestamps
   
2. **Validar integración con `create_map_poster.py`**
   - Verificar que imports funcionan correctamente
   - Probar con job de prueba manual en BD
   
3. **Script de instalación del worker**
   - `/deploy/install_worker.sh`
   - Instalar dependencias Python (venv recomendado)
   - Copiar systemd service file
   - Configurar permisos
   
4. **Archivo systemd service**
   - `/deploy/mapasbonitos-worker.service`
   - Auto-restart on failure
   - Logging a journalctl
   - User/Group según HestiaCP
   
5. **Script de gestión**
   - `/deploy/worker.sh` con comandos: start, stop, restart, status, logs

**Criterios de éxito**:
- ✅ Worker procesa jobs correctamente
- ✅ Se reinicia automáticamente si falla
- ✅ Logs accesibles vía journalctl
- ✅ Caché de geocoding funciona

---

### **Fase 4: Frontend HTML/CSS/JS Vanilla**
**Objetivo**: Interfaz moderna, responsive y user-friendly.

#### Páginas/Secciones:

1. **Landing Page (`/public/index.html`)**
   - Hero con título y descripción breve
   - CTA principal: "Crear tu mapa"
   - Galería de ejemplos (imágenes de los mapas del README)
   - Footer con atribución

2. **Configurador (`/public/create.html` o sección en index)**
   - **Paso 1**: Input de ubicación (ciudad, país o lugar)
   - **Paso 2**: Selector de tema (grid visual con previews)
   - **Paso 3**: Slider de distancia (4km - 20km)
   - **Paso 4**: Opcionales (título custom, subtítulo)
   - Botón "Generar Mapa"
   
3. **Status Page (`/public/status.html?job={id}`)**
   - Polling automático cada 2 segundos
   - Estados visuales:
     - ⏳ En cola
     - 🎨 Generando mapa (con progress si es posible)
     - ✅ Completado → mostrar preview + botón descarga
     - ❌ Error → mensaje descriptivo
   
4. **Galería opcional (`/public/gallery.html`)**
   - Listado de mapas públicos recientes
   - Solo si decidimos hacerla después

#### Estilo:
- **CSS moderno**: Variables CSS, Grid, Flexbox
- **Responsive**: Mobile-first approach
- **Tema visual**: Minimalista, colores neutros con acentos
- **Iconos**: Usar emojis o SVGs inline (sin dependencias)

#### JavaScript:
- **No jQuery**: Vanilla JS con Fetch API
- **Polling inteligente**: Backoff exponencial si job tarda mucho
- **Form validation**: Client-side básica
- **Error handling**: Mensajes claros al usuario

**Criterios de éxito**:
- ✅ Interfaz responsive (mobile + desktop)
- ✅ Flujo completo: configurar → generar → descargar
- ✅ Preview de temas funciona
- ✅ Polling de status es smooth

---

### **Fase 5: Integración, Pruebas y Documentación de Despliegue**
**Objetivo**: Sistema end-to-end funcional con guía de deployment para HestiaCP.

#### Tareas:

1. **Smoke Tests End-to-End**
   - Crear job desde frontend → verificar en BD → worker procesa → descarga funciona
   - Probar rate limiting
   - Probar caché de geocoding (mismo lugar 2 veces)
   - Probar con diferentes temas
   
2. **Guía de deployment para HestiaCP** (`/deploy/DEPLOYMENT.md`)
   - **Requisitos del servidor**: Python 3.9+, MySQL 5.7+, PHP 8.x
   - **Paso 1**: Clonar repo en directorio web
   - **Paso 2**: Configurar virtual host en HestiaCP
   - **Paso 3**: Crear base de datos y usuario MySQL
   - **Paso 4**: Copiar `.env.example` → `.env` y configurar
   - **Paso 5**: Ejecutar `deploy/schema.sql`
   - **Paso 6**: Instalar dependencias Python (venv)
   - **Paso 7**: Instalar y activar worker systemd
   - **Paso 8**: Configurar permisos de `storage/`
   - **Paso 9**: Probar con job de prueba
   
3. **README.md principal**
   - Descripción del proyecto
   - Screenshots del frontend
   - Instrucciones de instalación
   - Arquitectura del sistema
   - Créditos y licencia
   
4. **Script de deployment automatizado** (opcional pero recomendado)
   - `/deploy/deploy.sh` que ejecute todos los pasos
   
5. **Logs y monitoring básico**
   - Verificar que logs del worker son accesibles
   - Documentar cómo ver errores

**Criterios de éxito**:
- ✅ Guía de deployment reproducible paso a paso
- ✅ Sistema funciona end-to-end en entorno limpio
- ✅ README completo y claro
- ✅ Worker se inicia correctamente con systemd

---

## Project Status Board
- [x] **Fase 1**: Infraestructura base y configuración del repo ✅
  - [x] Crear estructura de directorios
  - [x] Configurar `.gitignore` y `.env.example`
  - [x] Diseñar schema MySQL completo
  - [x] Crear scripts SQL (schema + seed themes)
  
- [x] **Fase 2**: Backend API PHP (vanilla) ✅
  - [x] Endpoint POST /api/jobs.php
  - [x] Endpoint GET /api/jobs.php (status)
  - [x] Endpoint GET /api/themes.php
  - [x] Endpoint GET /api/download.php
  - [x] Clases comunes (Config, Database, RateLimiter, Response)
  
- [x] **Fase 3**: Worker Python integrado ✅
  - [x] Ajustar worker.py para nueva estructura
  - [x] Crear systemd service file
  - [x] Script de instalación (install_worker.sh)
  - [x] Script de gestión (worker.sh)
  - [x] Test de conexión BD (--test-db)
  
- [x] **Fase 4**: Frontend HTML/CSS/JS ✅
  - [x] Landing page (index.html)
  - [x] Configurador de mapas con selector de temas
  - [x] Modal de status con polling
  - [x] Estilos responsive (CSS vanilla)
  - [x] JavaScript vanilla para interacciones
  
- [x] **Fase 5**: Integración, pruebas y docs de despliegue ✅
  - [x] Guía de deployment HestiaCP (DEPLOYMENT.md)
  - [x] README.md principal completo
  - [x] .htaccess para Apache
  - [ ] Smoke tests E2E (pendiente en servidor real)
  - [ ] Validación final (pendiente deployment)

---

## Current Status / Progress Tracking

**Estado actual**: ✅ IMPLEMENTACIÓN COMPLETADA

**Fecha**: 18 Enero 2026

### Archivos creados:
- `api/` - 6 archivos PHP (config, db, jobs, themes, download, rate_limiter, response, .htaccess)
- `public/` - Frontend completo (index.html, css/styles.css, js/app.js, .htaccess)
- `deploy/` - 5 archivos (schema.sql, seed_themes.sql, install_worker.sh, worker.sh, mapasbonitos-worker.service, DEPLOYMENT.md)
- `private/.env` - Configuración con credenciales
- `.gitignore`, `.env.example`, `README.md`
- `storage/renders/.gitkeep` - Directorio para mapas generados
- `maptoposter-main/worker.py` - Actualizado con nuevas rutas

### Pendiente del usuario:
1. Ejecutar SQL en el servidor: `schema.sql` + `seed_themes.sql`
2. Subir a GitHub
3. Deploy en HestiaCP siguiendo `deploy/DEPLOYMENT.md`
4. Instalar worker Python con `deploy/install_worker.sh`
5. Smoke tests en servidor real

---

## Executor's Feedback or Assistance Requests

_Este espacio será utilizado por el Executor para reportar progreso, bloqueos o solicitar aclaraciones._

---

## Lessons

_Lecciones aprendidas durante el desarrollo se documentarán aquí para referencia futura._

### Decisiones de arquitectura

1. **MySQL como cola de jobs**: Simplifica deployment inicial, se puede migrar a Redis después sin cambiar la arquitectura
2. **PHP vanilla**: Sin frameworks = sin actualizaciones de dependencias, más simple para hosting compartido
3. **Worker Python independiente**: systemd service separado del webserver = escalabilidad y aislamiento
4. **Storage local**: Path `/storage/renders/{job_id}/poster.png` es migrable a S3 cambiando solo rutas

### Dependencias Python clave
- `osmnx==2.0.7`: Descarga datos de OpenStreetMap
- `matplotlib==3.10.8`: Renderizado de mapas
- `geopy==2.4.1`: Geocoding (Nominatim)
- `mysql-connector-python==8.3.0`: Conexión a MySQL
- `python-dotenv==1.0.0`: Manejo de variables de entorno

### Datos de la BD (para .env)
```
DB_HOST=localhost
DB_NAME=dvdgp_mapas
DB_USER=dvdgp_mapas_usr
DB_PASS=mapasusrPASS2!
DB_CHARSET=utf8mb4
```

### Temas disponibles (17 total)
autumn, blueprint, contrast_zones, copper_patina, feature_based, forest, gradient_roads, japanese_ink, midnight_blue, monochrome_blue, neon_cyberpunk, noir, ocean, pastel_dream, sunset, terracotta, warm_beige

---

## Notas Técnicas Adicionales

### Rate Limiting
- **IP anónima**: 5 jobs/hora
- **Ventana deslizante**: Limpiar registros > 1 hora automáticamente
- **Implementación**: Tabla `rate_limits` con timestamp + IP hash

### Geocoding Cache
- **TTL**: 30 días
- **Hash**: MD5 del query normalizado (lowercase)
- **Limpieza**: Cronjob diario o lazy cleanup en worker

### Worker Behavior
- **Poll interval**: 2 segundos
- **Cleanup de jobs estancados**: Jobs en "running" > 10 minutos → reset a "queued"
- **Rate limit Nominatim**: 1 segundo entre requests (ya implementado)

### Security Checklist
- ✅ Prepared statements en todas las queries SQL
- ✅ Path traversal protection en download
- ✅ Rate limiting por IP
- ✅ `.env` fuera de public_html
- ✅ CORS headers apropiados
- ⚠️ Considerar CAPTCHA si hay abuso (Fase 6 opcional)
