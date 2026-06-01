<!-- SORTIFY_DISPATCH_V44_SDD_START -->
## Sortify Dispatch v4.4 - SSH Drop Dispatcher alignment

Planned release: `v4.4-ssh-drop-dispatcher` / `versionCode=15`.

- Default dispatcher runtime is `/data/adb/ssh-drop-dispatcher`.
- Remote protected artifacts still require the v4115 dispatcher release marker contract.
- Pixel-local Termux artifacts stay local protected hold only.
- `rc=0` never globally releases Pixel-local artifacts; explicit local-release marker is deferred to a later feature.
- Visible status uses generic dispatcher keys while legacy pidd keys remain compatibility aliases.

<!-- SORTIFY_DISPATCH_V44_SDD_END -->

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
- `action.sh --dispatcher-status` checks whether Pixel Drop Dispatcher runtime metadata is present at `/data/adb/ssh-drop-dispatcher`.
- The KernelSU WebUI exposes interval settings, guard status, safe guard clean, dispatcher link status, and manual sort.

## Module ID and path safety

The visible module name is `Sortify Dispatch`, but the module ID remains `sortify`. The active module path stays `/data/adb/modules/sortify` for safe in-place updates.

## Rationale

Sortify sorts by file extension. Operational artifacts often share normal extensions such as `.zip`, `.sh`, `.py`, `.apk`, `.tar.gz`, or `.txt`. Without explicit protection, these files can be moved into `/sdcard/Sortify`, breaking repeatable Dispatcher and Pixel/Termux workflows.

<!-- HOLD_RELEASE_CONTRACT_20260517_START -->
## Hold / release contract

Sortify Dispatch uses an explicit hold/release model for operational artifacts.

- Normal downloads are sorted automatically.
- Dispatcher target artifacts stay in `/sdcard/Download` until Pixel Drop Dispatcher releases them after successful delivery to every resolved target.
- `pixel_local__*`, Termux helper artifacts, and repo helper artifacts stay in `/sdcard/Download` until Termux / the local operator workflow releases them.
- Release markers must match file identity by at least basename, size, and SHA256.
- Same-named conflicts must not be overwritten; conflict copies stay under `GuardConflicts`.
- Public Dispatcher release work must wait until the private/proven Dispatcher release implements and verifies this contract.

Details: `docs/HOLD_RELEASE_CONTRACT.md`.
<!-- HOLD_RELEASE_CONTRACT_20260517_END -->

<!-- SORTIFY_HOLD_RELEASE_OPTIONAL_CONTRACT_20260517_START -->
## Optional hold/release contract

The dispatcher hold/release contract is optional.

Required behavior:
- users without dispatcher can disable dispatcher integration
- protected operational artifacts may be held only when integration is enabled
- unrelated downloads must not be held because no dispatcher is present
- if integration is `auto`, missing dispatcher runtime degrades to disabled behavior
- if integration is `on`, missing dispatcher runtime is a clear configuration error
<!-- SORTIFY_HOLD_RELEASE_OPTIONAL_CONTRACT_20260517_END -->
