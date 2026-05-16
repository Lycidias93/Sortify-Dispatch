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

## Rationale

Sortify sorts by file extension. Operational artifacts often share normal extensions such as `.zip`, `.sh`, `.py`, `.apk`, `.tar.gz`, or `.txt`. Without explicit protection, these files can be moved into `/sdcard/Sortify`, breaking repeatable Dispatcher and Pixel/Termux workflows.
