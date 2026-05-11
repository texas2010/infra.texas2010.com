#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/variables.sh"

select_infra_location() {
  local infra="${INFRA_LOCATION:-$DEFAULT_INFRA_LOCATION}"

  if [ -z "$infra" ]; then
    echo "Select infrastructure:"
    echo "1) home"
    echo "2) cloud"
    printf "> "
    read -r choice

    case "$choice" in
      1|home) infra="home" ;;
      2|cloud) infra="cloud" ;;
      *) echo -e "${RED}Invalid infrastructure${RESET}"; exit 1 ;;
    esac
  fi

  case "$infra" in
    home|cloud) ;;
    *) echo -e "${RED}Invalid INFRA_LOCATION: $infra${RESET}"; exit 1 ;;
  esac

  INFRA_LOCATION="$infra"
}

select_docker_env() {
  local docker_env="${DOCKER_ENV:-$DEFAULT_DOCKER_ENV}"

  if [ -z "$docker_env" ]; then
    echo "Select Docker environment:"
    echo "1) dev"
    echo "2) test"
    echo "3) prod"
    printf "> "
    read -r choice

    case "$choice" in
      1|dev) docker_env="dev" ;;
      2|test) docker_env="test" ;;
      3|prod) docker_env="prod" ;;
      *) echo -e "${RED}Invalid Docker environment${RESET}"; exit 1 ;;
    esac
  fi

  case "$docker_env" in
    dev|test|prod) ;;
    *) echo -e "${RED}Invalid DOCKER_ENV: $docker_env${RESET}"; exit 1 ;;
  esac

  DOCKER_ENV="$docker_env"
}

load_context() {
  select_infra_location
  select_docker_env
}