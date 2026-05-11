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
      *) echo -e "${RED}Invalid infrastructure location${RESET}"; exit 1 ;;
    esac
  fi

  case "$infra" in
    home|cloud) ;;
    *) echo -e "${RED}Invalid INFRA_LOCATION: $infra${RESET}"; exit 1 ;;
  esac

  INFRA_LOCATION="$infra"
  echo
}

select_deploy_env() {
  local deploy_env="${DEPLOY_ENV:-$DEFAULT_DEPLOY_ENV}"

  if [ -z "$deploy_env" ]; then
    echo "Select deploy environment:"
    echo "1) dev"
    echo "2) test"
    echo "3) prod"
    printf "> "
    read -r choice

    case "$choice" in
      1|dev) deploy_env="dev" ;;
      2|test) deploy_env="test" ;;
      3|prod) deploy_env="prod" ;;
      *) echo -e "${RED}Invalid deploy environment${RESET}"; exit 1 ;;
    esac
  fi

  case "$deploy_env" in
    dev|test|prod) ;;
    *) echo -e "${RED}Invalid DEPLOY_ENV: $deploy_env${RESET}"; exit 1 ;;
  esac

  DEPLOY_ENV="$deploy_env"
  echo
}

load_context() {
  select_infra_location
  select_deploy_env
}