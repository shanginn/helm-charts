#!/bin/bash

set -ex

# TODO: temporal-sql-tool create-database temporal
temporal-sql-tool --database temporal setup-schema -v 0.0
temporal-sql-tool --database temporal update --schema-dir "${SCHEMA_DIR_PREFIX}/temporal/versioned"

# TODO: temporal-sql-tool create-database temporal_visibility
temporal-sql-tool --database temporal_visibility setup-schema -v 0.0
temporal-sql-tool --database temporal_visibility update --schema-dir "${SCHEMA_DIR_PREFIX}/visibility/versioned"