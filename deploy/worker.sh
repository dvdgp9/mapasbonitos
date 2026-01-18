#!/bin/bash
# ===========================================
# MAPAS BONITOS - Worker Management Script
# ===========================================
# Usage: ./worker.sh [start|stop|restart|status|logs|test]

SERVICE_NAME="mapasbonitos-worker"

case "$1" in
    start)
        echo "Starting $SERVICE_NAME..."
        sudo systemctl start $SERVICE_NAME
        sudo systemctl status $SERVICE_NAME --no-pager
        ;;
    stop)
        echo "Stopping $SERVICE_NAME..."
        sudo systemctl stop $SERVICE_NAME
        echo "Stopped."
        ;;
    restart)
        echo "Restarting $SERVICE_NAME..."
        sudo systemctl restart $SERVICE_NAME
        sleep 2
        sudo systemctl status $SERVICE_NAME --no-pager
        ;;
    status)
        sudo systemctl status $SERVICE_NAME --no-pager
        ;;
    logs)
        echo "Showing logs (Ctrl+C to exit)..."
        sudo journalctl -u $SERVICE_NAME -f
        ;;
    logs-all)
        sudo journalctl -u $SERVICE_NAME --no-pager
        ;;
    test)
        echo "Testing database connection..."
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
        VENV_PATH="$PROJECT_DIR/venv"
        
        if [ -d "$VENV_PATH" ]; then
            "$VENV_PATH/bin/python" "$PROJECT_DIR/maptoposter-main/worker.py" --test-db
        else
            python3 "$PROJECT_DIR/maptoposter-main/worker.py" --test-db
        fi
        ;;
    enable)
        echo "Enabling $SERVICE_NAME to start on boot..."
        sudo systemctl enable $SERVICE_NAME
        echo "Enabled."
        ;;
    disable)
        echo "Disabling $SERVICE_NAME from starting on boot..."
        sudo systemctl disable $SERVICE_NAME
        echo "Disabled."
        ;;
    *)
        echo "MAPAS BONITOS - Worker Management"
        echo ""
        echo "Usage: $0 {start|stop|restart|status|logs|logs-all|test|enable|disable}"
        echo ""
        echo "Commands:"
        echo "  start     Start the worker service"
        echo "  stop      Stop the worker service"
        echo "  restart   Restart the worker service"
        echo "  status    Show service status"
        echo "  logs      Follow live logs (Ctrl+C to exit)"
        echo "  logs-all  Show all logs"
        echo "  test      Test database connection"
        echo "  enable    Enable auto-start on boot"
        echo "  disable   Disable auto-start on boot"
        exit 1
        ;;
esac

exit 0
