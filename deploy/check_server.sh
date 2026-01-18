#!/bin/bash
# ===========================================
# MAPAS BONITOS - Server Diagnostic Script
# ===========================================
# Run this on the server to diagnose issues
# Usage: bash check_server.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "===========================================
MAPAS BONITOS - Server Diagnostics
==========================================="

# 1. Check .env file
echo -e "\n${YELLOW}[1] Checking .env file...${NC}"
if [ -f "private/.env" ]; then
    echo -e "${GREEN}✓ private/.env exists${NC}"
    echo "  Permissions: $(stat -c '%a' private/.env 2>/dev/null || stat -f '%A' private/.env)"
    
    # Check if it has content
    if grep -q "DB_NAME" private/.env; then
        echo -e "${GREEN}✓ .env has DB_NAME configured${NC}"
    else
        echo -e "${RED}✗ .env exists but missing DB_NAME${NC}"
    fi
else
    echo -e "${RED}✗ private/.env NOT FOUND!${NC}"
    echo "  You need to copy .env.example to private/.env and configure it"
fi

# 2. Check database connection
echo -e "\n${YELLOW}[2] Checking database connection...${NC}"
DB_NAME=$(grep DB_NAME private/.env 2>/dev/null | cut -d'=' -f2)
DB_USER=$(grep DB_USER private/.env 2>/dev/null | cut -d'=' -f2)
DB_PASS=$(grep DB_PASS private/.env 2>/dev/null | cut -d'=' -f2)

if [ -n "$DB_NAME" ]; then
    if mysql -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME; SELECT COUNT(*) FROM themes;" 2>/dev/null; then
        echo -e "${GREEN}✓ Database connection successful${NC}"
        THEME_COUNT=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -se "SELECT COUNT(*) FROM themes;")
        echo "  Themes in database: $THEME_COUNT"
    else
        echo -e "${RED}✗ Cannot connect to database${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Skipping DB check (no .env)${NC}"
fi

# 3. Check PHP version
echo -e "\n${YELLOW}[3] Checking PHP version...${NC}"
PHP_VERSION=$(php -v | head -n1)
echo "  $PHP_VERSION"

if php -v | grep -q "PHP 8"; then
    echo -e "${GREEN}✓ PHP version OK (8.x)${NC}"
else
    echo -e "${YELLOW}⚠ PHP version may need to be 8.0+${NC}"
fi

# 4. Check storage directory
echo -e "\n${YELLOW}[4] Checking storage directory...${NC}"
if [ -d "storage/renders" ]; then
    echo -e "${GREEN}✓ storage/renders exists${NC}"
    echo "  Permissions: $(stat -c '%a' storage/renders 2>/dev/null || stat -f '%A' storage/renders)"
    echo "  Owner: $(stat -c '%U:%G' storage/renders 2>/dev/null || stat -f '%Su:%Sg' storage/renders)"
else
    echo -e "${RED}✗ storage/renders NOT FOUND${NC}"
fi

# 5. Test API endpoint
echo -e "\n${YELLOW}[5] Testing API endpoint...${NC}"
API_TEST=$(php -r "include 'api/themes.php';" 2>&1)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ API script loads without fatal errors${NC}"
else
    echo -e "${RED}✗ API has PHP errors:${NC}"
    echo "$API_TEST"
fi

# 6. Check Python environment
echo -e "\n${YELLOW}[6] Checking Python environment...${NC}"
if [ -d "venv" ]; then
    echo -e "${GREEN}✓ venv exists${NC}"
    if [ -f "venv/bin/python" ]; then
        PYTHON_VERSION=$(venv/bin/python --version)
        echo "  Python: $PYTHON_VERSION"
        
        # Check worker
        if venv/bin/python maptoposter-main/worker.py --test-db 2>&1 | grep -q "successful"; then
            echo -e "${GREEN}✓ Worker can connect to database${NC}"
        else
            echo -e "${RED}✗ Worker cannot connect to database${NC}"
        fi
    fi
else
    echo -e "${RED}✗ venv NOT FOUND - run install_worker.sh${NC}"
fi

# 7. Check systemd service
echo -e "\n${YELLOW}[7] Checking worker service...${NC}"
if systemctl list-unit-files | grep -q mapasbonitos-worker; then
    echo -e "${GREEN}✓ Service installed${NC}"
    
    if systemctl is-active --quiet mapasbonitos-worker; then
        echo -e "${GREEN}✓ Service is running${NC}"
    else
        echo -e "${RED}✗ Service is not running${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Service not installed yet${NC}"
fi

echo -e "\n===========================================
Diagnostic complete!
==========================================="
