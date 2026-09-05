#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CORE="$ROOT/.webui-core"
CORE_COMMIT=efd19b1e892a8ce9bd97490ef3ea9c2f2eeed7f7
CORE_VERSION=0.6.1
MODULE_SRC="$ROOT/module"
DIST="$ROOT/dist"

if [[ ! -f "$CORE/CORE_VERSION" ]]; then
  git -C "$ROOT" submodule update --init --checkout .webui-core
fi
[[ "$(git -C "$CORE" rev-parse HEAD)" == "$CORE_COMMIT" ]] || { echo "webui_core_commit_mismatch"; exit 1; }
[[ "$(tr -d '\r\n' < "$CORE/CORE_VERSION")" == "$CORE_VERSION" ]] || { echo "webui_core_version_mismatch"; exit 1; }

bash "$ROOT/tools/test-vnext.sh" --source-only
python3 "$CORE/scripts/webui-release-audit.py"
# The reusable static release audit must be paired with the pinned Core's real
# loopback HTTP integration test. This exercises bootstrap/session handling,
# every shipped page-referenced asset, enabled API routes, config POST/readback,
# actions/jobs/inventory, authentication and Origin rejection on every build.
bash "$CORE/scripts/integration-test.sh"

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
mkdir -p "$STAGE/bin" "$STAGE/tools" "$STAGE/third_party/licenses"
cp -f "$ROOT/tools/sortify-download-cleanup.sh" "$STAGE/tools/sortify-download-cleanup.sh"

# Preserve licensing/provenance for the shared WebUI code and its documented
# upstream design sources inside the distributable candidate.
cp -f "$ROOT/LICENSE" "$STAGE/LICENSE"
cp -f "$CORE/LICENSE" "$STAGE/third_party/licenses/android-root-module-webui-template.LICENSE"
cp -f "$CORE/NOTICE" "$STAGE/WEBUI_CORE_NOTICE"
cp -f "$CORE/CREDITS.md" "$STAGE/WEBUI_CORE_CREDITS.md"
cp -f "$CORE/UPSTREAMS.md" "$STAGE/WEBUI_CORE_UPSTREAMS.md"
cp -f "$CORE"/third_party/licenses/*.LICENSE "$STAGE/third_party/licenses/"

(
  cd "$CORE"
  CGO_ENABLED=0 GOOS=android GOARCH=arm64 go build -buildvcs=false -trimpath \
    -ldflags "-s -w -X main.version=$CORE_VERSION" \
    -o "$STAGE/bin/webui-server-arm64" ./server/cmd/webui-server
)

chmod 0755 "$STAGE/action.sh" "$STAGE/service.sh" "$STAGE/customize.sh" "$STAGE/uninstall.sh" \
  "$STAGE/bin/module-control" "$STAGE/bin/sortify-domain" "$STAGE/bin/webui-server-arm64" \
  "$STAGE/tools/sortify-download-cleanup.sh"
chmod 0644 "$STAGE/module.prop" "$STAGE/config/sortify.conf.default" "$STAGE"/webroot/* \
  "$STAGE/LICENSE" "$STAGE/WEBUI_CORE_NOTICE" "$STAGE/WEBUI_CORE_CREDITS.md" \
  "$STAGE/WEBUI_CORE_UPSTREAMS.md" "$STAGE"/third_party/licenses/*.LICENSE

cmp "$STAGE/action.sh" "$CORE/module/action.sh"
diff -qr "$STAGE/webroot" "$CORE/module/webroot" >/dev/null
[[ -s "$STAGE/LICENSE" ]]
[[ -s "$STAGE/WEBUI_CORE_NOTICE" ]]
[[ -s "$STAGE/third_party/licenses/android-root-module-webui-template.LICENSE" ]]
[[ -s "$STAGE/third_party/licenses/F2FS-Optimizer.LICENSE" ]]

mkdir -p "$DIST"
rm -f "$DIST/Sortify-Dispatch-$VERSION.zip" "$DIST/build-manifest.json"
python3 "$ROOT/tools/package-vnext.py" \
  --stage "$STAGE" \
  --output "$DIST/Sortify-Dispatch-$VERSION.zip" \
  --manifest "$DIST/build-manifest.json" \
  --core-version "$CORE_VERSION" \
  --core-commit "$CORE_COMMIT"

echo "webui_core_provenance=PASS"
echo "webui_release_audit=PASS"
echo "webui_core_http_integration=PASS"
echo "RESULT: SORTIFY_VNEXT_BUILD_DONE outcome=success workflow_exit_code=0"
