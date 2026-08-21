#!/usr/bin/env python3
import argparse
import hashlib
import json
import pathlib
import stat
import zipfile

FIXED_DT = (1980, 1, 1, 0, 0, 0)


def sha256(path: pathlib.Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def prop(path: pathlib.Path, key: str) -> str:
    prefix = key + "="
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith(prefix):
            return line[len(prefix):]
    raise SystemExit(f"missing {key} in {path}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--core-version", required=True)
    ap.add_argument("--core-commit", required=True)
    args = ap.parse_args()

    stage = pathlib.Path(args.stage).resolve()
    output = pathlib.Path(args.output).resolve()
    manifest = pathlib.Path(args.manifest).resolve()
    if not stage.is_dir():
        raise SystemExit("stage is not a directory")
    files = sorted(p for p in stage.rglob("*") if p.is_file())
    for path in stage.rglob("*"):
        if path.is_symlink():
            raise SystemExit(f"symlink not allowed in module package: {path}")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.unlink(missing_ok=True)

    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for path in files:
            rel = path.relative_to(stage).as_posix()
            info = zipfile.ZipInfo(rel, FIXED_DT)
            info.compress_type = zipfile.ZIP_DEFLATED
            mode = stat.S_IMODE(path.stat().st_mode)
            info.external_attr = (stat.S_IFREG | mode) << 16
            zf.writestr(info, path.read_bytes())

    module_prop = stage / "module.prop"
    payload = {
        "schema": "sortify-dispatch-build-manifest-v1",
        "module_id": prop(module_prop, "id"),
        "version": prop(module_prop, "version"),
        "version_code": int(prop(module_prop, "versionCode")),
        "webui_core_version": args.core_version,
        "webui_core_commit": args.core_commit,
        "zip": output.name,
        "sha256": sha256(output),
        "bytes": output.stat().st_size,
        "files": len(files),
        "sha_sidecar": False,
    }
    manifest.parent.mkdir(parents=True, exist_ok=True)
    manifest.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"build_zip={output}")
    print(f"build_sha256={payload['sha256']}")
    print(f"build_bytes={payload['bytes']}")
    print("sha_sidecar=no")


if __name__ == "__main__":
    main()
