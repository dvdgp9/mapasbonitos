#!/usr/bin/env python3
"""
MAPAS BONITOS - Worker de renderizado
Consume jobs de MySQL y genera mapas usando create_map_poster.py

Usage:
    python worker.py              # Run worker
    python worker.py --test-db    # Test database connection
"""

import os
import sys
import time
import json
import hashlib
import traceback
import argparse
from datetime import datetime, timedelta
from pathlib import Path

import mysql.connector
from mysql.connector import Error as MySQLError
from dotenv import load_dotenv

# Determinar rutas
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent

# Cargar variables de entorno desde .env
env_paths = [
    PROJECT_ROOT / 'private' / '.env',
    PROJECT_ROOT / '.env',
    SCRIPT_DIR / '.env'
]

env_loaded = False
for env_path in env_paths:
    if env_path.exists():
        load_dotenv(env_path)
        print(f"[CONFIG] Loaded .env from: {env_path}")
        env_loaded = True
        break

if not env_loaded:
    print("[WARN] No .env file found, using environment variables")

# Configuración desde .env
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'database': os.getenv('DB_NAME'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASS'),
    'charset': os.getenv('DB_CHARSET', 'utf8mb4'),
}

# Validar credenciales
if not all([DB_CONFIG['database'], DB_CONFIG['user'], DB_CONFIG['password']]):
    print("[ERROR] Credenciales de base de datos no configuradas en .env")
    sys.exit(1)

# Rutas (usando constantes ya definidas arriba)
STORAGE_PATH = str(PROJECT_ROOT / 'storage' / 'renders')
THEMES_DIR = str(SCRIPT_DIR / 'themes')
FONTS_DIR = str(SCRIPT_DIR / 'fonts')

# Configuración del worker
POLL_INTERVAL = 2  # segundos entre polls
GEOCODE_CACHE_TTL = 30 * 24 * 3600  # 30 días

# Importar módulos del generador de mapas
sys.path.insert(0, str(SCRIPT_DIR))
from create_map_poster import (
    load_theme, load_fonts, create_poster, 
    get_coordinates, FONTS
)

def get_db_connection():
    """Crea conexión a MySQL"""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except MySQLError as e:
        print(f"[ERROR] Conexión a MySQL fallida: {e}")
        return None

def get_cached_geocode(conn, query):
    """Busca coordenadas en caché"""
    query_hash = hashlib.md5(query.lower().encode()).hexdigest()
    
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT latitude, longitude, display_name 
        FROM geocode_cache 
        WHERE query_hash = %s AND expires_at > NOW()
    """, (query_hash,))
    
    result = cursor.fetchone()
    cursor.close()
    
    if result:
        print(f"  ✓ Geocoding desde caché: {query}")
        # Convert Decimal to float for numpy compatibility
        return (float(result['latitude']), float(result['longitude'])), result['display_name']
    
    return None, None

def save_geocode_cache(conn, query, lat, lon, display_name):
    """Guarda coordenadas en caché"""
    query_hash = hashlib.md5(query.lower().encode()).hexdigest()
    expires_at = datetime.now() + timedelta(seconds=GEOCODE_CACHE_TTL)
    
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO geocode_cache (query_hash, query, latitude, longitude, display_name, expires_at)
        VALUES (%s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE 
            latitude = VALUES(latitude),
            longitude = VALUES(longitude),
            display_name = VALUES(display_name),
            expires_at = VALUES(expires_at)
    """, (query_hash, query, lat, lon, display_name, expires_at))
    conn.commit()
    cursor.close()

def get_next_job(conn):
    """Obtiene el siguiente job en cola (FIFO)"""
    cursor = conn.cursor(dictionary=True)
    
    # Seleccionar y marcar como running en una transacción
    cursor.execute("""
        SELECT id, location, theme, distance, title, subtitle
        FROM jobs 
        WHERE status = 'queued'
        ORDER BY created_at ASC
        LIMIT 1
        FOR UPDATE
    """)
    
    job = cursor.fetchone()
    
    if job:
        cursor.execute("""
            UPDATE jobs 
            SET status = 'running', started_at = NOW()
            WHERE id = %s
        """, (job['id'],))
        conn.commit()
    
    cursor.close()
    return job

def update_job_done(conn, job_id, result_path, lat, lon):
    """Marca job como completado"""
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE jobs 
        SET status = 'done', 
            result_path = %s,
            latitude = %s,
            longitude = %s,
            finished_at = NOW()
        WHERE id = %s
    """, (result_path, lat, lon, job_id))
    conn.commit()
    cursor.close()

def update_job_error(conn, job_id, error_message):
    """Marca job como error"""
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE jobs 
        SET status = 'error', 
            error_message = %s,
            finished_at = NOW()
        WHERE id = %s
    """, (error_message[:500], job_id))  # Truncar mensaje
    conn.commit()
    cursor.close()

