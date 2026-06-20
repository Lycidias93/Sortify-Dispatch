# Sortify Dispatch 4.6.5-sort-mode-control

## Scope

- Adds `SORTIFY_SORT_MODE=interval|manual|boot_once`.
- Keeps `action.sh --sort` as explicit manual Sort Now.
- Adds `action.sh --service-cycle`, used by `service.sh` for automatic mode semantics.
- Adds `action.sh --mode-status` and bounded `action.sh --preview-sort`.
- Adds WebUI sort mode selector plus Mode Status and Preview Sort actions.
- Keeps SSH Drop Dispatcher marker root read-only and policy `v4115` unchanged.

## Mode semantics

- `interval`: service sorts every configured interval.
- `manual`: service does not sort automatically; WebUI/CLI Sort Now still works.
- `boot_once`: service sorts once per Android boot, then skips until reboot.

## Safety

- No SDD marker writes.
- No SDD target management.
- No SSH key handling.
- No ntfy secret handling.
- No host-run, DNS/HA/VIP/default-route/static-route/MagicDNS/subnet-route changes.
