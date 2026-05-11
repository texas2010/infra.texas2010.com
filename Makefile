ENV ?=
INFRA_LOCATION ?= $(INFRA)

.DEFAULT_GOAL := help
.PHONY: help docker-% systemd-%

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
	disable:"[Systemd] Disable service" \
	logs-recent:"[Systemd] Show recent logs and follow live" \
	logs:"[Systemd] Show full logs from systemd journal" \
	rebuild:"[Systemd] Rebuild Docker containers and restart Service" \
	create-file:"[Systemd] Create Systemd Service file" \
	install-file:"[Systemd] Move, reload, enable, and start service" \
	unintall-file:"[Systemd] Stop, disable, and remove the service"

systemd-help: ## [Systemd] Show Systemd subcommands
	@echo "$(BOLD)Systemd subcommands:$(RESET)"
	@for item in $(SYSTEMD_HELP); do \
		key=$${item%%:*}; val=$${item#*:}; \
		printf "  systemd-%-15s %s\n" "$$key" "$$val"; \
	done
	@grep -E '^systemd-[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-23s %s\n", $$1, $$2}'

systemd-%:
	@bash ./scripts/systemd.sh "$*"