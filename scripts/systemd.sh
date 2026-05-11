#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/context.sh"

systemd_info() {
  echo -e "${CYAN}[Systemd] $1${RESET}"
}

systemd_success() {
  echo -e "${GREEN}[Systemd] $1${RESET}"
}

systemd_warning() {
  echo -e "${YELLOW}[Systemd] $1${RESET}"
}

systemd_error() {
  echo -e "${RED}[Systemd] $1${RESET}"
}

systemd_start() {
  systemd_info "Starting $SERVICE_NAME..."
  sudo systemctl start "$SERVICE_NAME"
  systemd_success "Start complete."
}

systemd_enable() {
  systemd_info "Enabling $SERVICE_NAME..."
  sudo systemctl enable "$SERVICE_NAME"
  systemd_success "Enable complete."
}

systemd_stop() {
  systemd_info "Stopping $SERVICE_NAME..."
  sudo systemctl stop "$SERVICE_NAME"
  systemd_success "Stop complete."
}

load_systemd_env() {
  local env_files=()

  if [ -n "${SYSTEMD_ENV_FILE:-}" ]; then
    env_files=("$SYSTEMD_ENV_FILE")
  else
    env_files=(.env.*.prod)
  fi

  if [ "${env_files[0]}" = ".env.*.prod" ]; then
    systemd_error "No prod env file found. Expected something like .env.home.prod"
    exit 1
  fi

  if [ "${#env_files[@]}" -gt 1 ]; then
    systemd_error "Multiple prod env files found:"
    printf '  %s\n' "${env_files[@]}"
    systemd_error "Set SYSTEMD_ENV_FILE to choose one."
    exit 1
  fi

  local env_file="${env_files[0]}"

  if [ ! -f "$env_file" ]; then
    systemd_error "Env file not found: $env_file"
    exit 1
  fi

  systemd_info "Loading env file: $env_file"

  set -a
  source "$env_file"
  set +a

  if [ -z "${INFRA_LOCATION:-}" ]; then
    systemd_error "INFRA_LOCATION is missing in $env_file"
    exit 1
  fi

  case "$INFRA_LOCATION" in
    home|cloud) ;;
    *)
      systemd_error "Invalid INFRA_LOCATION in $env_file: $INFRA_LOCATION"
      systemd_error "Expected: home or cloud"
      exit 1
      ;;
  esac

  if [ -z "${DOCKER_ENV:-}" ]; then
    systemd_error "DOCKER_ENV is missing in $env_file"
    exit 1
  fi

  case "$DOCKER_ENV" in
    production) ;;
    *)
      systemd_error "Invalid DOCKER_ENV in $env_file: $DOCKER_ENV"
      systemd_error "Expected: production"
      exit 1
      ;;
  esac

  SYSTEMD_ENV_FILE="$env_file"
}

create_systemd_service_file() {
  systemd_info "Creating systemd service file: $SERVICE_NAME..."
  mkdir -p ./systemd
  mkdir -p ./logs

  cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=${INFRA_FILE_NAME}
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/docker compose --env-file ${SYSTEMD_ENV_FILE} --project-name ${INFRA_FILE_NAME} --profile ${INFRA_LOCATION} -f docker-compose.yml up -d
ExecStop=/usr/bin/docker compose --env-file ${SYSTEMD_ENV_FILE} --project-name ${INFRA_FILE_NAME} --profile ${INFRA_LOCATION} -f docker-compose.yml down
TimeoutStartSec=0

StandardOutput=append:$(pwd)/logs/service.log
StandardError=append:$(pwd)/logs/service-error.log

[Install]
WantedBy=multi-user.target
EOF

systemd_success "Systemd service file created: $SERVICE_FILE"
}

if [ "$(uname -s)" != "Linux" ]; then
  systemd_error "systemd commands can only run on Linux."
  exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
  systemd_error "systemctl not found. This machine may not use systemd."
  exit 1
fi

load_systemd_env

command="${1:-}"

