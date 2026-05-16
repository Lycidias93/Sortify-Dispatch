#!/usr/bin/env bash
set -euo pipefail

VERSION="4.1-guard-tools"
TAG="v4.1-guard-tools"
ZIP_NAME="Sortify-Dispatch-v4.1-guard-tools.zip"
RELEASE_DIR="releases/$TAG"
mkdir -p "$RELEASE_DIR"
rm -f "$RELEASE_DIR/$ZIP_NAME" "$RELEASE_DIR/$ZIP_NAME.sha256"

required=(module.prop action.sh service.sh customize.sh uninstall.sh sortify.conf webroot/index.html ARTIFACT_GUARD.md README.md CHANGELOG.md update.json)
for f in "${required[@]}"; do
  test -s "$f" || { echo "missing=$f"; exit 1; }
done

sh -n action.sh
sh -n service.sh
sh -n customize.sh
sh -n uninstall.sh
bash tools/smoke-artifact-guard.sh >/dev/null

zip -qr "$RELEASE_DIR/$ZIP_NAME" \
  module.prop \
  action.sh \
  service.sh \
  customize.sh \
  uninstall.sh \
  sortify.conf \
  webroot \
  banner.png \
  ARTIFACT_GUARD.md \
  README.md \
  CHANGELOG.md \
  update.json

( cd "$RELEASE_DIR" && sha256sum "$ZIP_NAME" > "$ZIP_NAME.sha256" )
printf 'release_zip=%s\n' "$PWD/$RELEASE_DIR/$ZIP_NAME"
printf 'release_sha=%s\n' "$(awk '{print $1}' "$RELEASE_DIR/$ZIP_NAME.sha256")"
