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
    -f docker-compose.yml \
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
  echo "11) update"
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
    10|update) command="update" ;;
    *)
      docker_error "Invalid Docker command"
      exit 1
      ;;
  esac
fi

load_context

full_project_name="${REPO_NAME}-${INFRA_LOCATION}-${DOCKER_ENV}"
env_file=".env.${INFRA_LOCATION}.${DOCKER_ENV}"

echo -e "${GREEN}Infrastructure Location:${RESET} $INFRA_LOCATION"
echo -e "${GREEN}Docker Environment:${RESET} $DOCKER_ENV"
echo -e "${GREEN}Platform:${RESET} $full_project_name"
echo -e "${GREEN}Env File Name:${RESET} $env_file"
echo

case "$command" in
  up)
    docker_info "Starting containers..."
    docker_compose up -d
    docker_success "Start containers complete."
    ;;

  down)
    docker_info "Stopping containers..."
    docker_compose down
    docker_success "Stop containers complete."
    ;;

  restart)
    docker_info "Restarting containers..."
    docker_info "Stopping containers..."
    docker_compose down
    docker_success "Stop containers complete."
    docker_info "Starting containers..."
    docker_compose up -d
    docker_success "Start containers complete."
    ;;

  logs)
    docker_compose logs -f
    ;;

  ps)
    docker_compose ps
    ;;

  build)
    docker_info "Building containers..."
    docker_compose build
    docker_success "Build containers complete."
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

  update)
    docker_info "Updating platform from prod branch..."

    docker_info "Stopping containers..."
    docker_compose down
    docker_success "Stop containers complete."

    docker_info "Pulling latest code from prod branch..."
    git checkout prod
    git pull origin prod

    docker_info "Rebuilding images without cache..."
    docker_compose build --no-cache
    docker_success "Build complete."

    docker_info "Starting containers..."
    docker_compose up -d
    docker_success "Start containers complete."

    docker_success "Update complete."
    ;;

  *)
    docker_error "Invalid Docker command: $command"
    exit 1
    ;;
esac