.PHONY: help install start stop restart status logs clean backup update

help:
	@echo "Wazuh Management Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make install    - Install and setup Wazuh"
	@echo "  make start      - Start Wazuh services"
	@echo "  make stop       - Stop Wazuh services"
	@echo "  make restart    - Restart Wazuh services"
	@echo "  make status     - Check status of services"
	@echo "  make logs       - View logs"
	@echo "  make backup     - Create backup of Wazuh data"
	@echo "  make update     - Update Wazuh to latest version"
	@echo "  make clean      - Stop and remove all containers and volumes"
	@echo ""
	@echo "Alternative: Use ./wazuh.sh script for more options"

install:
	@echo "Installing Wazuh..."
	@./wazuh.sh install

start:
	@echo "Starting Wazuh..."
	@./wazuh.sh start

stop:
	@echo "Stopping Wazuh..."
	@./wazuh.sh stop

restart:
	@echo "Restarting Wazuh..."
	@./wazuh.sh restart

status:
	@./wazuh.sh status

logs:
	@./wazuh.sh logs

backup:
	@./wazuh.sh backup

update:
	@./wazuh.sh update

clean:
	@echo "WARNING: This will remove all Wazuh data!"
	@./wazuh.sh uninstall
