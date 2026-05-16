# Artifact Guard

Sortify Dispatch protects operational artifacts from extension-based sorting.

Protected files stay in `/sdcard/Download` so Dispatcher, Pixel, Termux, repo, and release workflows can find them reliably.

## Protected classes

- Dispatcher target markers: `target-...__*`, `targets-...__*`
- Legacy host prefixes: `pi3_*`, `pi4_*`, `zeropi2_*`, `berylax_*`
- Pixel local scripts: `pixel_local__*`
- Termux helper artifacts: `termux-*`, `termux_*`, `pixel-termux*`, `pixel_termux*`
- Dispatcher releases: `pixel-drop-dispatch*`, `ssh-drop-dispatcher*`, `*drop-dispatch*`, `*drop_dispatch*`
- Sortify Dispatch releases: `sortify-dispatch*`, `sortify_dispatch*`
- Repo helper scripts: `repo_*.py`, `*_repo_*.py`, `repo_*.sh`, `*_repo_*.sh`

## v4.1 guard tools

- `action.sh --guard-status` reports protected files in Download, misplaced protected files below `/sdcard/Sortify`, and conflict count.
- `action.sh --guard-clean` safely restores misplaced protected files to `/sdcard/Download`.
- If a same-named file already exists in Download, the misplaced file is moved to `/sdcard/Sortify/GuardConflicts/<timestamp>/` instead of overwriting.
- `action.sh --dispatcher-status` checks whether Pixel Drop Dispatcher runtime metadata is present at `/data/adb/pixel-drop-dispatch`.
- The KernelSU WebUI exposes interval settings, guard status, safe guard clean, dispatcher link status, and manual sort.

## Module ID and path safety

The visible module name is `Sortify Dispatch`, but the module ID remains `sortify`. The active module path stays `/data/adb/modules/sortify` for safe in-place updates.

## Rationale

Sortify sorts by file extension. Operational artifacts often share normal extensions such as `.zip`, `.sh`, `.py`, `.apk`, `.tar.gz`, or `.txt`. Without explicit protection, these files can be moved into `/sdcard/Sortify`, breaking repeatable Dispatcher and Pixel/Termux workflows.
