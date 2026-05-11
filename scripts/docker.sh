#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/context.sh"

docker_info() {
  echo -e "${CYAN}[Docker] $1${RESET}"
}

docker_success() {
  echo -e "${GREEN}[Docker] $1${RESET}"
}

docker_warning() {
  echo -e "${YELLOW}[Docker] $1${RESET}"
}

docker_error() {
  echo -e "${RED}[Docker] $1${RESET}"
}

docker_compose() {
  docker compose \
    --env-file "$env_file" \
    --project-name "$full_project_name" \
    --profile "$INFRA_LOCATION" \
    -f "$COMPOSE_BASE_FILE" \
    "$@"
}

command="${1:-}"

if [ -z "$command" ]; then
  echo "Select Docker command:"
  echo "1) up"
  echo "2) down"
  echo "3) restart"
  echo "4) logs"
  echo "5) ps"
  echo "6) build"
  echo "7) clean"
  echo "8) rebuild"
  echo "9) config"
  echo "10) deploy"
  printf "> "
  read -r choice

  case "$choice" in
    1|up) command="up" ;;
    2|down) command="down" ;;
    3|restart) command="restart" ;;
    4|logs) command="logs" ;;
    5|ps) command="ps" ;;
    6|build) command="build" ;;
    7|clean) command="clean" ;;
    8|rebuild) command="rebuild" ;;
    9|config) command="config" ;;
    10|deploy) command="deploy" ;;
    *)
      docker_error "Invalid Docker command"
      exit 1
      ;;
  esac
fi

load_context

full_project_name="${REPO_NAME}-${INFRA_LOCATION}-${DOCKER_ENV}"
env_file=".env.${INFRA_LOCATION}.${DOCKER_ENV}"

echo -e "${GREEN}Infrastructure:${RESET} $INFRA_LOCATION"
echo -e "${GREEN}Docker environment:${RESET} $DOCKER_ENV"
echo -e "${GREEN}Project:${RESET} $full_project_name"
echo -e "${GREEN}Compose file:${RESET} $COMPOSE_BASE_FILE"
echo -e "${GREEN}Env file:${RESET} $env_file"
echo

case "$command" in
  up)
    docker_compose up -d
    ;;

  down)
    docker_compose down
    ;;

  restart)
    docker_compose down
    docker_compose up -d
    ;;

  logs)
    docker_compose logs -f
    ;;

  ps)
    docker_compose ps
    ;;

  build)
    docker_compose build
    ;;

  clean)
    docker_warning "WARNING: This will remove containers, volumes, and orphans."
    printf "Continue? (yes/no): "
    read -r confirm

    case "$confirm" in
      y|Y|yes|YES)
        docker_warning "Removing containers, volumes, and orphans..."
        docker_compose down -v --remove-orphans
        docker_info "Running Docker system prune..."
        docker system prune -f
        docker_success "Clean complete."
        ;;
      *)
        docker_info "Clean cancelled."
        ;;
    esac
    ;;

  rebuild)
    docker_info "Rebuilding images without cache..."
    docker_compose build --no-cache
    docker_compose up -d
    docker_success "Rebuild complete."
    ;;

  config)
    docker_info "Showing resolved Docker Compose configuration..."
    docker_compose config
    ;;

  deploy)
    docker_info "Deploying containers..."
    docker_compose build
    docker_success "Build complete."
    docker_info "Start containers..."
    docker_compose up -d
    docker_success "Start containers complete."
    docker_success "Deploy complete."
    ;;


  *)
    docker_error "Invalid Docker command: $command"
    exit 1
    ;;
esac