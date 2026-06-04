# Sortify Dispatch 4.5.1-custom-park-prefixes

## Scope

- Configurable custom park prefixes for local hold-only files.
- WebUI editor for custom park prefixes.
- Filename tester for built-in and custom hold rules.
- Bounded guard status using `SORTIFY_GUARD_MAX_FILES` and `SORTIFY_GUARD_STATUS_TIMEOUT`.
- Sortify-only config export includes custom prefixes and guard bounds.

## Out of scope

- No SSH Drop Dispatcher target creation or editing.
- No SSH Drop Dispatcher config import/export.
- No SSH key handling.
- No private runtime migration.
- No DNS/HA/VIP/route or host drop path changes.

## Operational notes

Custom park prefixes are local hold only. They do not release remote artifacts and do not replace the SDD marker contract for `target-*__*` or `targets-*__*` files.