INFRA_FILE_NAME="${REPO_NAME}-${INFRA_LOCATION}"
SERVICE_NAME="${INFRA_FILE_NAME}.service"
SERVICE_FILE="./systemd/${SERVICE_NAME}"
SYSTEMD_PATH="/etc/systemd/system/${SERVICE_NAME}"

if [ -z "$command" ]; then
  echo "Select systemd command:"
  echo "1) start"
  echo "2) stop"
  echo "3) restart"
  echo "4) status"
  echo "5) enable"
  echo "6) disable"
  echo "7) logs"
  echo "8) logs-recent"
  echo "9) rebuild"
  echo "10) create-file"
  echo "11) install-file"
  echo "12) uninstall-file"
  echo "13) command-test"
  printf "> "
  read -r choice

  case "$choice" in
    1|start) command="start" ;;
    2|stop) command="stop" ;;
    3|restart) command="restart" ;;
    4|status) command="status" ;;
    5|enable) command="enable" ;;
    6|disable) command="disable" ;;
    7|logs) command="logs" ;;
    8|logs-recent) command="logs-recent" ;;
    9|rebuild) command="rebuild" ;;
    10|create-file) command="create-file" ;;
    11|install-file) command="install-file" ;;
    12|uninstall-file) command="uninstall-file" ;;
    13|command-test) command="command-test" ;;
    *)
      systemd_error "Invalid systemd command"
      exit 1
      ;;
  esac
fi

case "$command" in
  start)
    systemd_start
    ;;

  stop)
    systemd_stop
    ;;

  restart)
    systemd_info "Restarting $SERVICE_NAME..."
    sudo systemctl restart "$SERVICE_NAME"
    systemd_success "Restart complete."
    ;;

  status)
    systemd_info "Showing status for $SERVICE_NAME..."
    systemctl status "$SERVICE_NAME"
    ;;

  enable)
    systemd_enable
    ;;

  disable)
    systemd_info "Disabling $SERVICE_NAME..."
    sudo systemctl disable "$SERVICE_NAME"
    systemd_success "Disable complete."
    ;;

  logs)
    systemd_info "Showing full logs for $SERVICE_NAME..."
    journalctl -u "$SERVICE_NAME" -f
    ;;

  logs-recent)
    systemd_info "Showing recent logs for $SERVICE_NAME..."
    journalctl -u "$SERVICE_NAME" -n 100 --no-pager
    ;;

  rebuild)
    systemd_info "Rebuilding Docker containers and restarting service..."
    systemd_stop

    systemd_info "Pulling latest code..."
    git checkout prod
    git pull origin prod

    systemd_info "Rebuilding Docker containers without cache..."
    docker compose \
      --env-file "$SYSTEMD_ENV_FILE" \
      --project-name "$INFRA_FILE_NAME" \
      --profile "$INFRA_LOCATION" \
      -f docker-compose.yml \
      build --no-cache

    systemd_start

    systemd_success "Rebuild complete."
    ;;

  install-file)
    systemd_info "Installing service file: $SERVICE_NAME..."
    create_systemd_service_file

    systemd_info "Installing service file into $SYSTEMD_PATH..."
    sudo cp "$SERVICE_FILE" "$SYSTEMD_PATH"

    sudo systemctl daemon-reload

    systemd_enable
    systemd_start

    systemd_success "Install file complete."
    ;;

  uninstall-file)
    # NEED TO REVIEW
    systemd_warning "This will stop, disable, and remove $SERVICE_NAME."
    printf "Continue? (yes/no): "
    read -r confirm

    case "$confirm" in
      y|Y|yes|YES)
        sudo systemctl stop "$SERVICE_NAME" || true
        sudo systemctl disable "$SERVICE_NAME" || true
        sudo rm -f "$SYSTEMD_PATH"
        sudo systemctl daemon-reload
        systemd_success "Uninstall complete."
        ;;
      *)
        systemd_info "Uninstall cancelled."
        ;;
    esac
    ;;

  create-file)
    create_systemd_service_file
    ;;

  *)
    systemd_error "Invalid systemd command: $command"
    exit 1
    ;;
esac