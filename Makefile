.DEFAULT_GOAL := help
.PHONY: help docker-%

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
	logs:"[Docker] Show logs" \
	build:"[Docker] Build images" \
	clean:"[Docker] Remove containers, volumes, and orphans" \
	rebuild:"[Docker] Rebuild images without cache" \
	deploy:"[Docker] Build and start containers" \
	update:"[Docker] Stop containers, Pull code, Rebuild images, Start containers" \
	config:"[Docker] Show resolved Docker Compose config"

docker-help: ## [Docker] Show Docker subcommands
	@echo "$(BOLD)Docker subcommands:$(RESET)"
	@for item in $(DOCKER_HELP); do \
		key=$${item%%:*}; val=$${item#*:}; \
		printf "  docker-%-15s %s\n" "$$key" "$$val"; \
	done
	@grep -E '^docker-[a-zA-Z0-9_.-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS=":.*?## "}; {printf "  %-22s %s\n", $$1, $$2}'

docker-%:
	@INFRA_LOCATION="$(INFRA_LOCATION)" DEPLOY_ENV="$(DEPLOY_ENV)" FORMAT="$(FORMAT)" bash ./scripts/docker.sh "$*"