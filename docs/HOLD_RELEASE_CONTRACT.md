# Artifact Hold / Release Contract

Sortify Dispatch must not decide on its own when operational artifacts are no longer needed.

Normal downloads are sorted automatically. Only operational workflow artifacts are held.

## Authority

| Artifact class | Release authority | Default |
|---|---|---|
| `target-*__*`, `targets-*__*` | Pixel Drop Dispatcher | hold in `/sdcard/Download` |
| legacy host prefixes `pi3_*`, `pi4_*`, `zeropi2_*`, `berylax_*` | Pixel Drop Dispatcher when used as target artifacts | hold in `/sdcard/Download` |
| `pixel_local__*` | Termux / local operator workflow | hold in `/sdcard/Download` |
| `termux-*`, `termux_*`, `pixel-termux*`, `pixel_termux*` | Termux / local operator workflow | hold in `/sdcard/Download` |
| repo helpers `repo_*.py`, `*_repo_*.py`, `repo_*.sh`, `*_repo_*.sh` | Termux / local operator workflow | hold in `/sdcard/Download` |
| normal downloads | Sortify Dispatch | sort automatically |

## Dispatcher release rule

Dispatcher may release a target artifact only after successful delivery to every resolved target.

Partial failure keeps the file held:

```text
pi3=done
pi4=failed
berylax=done
released=no
keep_in_download=yes
```

## Termux release rule

Termux / local operator workflows release `pixel_local__*`, `termux-*`, `termux_*`, and repo helper artifacts only when they are no longer needed for rerun, rollback, evidence, or follow-up work.

No automatic release after a successful `cgrun`.

## Release marker identity

Release markers must be bound to the actual file, not only the filename.

Minimum identity:

```text
basename + size + sha256
```

Preferred identity:

```text
sha256 as primary key
```

## Sortify behavior

| State | Behavior |
|---|---|
| normal download | sort automatically |
| protected artifact without valid release marker | keep in `/sdcard/Download` |
| protected artifact with valid Dispatcher release | eligible to sort |
| protected artifact with valid Termux release | eligible to sort |
| release marker mismatch | keep in `/sdcard/Download` and log warning |

## Non-goals

- Sortify Dispatch must not start, stop, or control Pixel Drop Dispatcher.
- Pixel Drop Dispatcher must not depend on Sortify Dispatch to function.
- Sortify Dispatch must not delete protected artifacts during clean/release handling.
- Sortify Dispatch must not overwrite same-named files in `/sdcard/Download`.
