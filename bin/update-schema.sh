#!/bin/bash

# Ensure that Docker is running...
if ! docker info > /dev/null 2>&1; then
    echo "${BOLD}Docker is not running.${NC}" >&2

    exit 1
fi

SQL_PLUGIN=postgres12

while getopts ":hs:p:u:P:v:" opt; do
  case $opt in
    h)
      echo "Usage: update-schema.sh -s <SQL_HOST> -p <SQL_PORT> -u <SQL_USER> -P <SQL_PASSWORD> -v <NEXT_MINOR_VERSION>"
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
    v)
      NEXT_MINOR_VERSION=$OPTARG
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

declare -a arr=("SQL_HOST" "SQL_PORT" "SQL_USER")
for i in "${arr[@]}"; do
  if [ -z "${!i}" ]; then
    read -p "Please input ${i}: " ${i}
  fi
done

if [ -z "${SQL_PASSWORD}" ]; then
  read -s -p "Please input SQL_PASSWORD (the input is hidden): " SQL_PASSWORD
  echo
fi

echo "SQL_HOST: ${SQL_HOST}"
echo "SQL_PORT: ${SQL_PORT}"
echo "SQL_USER: ${SQL_USER}"
echo "SQL_PASSWORD: ******"

# if NEXT_MINOR_VERSION is not set
if [ -z "${NEXT_MINOR_VERSION}" ]; then
  echo "Please input next minor release version."
  echo -n "For example, if current version is 1.12.0, then next minor release version is 1.13.0, "
  echo "but it is better to find latest patch, eg. 1.13.4"
  echo -n "It will be used to pull an docker image from https://hub.docker.com/r/temporalio/admin-tools/tags "
  echo "so you can look up the appropriate tag version."
  echo "You can check current version in the values.yaml file under server.image.tag"
  read -p "Next minor version is: " NEXT_MINOR_VERSION
fi

echo "NEXT_MINOR_VERSION: $NEXT_MINOR_VERSION"

if [ -z "${SQL_HOST}" ] || [ -z "${SQL_PORT}" ] || [ -z "${SQL_USER}" ] || [ -z "${SQL_PASSWORD}" ] || [ -z "${NEXT_MINOR_VERSION}" ]; then
  echo "Please set all parameters."
  exit 1
fi

if ! docker pull "temporalio/admin-tools:$NEXT_MINOR_VERSION" > /dev/null 2>&1; then
  echo "admin-tools version $NEXT_MINOR_VERSION is not present in docker repo."
  echo "Please check https://hub.docker.com/r/temporalio/admin-tools/tags for the correct version."
  exit 1
fi

docker run --rm --entrypoint /bin/bash "temporalio/admin-tools:$NEXT_MINOR_VERSION" -c "\
  temporal-sql-tool \
    --endpoint $SQL_HOST --port $SQL_PORT \
    --user $SQL_USER --password $SQL_PASSWORD \
    --plugin $SQL_PLUGIN --database temporal \
    update --schema-dir ./schema/postgresql/v12/temporal/versioned \
"

docker run --rm --entrypoint /bin/bash "temporalio/admin-tools:$NEXT_MINOR_VERSION" -c "\
  temporal-sql-tool \
    --endpoint $SQL_HOST --port $SQL_PORT \
    --user $SQL_USER --password $SQL_PASSWORD \
    --plugin $SQL_PLUGIN --database temporal_visibility \
    update --schema-dir ./schema/postgresql/v12/visibility/versioned \
"
