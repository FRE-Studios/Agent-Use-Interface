#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

XSD_FILE="$ROOT_DIR/schema/0.1/aui.xsd"
SCHEMATRON_FILE="$ROOT_DIR/schema/0.1/aui.sch"
CATALOG_FILE="$ROOT_DIR/example/aui.xml"

echo "Validating XSD structure..."
xmllint --noout --schema "$XSD_FILE" "$CATALOG_FILE"
for detail_file in "$ROOT_DIR"/example/tasks/*.xml; do
  [ -f "$detail_file" ] || continue
  xmllint --noout --schema "$XSD_FILE" "$detail_file"
done

echo "Validating Schematron semantic rules..."
ruby "$ROOT_DIR/scripts/run-schematron.rb" "$SCHEMATRON_FILE" "$CATALOG_FILE"
for detail_file in "$ROOT_DIR"/example/tasks/*.xml; do
  [ -f "$detail_file" ] || continue
  ruby "$ROOT_DIR/scripts/run-schematron.rb" "$SCHEMATRON_FILE" "$detail_file"
done

echo "Validating catalog/detail id linkage..."
ruby "$ROOT_DIR/scripts/validate-reference-links.rb" "$CATALOG_FILE"

echo "All validations passed."
