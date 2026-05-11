#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/context.sh"

command="${1:-}"

if [ -z "$command" ]; then
  echo "Select Docker command:"
  echo "1) up"
  echo "2) down"
  echo "3) restart"
  echo "4) logs"
  echo "5) ps"
  echo "6) build"
  printf "> "
  read -r choice

  case "$choice" in
    1|up) command="up" ;;
    2|down) command="down" ;;
    3|restart) command="restart" ;;
    4|logs) command="logs" ;;
    5|ps) command="ps" ;;
    6|build) command="build" ;;
    *) echo -e "${RED}Invalid Docker command${RESET}"; exit 1 ;;
  esac
fi

load_context

full_project_name="${REPO_NAME}-${INFRA_LOCATION}-${DOCKER_ENV}"
env_file=".env.${INFRA_LOCATION}.${DOCKER_ENV}"

docker_compose() {
  docker compose \
    --env-file "$env_file" \
    --project-name "$full_project_name" \
    --profile "$INFRA_LOCATION" \
    -f "$COMPOSE_BASE_FILE" \
    "$@"
}

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

  *)
    echo -e "${RED}Invalid Docker command: $command${RESET}"
    exit 1
    ;;
esac