#!/bin/bash
# ===========================================
# MAPAS BONITOS - Worker Installation Script
# ===========================================
# Run as root or with sudo on the server
# Usage: sudo bash install_worker.sh /var/www/mapas.iaiapro.com

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root (sudo)${NC}"
    exit 1
fi

# Get project path
PROJECT_PATH="${1:-/var/www/mapas.iaiapro.com}"

if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}Error: Project path does not exist: $PROJECT_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}===========================================\n"
echo "MAPAS BONITOS - Worker Installation"
echo -e "===========================================${NC}\n"
echo "Project path: $PROJECT_PATH"

# 1. Install system dependencies
echo -e "\n${YELLOW}[1/6] Installing system dependencies...${NC}"
apt-get update
apt-get install -y python3 python3-pip python3-venv

# 2. Create virtual environment
echo -e "\n${YELLOW}[2/6] Creating Python virtual environment...${NC}"
VENV_PATH="$PROJECT_PATH/venv"
if [ ! -d "$VENV_PATH" ]; then
    python3 -m venv "$VENV_PATH"
    echo "Created venv at $VENV_PATH"
else
    echo "Venv already exists at $VENV_PATH"
fi

# 3. Install Python dependencies
echo -e "\n${YELLOW}[3/6] Installing Python dependencies...${NC}"
"$VENV_PATH/bin/pip" install --upgrade pip
"$VENV_PATH/bin/pip" install -r "$PROJECT_PATH/maptoposter-main/requirements.txt"

# 4. Create storage directory
echo -e "\n${YELLOW}[4/6] Setting up storage directory...${NC}"
mkdir -p "$PROJECT_PATH/storage/renders"
chown -R www-data:www-data "$PROJECT_PATH/storage"
chmod -R 755 "$PROJECT_PATH/storage"

# 5. Update and install systemd service
echo -e "\n${YELLOW}[5/6] Installing systemd service...${NC}"
SERVICE_FILE="$PROJECT_PATH/deploy/mapasbonitos-worker.service"
SYSTEMD_PATH="/etc/systemd/system/mapasbonitos-worker.service"

# Update paths in service file
sed -i "s|/var/www/mapas.iaiapro.com|$PROJECT_PATH|g" "$SERVICE_FILE"

# Copy to systemd
cp "$SERVICE_FILE" "$SYSTEMD_PATH"
systemctl daemon-reload

# 6. Enable and start service
echo -e "\n${YELLOW}[6/6] Enabling and starting worker service...${NC}"
systemctl enable mapasbonitos-worker
systemctl start mapasbonitos-worker

# Check status
sleep 2
if systemctl is-active --quiet mapasbonitos-worker; then
    echo -e "\n${GREEN}✓ Worker installed and running successfully!${NC}"
    systemctl status mapasbonitos-worker --no-pager
else
    echo -e "\n${RED}✗ Worker failed to start. Check logs:${NC}"
    journalctl -u mapasbonitos-worker -n 20 --no-pager
    exit 1
fi

echo -e "\n${GREEN}===========================================\n"
echo "Installation complete!"
echo -e "===========================================${NC}\n"
echo "Useful commands:"
echo "  systemctl status mapasbonitos-worker   # Check status"
echo "  systemctl restart mapasbonitos-worker  # Restart worker"
echo "  journalctl -u mapasbonitos-worker -f   # View logs"
echo ""