def load_theme_from_db(conn, theme_id):
    """Carga tema desde la base de datos"""
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT config_json FROM themes WHERE id = %s AND active = 1
    """, (theme_id,))
    
    result = cursor.fetchone()
    cursor.close()
    
    if result:
        return json.loads(result['config_json'])
    
    # Fallback a archivo JSON
    return load_theme(theme_id)

def process_job(conn, job):
    """Procesa un job de renderizado"""
    job_id = job['id']
    location = job['location']
    theme_id = job['theme']
    distance = job['distance']
    title = job['title']
    subtitle = job['subtitle']
    
    print(f"\n{'='*50}")
    print(f"[JOB {job_id}] Procesando: {location}")
    print(f"  Tema: {theme_id}, Distancia: {distance}m")
    print('='*50)
    
    try:
        # 1. Geocodificar (con caché)
        coords, display_name = get_cached_geocode(conn, location)
        
        if not coords:
            print(f"  → Geocodificando: {location}")
            # Separar ciudad y país si es posible
            parts = [p.strip() for p in location.split(',')]
            if len(parts) >= 2:
                city, country = parts[0], parts[-1]
            else:
                city, country = location, ""
            
            # Usar geopy
            from geopy.geocoders import Nominatim
            geolocator = Nominatim(user_agent="mapasbonitos_worker")
            time.sleep(1)  # Rate limit
            
            result = geolocator.geocode(location)
            if not result:
                raise ValueError(f"No se encontró la ubicación: {location}")
            
            coords = (result.latitude, result.longitude)
            display_name = result.address
            
            # Guardar en caché
            save_geocode_cache(conn, location, coords[0], coords[1], display_name)
            print(f"  ✓ Coordenadas: {coords[0]:.4f}, {coords[1]:.4f}")
        
        lat, lon = coords
        
        # 2. Crear directorio de salida
        job_dir = os.path.join(STORAGE_PATH, str(job_id))
        os.makedirs(job_dir, exist_ok=True)
        output_file = os.path.join(job_dir, 'poster.png')
        
        # 3. Cargar tema
        global THEME
        import create_map_poster
        create_map_poster.THEME = load_theme_from_db(conn, theme_id)
        
        # 4. Determinar textos
        if not title:
            # Extraer nombre de ciudad
            parts = location.split(',')
            title = parts[0].strip().upper()
        
        if not subtitle:
            parts = location.split(',')
            if len(parts) > 1:
                subtitle = parts[-1].strip()
        
        # 5. Generar mapa
        print(f"  → Generando mapa...")
        create_poster(
            city=title,
            country=subtitle or "",
            point=coords,
            dist=distance,
            output_file=output_file
        )
        
        # 6. Verificar que se creó el archivo
        if not os.path.exists(output_file):
            raise RuntimeError("El archivo de salida no se creó")
        
        file_size = os.path.getsize(output_file)
        print(f"  ✓ Mapa generado: {file_size / 1024:.1f} KB")
        
        # 7. Marcar como completado
        result_path = f"{job_id}/poster.png"
        update_job_done(conn, job_id, result_path, lat, lon)
        
        print(f"[JOB {job_id}] ✓ Completado exitosamente")
        return True
        
    except Exception as e:
        error_msg = str(e)
        print(f"[JOB {job_id}] ✗ Error: {error_msg}")
        traceback.print_exc()
        update_job_error(conn, job_id, error_msg)
        return False

def cleanup_stale_jobs(conn):
    """Resetea jobs que quedaron 'running' por crash anterior"""
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE jobs 
        SET status = 'queued', started_at = NULL
        WHERE status = 'running' 
        AND started_at < DATE_SUB(NOW(), INTERVAL 10 MINUTE)
    """)
    affected = cursor.rowcount
    conn.commit()
    cursor.close()
    
    if affected > 0:
        print(f"[CLEANUP] {affected} jobs estancados reseteados a 'queued'")

def main():
    """Loop principal del worker"""
    print("="*50)
    print("MAPAS BONITOS - Worker de Renderizado")
    print("="*50)
    print(f"Storage: {STORAGE_PATH}")
    print(f"Poll interval: {POLL_INTERVAL}s")
    print()
    
    # Asegurar que existe el directorio de storage
    os.makedirs(STORAGE_PATH, exist_ok=True)
    
    # Verificar fuentes
    if not FONTS:
        print("[WARN] Fuentes Roboto no encontradas, usando fallback")
    
    consecutive_errors = 0
    max_consecutive_errors = 5
    
    while True:
        try:
            conn = get_db_connection()
            
            if not conn:
                print("[ERROR] No hay conexión a base de datos, reintentando en 10s...")
                time.sleep(10)
                consecutive_errors += 1
                if consecutive_errors >= max_consecutive_errors:
                    print("[FATAL] Demasiados errores consecutivos, saliendo...")
                    sys.exit(1)
                continue
            
            # Limpiar jobs estancados
            cleanup_stale_jobs(conn)
            
            # Buscar siguiente job
            job = get_next_job(conn)
            
            if job:
                consecutive_errors = 0
                process_job(conn, job)
            else:
                # No hay jobs, esperar
                time.sleep(POLL_INTERVAL)
            
            conn.close()
            
        except KeyboardInterrupt:
            print("\n[INFO] Detenido por el usuario")
            break
        except Exception as e:
            print(f"[ERROR] Error en loop principal: {e}")
            traceback.print_exc()
            consecutive_errors += 1
            if consecutive_errors >= max_consecutive_errors:
                print("[FATAL] Demasiados errores consecutivos, saliendo...")
                sys.exit(1)
            time.sleep(5)

def test_db_connection():
    """Test database connection and show status"""
    print("Testing database connection...")
    print(f"  Host: {DB_CONFIG['host']}")
    print(f"  Database: {DB_CONFIG['database']}")
    print(f"  User: {DB_CONFIG['user']}")
    
    conn = get_db_connection()
    if conn:
        print("✓ Database connection successful!")
        
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM jobs")
        jobs_count = cursor.fetchone()[0]
        print(f"  Jobs in database: {jobs_count}")
        
        cursor.execute("SELECT COUNT(*) FROM themes WHERE active = 1")
        themes_count = cursor.fetchone()[0]
        print(f"  Active themes: {themes_count}")
        
        cursor.close()
        conn.close()
        return True
    else:
        print("✗ Database connection failed!")
        return False

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='MAPAS BONITOS Worker')
    parser.add_argument('--test-db', action='store_true', help='Test database connection')
    args = parser.parse_args()
    
    if args.test_db:
        success = test_db_connection()
        sys.exit(0 if success else 1)
    else:
        main()
