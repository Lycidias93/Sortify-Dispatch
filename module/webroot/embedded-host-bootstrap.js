(() => {
  "use strict";

  const bridge = window.ksu;
  const embeddedHost = location.hostname === "mui.kernelsu.org"
    && bridge
    && typeof bridge.exec === "function"
    && typeof bridge.moduleInfo === "function";
  if (!embeddedHost) return;

  window.__ROOT_MODULE_WEBUI_EMBEDDED_BOOTSTRAP__ = true;

  const nativeFetch = window.fetch.bind(window);
  window.fetch = (input, init) => {
    const target = typeof input === "string" ? input : String(input?.url || "");
    if (target.startsWith("/api/v1/")) return new Promise(() => {});
    return nativeFetch(input, init);
  };

  const name = document.querySelector("#moduleName");
  const version = document.querySelector("#moduleVersion");
  const badge = document.querySelector("#connectionBadge");
  const notice = document.querySelector("#notice");

  const showState = (message, level = "muted") => {
    if (version) version.textContent = message;
    if (badge) {
      badge.textContent = level === "danger" ? "disconnected" : "starting";
      badge.className = `badge ${level}`;
    }
  };

  const fail = message => {
    showState("Embedded host could not start the standalone loopback session.", "danger");
    if (notice) {
      notice.textContent = message;
      notice.className = "notice danger";
    }
  };

  let info;
  try {
    info = JSON.parse(bridge.moduleInfo());
  } catch {
    fail("KsuWebUI module metadata is unavailable.");
    return;
  }

  const moduleDir = String(info?.moduleDir || "");
  const moduleId = String(info?.id || "");
  if (!/^\/data\/adb\/modules\/[A-Za-z0-9._-]+$/.test(moduleDir)
      || !/^[A-Za-z0-9._-]+$/.test(moduleId)
      || !moduleDir.endsWith(`/${moduleId}`)) {
    fail("KsuWebUI returned an invalid module path.");
    return;
  }

  if (name && moduleId) name.textContent = moduleId;
  showState("Starting secure standalone WebUI inside KsuWebUI…");

  const dedicatedLauncher = `${moduleDir}/tools/webui/launch.sh`;
  const actionLauncher = `${moduleDir}/action.sh`;
  const command = `if [ -r '${dedicatedLauncher}' ]; then /system/bin/sh '${dedicatedLauncher}' --print-url; else /system/bin/sh '${actionLauncher}' --print-url; fi`;
  const callbackName = "__rootModuleWebuiEmbeddedBootstrapDone";

  window[callbackName] = (code, stdout, stderr) => {
    try {
      if (code !== 0) {
        fail(String(stderr || stdout || `Launcher exited with code ${code}.`).trim());
        return;
      }
      const match = String(stdout || "").match(/^WEBUI_BOOTSTRAP_URL=(http:\/\/127\.0\.0\.1:([0-9]+)\/bootstrap\?token=([0-9a-f]{64,}))$/m);
      if (!match) {
        fail("Launcher did not return a valid loopback bootstrap URL.");
        return;
      }
      const port = Number(match[2]);
      if (!Number.isInteger(port) || port < 1024 || port > 65535) {
        fail("Launcher returned an invalid loopback port.");
        return;
      }
      showState("Connecting to the local standalone session…");
      location.replace(match[1]);
    } finally {
      try { delete window[callbackName]; } catch { window[callbackName] = undefined; }
    }
  };

  try {
    bridge.exec(command, `window.${callbackName}`);
  } catch (error) {
    try { delete window[callbackName]; } catch { window[callbackName] = undefined; }
    fail(error instanceof Error ? error.message : String(error));
  }
})();
