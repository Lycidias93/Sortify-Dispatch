# Sortify Dispatch 4.8.8 - Magisk Action WebUI hotfix

Candidate hotfix for the module-manager Action button.

- Keeps the loopback WebUI server alive after the Magisk Action shell exits.
- Prevents the external browser from landing on `ERR_CONNECTION_REFUSED` because the server stopped before the first request.
- Updates the shared WebUI Core to 0.6.6.
- Preserves existing Sortify settings and sorting behavior.

Stable update metadata remains on 4.8.7 until exact-device Action-button acceptance passes.
