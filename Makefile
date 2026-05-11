ENV ?=
INFRA_LOCATION ?= $(INFRA)

INFRA_TITLE = "Texas2010 $(INFRA_LOCATION) Infrastructure"
INFRA_FILE_NAME = com-texas2010-infra-$(INFRA_LOCATION)
SYSTEMD_SERVICE_FILE = $(INFRA_FILE_NAME).service


## Do not edit below this line to end of the fine.
.DEFAULT_GOAL := help
.PHONY: help docker-% systemd-%

## === Variables ===
SYSTEMCTL := sudo systemctl --no-pager

# === Terminal Colors ===
RESET  := \033[0m
BOLD   := \033[1m
RED    := \033[31m
GREEN  := \033[32m
YELLOW := \033[33m
BLUE   := \033[34m
CYAN   := \033[36m


# === Help command ===
help: ## Show top-level help categories
	@echo "$(BOLD)Available top-level commands:$(RESET)"
	@grep -E '^[a-zA-Z0-9_.-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| grep -vE '^(docker-|systemd)' \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-22s %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BOLD)Subcommand help targets:$(RESET)"
	@grep -E '^[a-zA-Z0-9_.-]+-help:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-22s %s\n", $$1, $$2}'


# === Docker Control ===
DOCKER_HELP = \
	up:"[Docker] Start containers (detached)" \
	down:"[Docker] Stop and remove containers" \
	restart:"[Docker] Restart containers" \
	ps:"[Docker] Show container status" \
	status:"[Docker] Show container status" \
	logs:"[Docker] Show logs" \
	build:"[Docker] Rebuild images" \
	clean:"[Docker] Remove containers, volumes, and orphans" \
	rebuild:"[Docker] Rebuild images without cache" \
	deploy:"[Docker] Deploying containers"

docker-help: ## [Docker] Show Docker subcommands
	@echo "$(BOLD)Docker subcommands:$(RESET)"
	@for item in $(DOCKER_HELP); do \
		key=$${item%%:*}; val=$${item#*:}; \
		printf "  docker-%-15s %s\n" "$$key" "$$val"; \
	done
	@grep -E '^docker-[a-zA-Z0-9_.-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS=":.*?## "}; {printf "  %-22s %s\n", $$1, $$2}'

docker-%:
	@INFRA_LOCATION="$(or $(INFRA_LOCATION),$(INFRA))" DOCKER_ENV="$(DOCKER_ENV)" bash ./scripts/docker.sh "$*"

# === Systemd Control ===
SYSTEMD_HELP = \
	start:"[Systemd] Start service" \
	stop:"[Systemd] Stop service" \
	restart:"[Systemd] Restart service" \
	status:"[Systemd] Show service status" \
	enable:"[Systemd] Enable service" \
	disable:"[Systemd] Disable service"

systemd-help: ## [Systemd] Show Systemd subcommands
	@echo "$(BOLD)Systemd subcommands:$(RESET)"
	@for item in $(SYSTEMD_HELP); do \
		key=$${item%%:*}; val=$${item#*:}; \
		printf "  systemd-%-15s %s\n" "$$key" "$$val"; \
	done
	@grep -E '^systemd-[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-23s %s\n", $$1, $$2}'


systemd-%:
	@case "$*" in \
		start)    echo "$(GREEN)[Systemd] Starting $(INFRA_LOCATION)...$(RESET)";; \
		stop)     echo "$(YELLOW)[Systemd] Stopping $(INFRA_LOCATION)...$(RESET)";; \
		restart)  echo "$(BLUE)[Systemd] Restarting $(INFRA_LOCATION)...$(RESET)";; \
		status)   echo "$(CYAN)[Systemd] Checking status $(INFRA_LOCATION)...$(RESET)";; \
		enable)   echo "$(CYAN)[Systemd] Enabling $(INFRA_LOCATION)...$(RESET)";; \
		disable)  echo "$(CYAN)[Systemd] Disabling $(INFRA_LOCATION)...$(RESET)";; \
		*)        echo "$(RED)[Systemd] Unknown command '$*'$(RESET)"; exit 1;; \
	esac
	@$(SYSTEMCTL) $* $(SYSTEMD_SERVICE_FILE)

# === Workflow ===

update-all: ## [System] Stop, update from Git, rebuild, and restart containers
	@echo "$(YELLOW)[Docker] Stopping containers...$(RESET)"
	@$(MAKE) docker-down
	@echo "$(BLUE)[Git] Pulling latest code...$(RESET)"
	git pull
	@echo "$(CYAN)[Docker] Rebuilding images without cache...$(RESET)"
	docker compose -f $(COMPOSE_FILE) build --no-cache
	@echo "$(GREEN)[Docker] Starting containers...$(RESET)"
	@$(MAKE) docker-up

create-systemd-service-file:
	@mkdir -p logs
	@echo "$(CYAN)[Systemd] Creating service file $(SYSTEMD_SERVICE_FILE)...$(RESET)"
	@echo "[Unit]" > $(SYSTEMD_SERVICE_FILE)
	@echo "Description=$(INFRA_TITLE)" >> $(SYSTEMD_SERVICE_FILE)
	@echo "After=network.target docker.service" >> $(SYSTEMD_SERVICE_FILE)
	@echo "Requires=docker.service" >> $(SYSTEMD_SERVICE_FILE)
	@echo "" >> $(SYSTEMD_SERVICE_FILE)
	@echo "[Service]" >> $(SYSTEMD_SERVICE_FILE)
	@echo "Type=oneshot" >> $(SYSTEMD_SERVICE_FILE)
	@echo "RemainAfterExit=yes" >> $(SYSTEMD_SERVICE_FILE)
	@echo "WorkingDirectory=$(PWD)" >> $(SYSTEMD_SERVICE_FILE)
	@echo "ExecStart=/usr/bin/docker compose up -d" >> $(SYSTEMD_SERVICE_FILE)
	@echo "ExecStop=/usr/bin/docker compose down" >> $(SYSTEMD_SERVICE_FILE)
	@echo "StandardOutput=append:$(PWD)/logs/service.log" >> $(SYSTEMD_SERVICE_FILE)
	@echo "StandardError=append:$(PWD)/logs/service-error.log" >> $(SYSTEMD_SERVICE_FILE)
	@echo "" >> $(SYSTEMD_SERVICE_FILE)
	@echo "[Install]" >> $(SYSTEMD_SERVICE_FILE)
	@echo "WantedBy=multi-user.target" >> $(SYSTEMD_SERVICE_FILE)
	@echo "$(GREEN)[Systemd] Created: $(SYSTEMD_SERVICE_FILE)$(RESET)"

systemd-create-file: create-systemd-service-file ## [Systemd] Build a .service file using the current directory

systemd-install-file: create-systemd-service-file ## [Systemd] Move, reload, enable, and start service
	@echo "$(CYAN)[Systemd] Installing $(INFRA_LOCATION)...$(RESET)"
	sudo mv $(SYSTEMD_SERVICE_FILE) /etc/systemd/system/
	sudo systemctl daemon-reload
	@$(MAKE) systemd-enable
	@$(MAKE) systemd-start

systemd-uninstall: ## [Systemd] Stop, disable, and remove the unit
	@echo "$(YELLOW)[Systemd] Uninstalling $(SYSTEMD_SERVICE_FILE)...$(RESET)"
	$(SYSTEMCTL) stop $(SYSTEMD_SERVICE_FILE) || true
	$(SYSTEMCTL) disable $(SYSTEMD_SERVICE_FILE) || true
	sudo rm -f /etc/systemd/system/$(SYSTEMD_SERVICE_FILE)
	sudo systemctl daemon-reload
	@echo "$(RED)[Systemd] Removed: $(SYSTEMD_SERVICE_FILE)$(RESET)"

systemd-rebuild: systemd-stop ## [Systemd] Rebuild Docker images and restart service
	@echo "$(BLUE)[Git] Pulling latest code...$(RESET)"
	git pull
	@echo "$(CYAN)[Docker] Rebuilding images without cache...$(RESET)"
	docker compose -f $(COMPOSE_FILE) build --no-cache
	@$(MAKE) systemd-start

systemd-logs: ## [Systemd] Show full logs from systemd journal
	@echo "$(CYAN)[Systemd] Showing full logs for $(SYSTEMD_SERVICE_FILE)...$(RESET)"
	@sudo journalctl -u $(SYSTEMD_SERVICE_FILE)

systemd-logs-recent: ## [Systemd] Show recent logs and follow live
	@echo "$(CYAN)[Systemd] Showing recent logs for $(SYSTEMD_SERVICE_FILE)...(Ctrl+C to stop)$(RESET)"
	@sudo journalctl -u $(SYSTEMD_SERVICE_FILE) -n 50 -f
