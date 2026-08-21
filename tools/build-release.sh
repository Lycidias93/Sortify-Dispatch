#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CORE="$ROOT/.webui-core"
CORE_COMMIT=6fbd1b018a45fe5b1bebba7aeb9142423eab47fb
CORE_VERSION=0.6.1
MODULE_SRC="$ROOT/module"
DIST="$ROOT/dist"

if [[ ! -f "$CORE/CORE_VERSION" ]]; then
  git -C "$ROOT" submodule update --init --checkout .webui-core
fi
[[ "$(git -C "$CORE" rev-parse HEAD)" == "$CORE_COMMIT" ]] || { echo "webui_core_commit_mismatch"; exit 1; }
[[ "$(tr -d '\r\n' < "$CORE/CORE_VERSION")" == "$CORE_VERSION" ]] || { echo "webui_core_version_mismatch"; exit 1; }

bash "$ROOT/tools/test-vnext.sh" --source-only

VERSION=$(sed -n 's/^version=//p' "$MODULE_SRC/module.prop" | head -n1)
[[ -n "$VERSION" ]] || { echo "module_version_missing"; exit 1; }
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
STAGE="$WORK/module"
mkdir -p "$STAGE"
cp -a "$MODULE_SRC/." "$STAGE/"
cp -a "$CORE/module/META-INF" "$STAGE/"
cp -f "$CORE/module/action.sh" "$STAGE/action.sh"
rm -rf "$STAGE/webroot"
cp -a "$CORE/module/webroot" "$STAGE/webroot"
mkdir -p "$STAGE/bin" "$STAGE/tools"
cp -f "$ROOT/tools/sortify-download-cleanup.sh" "$STAGE/tools/sortify-download-cleanup.sh"

(
  cd "$CORE"
  CGO_ENABLED=0 GOOS=android GOARCH=arm64 go build -buildvcs=false -trimpath \
    -ldflags "-s -w -X main.version=$CORE_VERSION" \
    -o "$STAGE/bin/webui-server-arm64" ./server/cmd/webui-server
)

chmod 0755 "$STAGE/action.sh" "$STAGE/service.sh" "$STAGE/customize.sh" "$STAGE/uninstall.sh" \
  "$STAGE/bin/module-control" "$STAGE/bin/sortify-domain" "$STAGE/bin/webui-server-arm64" \
  "$STAGE/tools/sortify-download-cleanup.sh"
chmod 0644 "$STAGE/module.prop" "$STAGE/config/sortify.conf.default" "$STAGE"/webroot/*

cmp "$STAGE/action.sh" "$CORE/module/action.sh"
diff -qr "$STAGE/webroot" "$CORE/module/webroot" >/dev/null

mkdir -p "$DIST"
rm -f "$DIST/Sortify-Dispatch-$VERSION.zip" "$DIST/build-manifest.json"
python3 "$ROOT/tools/package-vnext.py" \
  --stage "$STAGE" \
  --output "$DIST/Sortify-Dispatch-$VERSION.zip" \
  --manifest "$DIST/build-manifest.json" \
  --core-version "$CORE_VERSION" \
  --core-commit "$CORE_COMMIT"

echo "RESULT: SORTIFY_VNEXT_BUILD_DONE outcome=success workflow_exit_code=0"
