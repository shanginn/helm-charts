#!/bin/bash

# Ensure that Docker is running...
if ! docker info > /dev/null 2>&1; then
    echo "${BOLD}Docker is not running.${NC}" >&2

    exit 1
fi

while getopts ":hs:p:u:P:d:" opt; do
  case $opt in
    h)
      echo "Usage: update-schema.sh -s <SQL_HOST> -p <SQL_PORT> -u <SQL_USER> -P <SQL_PASSWORD> -d <SQL_PLUGIN>"
      exit 0
      ;;
    s)
      SQL_HOST=$OPTARG
      ;;
    p)
      SQL_PORT=$OPTARG
      ;;
    u)
      SQL_USER=$OPTARG
      ;;
    P)
      SQL_PASSWORD=$OPTARG
      ;;
    d)
      SQL_PLUGIN=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done

declare -a arr=("SQL_HOST" "SQL_PORT" "SQL_USER" "SQL_PLUGIN")
for i in "${arr[@]}"; do
  if [ -z "${!i}" ]; then
    read -p "Please input ${i}: " ${i}
  fi
done

if [ -z "${SQL_PASSWORD}" ]; then
  read -s -p "Please input SQL_PASSWORD (the input is hidden): " SQL_PASSWORD
  echo
fi

echo "SQL_PLUGIN: ${SQL_PLUGIN}"
echo "SQL_HOST: ${SQL_HOST}"
echo "SQL_PORT: ${SQL_PORT}"
echo "SQL_USER: ${SQL_USER}"
echo "SQL_PASSWORD: ******"

if [ -z "${SQL_HOST}" ] || [ -z "${SQL_PORT}" ] || [ -z "${SQL_USER}" ] || [ -z "${SQL_PASSWORD}" ] || [ -z "${SQL_PLUGIN}" ]; then
  echo "Please set all parameters."
  exit 1
fi

set -ex

if ! docker pull "temporalio/admin-tools:latest" > /dev/null 2>&1; then
  echo "admin-tools version 'latest' is not present in docker repo. "
  echo "Please check https://hub.docker.com/r/temporalio/admin-tools/tags for the correct version."
  exit 1
fi

if [ "${SQL_PLUGIN}" == "mysql" ]; then
  SCHEMA_DIR_PREFIX="./schema/mysql/v57"
elif [ "${SQL_PLUGIN}" == "postgres" ]; then
  SCHEMA_DIR_PREFIX="./schema/postgresql/v96"
else
  echo "Please set correct SQL_PLUGIN."
  exit 1
fi

echo "Running admin-tools..."

docker run --rm \
  -v "$PWD/bin/_init-schema-script.sh":/bin/_init-schema-script.sh \
  --entrypoint=/bin/_init-schema-script.sh \
  -e SQL_PLUGIN="$SQL_PLUGIN" \
  -e SQL_HOST="$SQL_HOST" \
  -e SQL_PORT="$SQL_PORT" \
  -e SQL_USER="$SQL_USER" \
  -e SQL_PASSWORD="$SQL_PASSWORD" \
  -e SCHEMA_DIR_PREFIX="$SCHEMA_DIR_PREFIX" \
  "temporalio/admin-tools:latest"